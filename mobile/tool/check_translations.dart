// dart run tool/check_translations.dart
// Çevrilmemiş sabit UI string'lerini tarar. Dinamik veri (model.name, "$var") atlar.
import 'dart:io';

void main() {
  final script = File(Platform.script.toFilePath());
  final libDir = Directory('${script.parent.parent.path}/lib');
  final mobileRoot = script.parent.parent.path;

  if (!libDir.existsSync()) {
    stderr.writeln('Hata: lib/ klasörü bulunamadı (${libDir.path})');
    exit(1);
  }

  final findings = <_Finding>[];
  _scanDirectory(libDir, mobileRoot, findings);

  if (findings.isEmpty) {
    stdout.writeln('Hardcoded string bulunamadı.');
    return;
  }

  stdout.writeln('Çevrilmemiş string\'ler bulundu:\n');
  for (final f in findings) {
    stdout.writeln('${f.file}:${f.lineNumber}');
    stdout.writeln('  → ${f.snippet}');
    stdout.writeln();
  }
  stdout.writeln('Toplam: ${findings.length} şüpheli string');
  exit(1);
}

void _scanDirectory(Directory dir, String root, List<_Finding> results) {
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File) continue;
    final p = entity.path.replaceAll('\\', '/');
    if (!p.endsWith('.dart')) continue;
    if (p.endsWith('.g.dart') || p.endsWith('.freezed.dart')) continue;
    if (p.endsWith('/main.dart')) continue; // entry point, no UI strings
    _scanFile(entity, root, results);
  }
}

void _scanFile(File file, String root, List<_Finding> results) {
  List<String> lines;
  try {
    lines = file.readAsLinesSync();
  } catch (_) {
    return;
  }

  final relativePath = _rel(file.path, root);
  bool inBlockComment = false;

  for (int i = 0; i < lines.length; i++) {
    final raw = lines[i];
    final trimmed = raw.trim();

    // Block comment yönetimi
    if (!inBlockComment && trimmed.startsWith('/*')) inBlockComment = true;
    if (inBlockComment) {
      if (trimmed.contains('*/')) inBlockComment = false;
      continue;
    }

    // Kesin atla
    if (trimmed.startsWith('//')) continue;
    if (trimmed.startsWith('import ') || trimmed.startsWith('export ')) continue;
    if (trimmed.startsWith('part ') || trimmed.startsWith('package:')) continue;
    if (raw.contains('debugPrint(') || raw.contains('print(') || raw.contains(' log(')) continue;
    if (raw.contains("r'") || raw.contains('r"')) continue; // raw string (regex)
    if (raw.contains('context.t.') || raw.contains('.tr()')) continue; // zaten çevrilmiş
    if (raw.contains('RegExp(') || raw.contains('Pattern(')) continue;

    final suspects = _extractCandidates(raw);
    for (final s in suspects) {
      if (_isUIString(s)) {
        results.add(_Finding(
          file: relativePath,
          lineNumber: i + 1,
          snippet: trimmed.length > 100 ? '${trimmed.substring(0, 100)}…' : trimmed,
        ));
        break;
      }
    }
  }
}

// Satırdan literal string adaylarını çıkar (sadece alıntılanmış literal'ler)
List<String> _extractCandidates(String line) {
  final results = <String>[];

  // Text('...') veya Text("...")
  for (final m in RegExp(r'''Text\(\s*['"]([^'"$\\]+)['"]\s*[,)]''').allMatches(line)) {
    results.add(m.group(1)!);
  }

  // Widget'ın bilinen string parametreleri
  const namedParams =
      r'(hintText|labelText|helperText|counterText|errorText|tooltip|semanticsLabel|placeholder)';
  for (final m in RegExp(namedParams + r'''\s*:\s*['"]([^'"$\\]+)['"]''').allMatches(line)) {
    results.add(m.group(2)!);
  }

  // title: '...' veya subtitle: '...' — sadece string literal olanlar
  for (final m in RegExp(r'''(title|subtitle)\s*:\s*['"]([^'"$\\]+)['"]''').allMatches(line)) {
    results.add(m.group(2)!);
  }

  // showToast('...') veya Toast.show('...')
  for (final m in RegExp(r'''show[Tt]oast\(\s*['"]([^'"$\\]+)['"]''').allMatches(line)) {
    results.add(m.group(1)!);
  }

  return results;
}

bool _isUIString(String s) {
  if (s.trim().isEmpty) return false;
  if (s.length <= 2) return false;
  if (s.contains(r'$')) return false; // interpolasyon
  if (s.startsWith('/')) return false; // route veya yorum
  // Asset ve dosya yolları
  if (RegExp(r'\.(png|svg|json|dart|ttf|otf|jpg|jpeg|gif|webp)$').hasMatch(s)) return false;
  if (s.startsWith('assets/') || s.startsWith('fonts/')) return false;
  // Sadece büyük harf + alt çizgi = sabit
  if (RegExp(r'^[A-Z_0-9]+$').hasMatch(s)) return false;
  // camelCase identifier (boşluk yok, sadece harf+rakam)
  if (RegExp(r'^[a-z][a-zA-Z0-9]*$').hasMatch(s)) return false;
  // Harf içermiyor
  if (!RegExp(r'[a-zA-ZğüşıöçĞÜŞİÖÇ]').hasMatch(s)) return false;
  // Email formatı
  if (RegExp(r'^[\w.+-]+@[\w-]+\.[a-z]{2,}$').hasMatch(s)) return false;
  // Sadece rakam
  if (RegExp(r'^\d+$').hasMatch(s)) return false;
  // Regex karakterleri içeriyor
  if (s.contains('[') && s.contains(']') && (s.contains('^') || s.contains('+'))) return false;
  // Format placeholder (AP3-B12-X7K9)
  if (RegExp(r'^[A-Z0-9]{2,4}-[A-Z0-9]{2,4}-[A-Z0-9]{2,4}$').hasMatch(s)) return false;

  return true;
}

String _rel(String absolute, String root) {
  final norm = absolute.replaceAll('\\', '/');
  final normRoot = root.replaceAll('\\', '/');
  if (norm.startsWith(normRoot)) return norm.substring(normRoot.length + 1);
  return norm;
}

class _Finding {
  final String file;
  final int lineNumber;
  final String snippet;
  const _Finding({required this.file, required this.lineNumber, required this.snippet});
}
