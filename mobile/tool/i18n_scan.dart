// dart run tool/i18n_scan.dart
// lib/**/*.dart dosyalarını tarar: hardcoded string bulunca DeepL çevirir,
// JSON'a ekler, kaynak kodu günceller ve dart run slang çalıştırır.
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final script = File(Platform.script.toFilePath());
  final mobileRoot = script.parent.parent.path.replaceAll('\\', '/');
  final libDir = Directory('$mobileRoot/lib');
  final keyFile = File('${script.parent.path.replaceAll("\\", "/")}/.deepl_key');

  if (!libDir.existsSync()) {
    stderr.writeln('Hata: lib/ klasörü bulunamadı');
    exit(1);
  }
  if (!keyFile.existsSync() || keyFile.readAsStringSync().trim().isEmpty) {
    stderr.writeln('Hata: .deepl_key bulunamadı → mobile/tool/.deepl_key oluştur');
    exit(1);
  }

  final apiKey = keyFile.readAsStringSync().trim();

  final l10nDir = '$mobileRoot/lib/l10n';
  final trFile = File('$l10nDir/strings_tr.i18n.json');
  final enFile = File('$l10nDir/strings_en.i18n.json');

  if (!trFile.existsSync() || !enFile.existsSync()) {
    stderr.writeln('Hata: l10n dosyaları bulunamadı ($l10nDir)');
    exit(1);
  }

  final trJson = jsonDecode(trFile.readAsStringSync()) as Map<String, dynamic>;
  final enJson = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;

  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) {
        final p = f.path.replaceAll('\\', '/');
        return p.endsWith('.dart') &&
            !p.endsWith('.g.dart') &&
            !p.endsWith('.freezed.dart') &&
            !p.endsWith('/main.dart');
      })
      .toList();

  stdout.writeln('Taranıyor... (${dartFiles.length} dosya)\n');

  int totalAdded = 0;
  int totalFiles = 0;
  bool jsonChanged = false;

  for (final file in dartFiles) {
    final filePath = file.path.replaceAll('\\', '/');
    final content = file.readAsStringSync();
    final replacements = _findReplacements(content, filePath, mobileRoot);
    if (replacements.isEmpty) continue;

    final activeRepls = <_CodeRepl>[];

    for (final r in replacements) {
      var key = r.key;
      final parts = key.split('.');

      if (_keyExists(trJson, parts)) {
        if (_getNested(trJson, parts) == r.trText) {
          activeRepls.add(r.code);
        } else {
          // Aynı key, farklı metin → unique suffix ekle
          key = _uniqueKey(key, trJson);
        }
        if (_getNested(trJson, parts) == r.trText) continue;
      }

      String enText;
      try {
        enText = await _translate(r.trText, apiKey);
      } catch (e) {
        stderr.writeln('DeepL hatası "${r.trText}": $e');
        continue;
      }

      final finalParts = key.split('.');
      _setNested(trJson, finalParts, r.trText);
      _setNested(enJson, finalParts, enText);
      jsonChanged = true;
      totalAdded++;

      activeRepls.add(_CodeRepl(
        start: r.code.start,
        end: r.code.end,
        text: r.code.text.replaceAll('context.t.${r.key}', 'context.t.$key'),
      ));

      stdout.writeln('+ $key');
      stdout.writeln('  TR: ${r.trText}');
      stdout.writeln('  EN: $enText');
    }

    if (activeRepls.isEmpty) continue;

    activeRepls.sort((a, b) => b.start.compareTo(a.start));
    var updated = content;
    for (final rep in activeRepls) {
      updated = updated.substring(0, rep.start) + rep.text + updated.substring(rep.end);
    }
    file.writeAsStringSync(updated);
    totalFiles++;

    final relPath = filePath.substring(mobileRoot.length + 1);
    stdout.writeln('  → $relPath\n');
  }

  if (jsonChanged) {
    const enc = JsonEncoder.withIndent('  ');
    trFile.writeAsStringSync('${enc.convert(trJson)}\n');
    enFile.writeAsStringSync('${enc.convert(enJson)}\n');
    await _runSlang(mobileRoot);
  }

  if (totalAdded == 0) {
    stdout.writeln('Hardcoded string bulunamadı. Her şey zaten çevrilmiş.');
  } else {
    stdout.writeln('\nTamamlandı: $totalAdded string eklendi, $totalFiles dosya güncellendi.');
  }
}

// ---------------------------------------------------------------------------

class _Replacement {
  final String key;
  final String trText;
  final _CodeRepl code;
  const _Replacement({required this.key, required this.trText, required this.code});
}

class _CodeRepl {
  final int start;
  final int end;
  final String text;
  const _CodeRepl({required this.start, required this.end, required this.text});
}

List<_Replacement> _findReplacements(
    String content, String filePath, String mobileRoot) {
  final namespace = _namespaceFromPath(filePath, mobileRoot);
  final results = <_Replacement>[];

  final skipLines = <int>{};
  final lineStarts = <int>[0];
  for (int i = 0; i < content.length; i++) {
    if (content[i] == '\n') lineStarts.add(i + 1);
  }

  bool inBlock = false;
  for (int li = 0; li < lineStarts.length; li++) {
    final lStart = lineStarts[li];
    final lEnd = li + 1 < lineStarts.length ? lineStarts[li + 1] - 1 : content.length;
    final line = content.substring(lStart, lEnd);
    final trimmed = line.trim();

    if (!inBlock && trimmed.startsWith('/*')) inBlock = true;
    if (inBlock) {
      skipLines.add(li);
      if (trimmed.contains('*/')) inBlock = false;
      continue;
    }
    if (trimmed.startsWith('//') ||
        trimmed.startsWith('import ') ||
        trimmed.startsWith('export ') ||
        line.contains('context.t.') ||
        line.contains('.tr()') ||
        line.contains('debugPrint(') ||
        line.contains('print(') ||
        line.contains("r'") ||
        line.contains('r"') ||
        line.contains('RegExp(')) {
      skipLines.add(li);
    }
  }

  int lineOf(int pos) {
    int lo = 0, hi = lineStarts.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (lineStarts[mid] <= pos) { lo = mid; } else { hi = mid - 1; }
    }
    return lo;
  }

  void add(RegExpMatch m, String trText, String codeReplacement) {
    if (skipLines.contains(lineOf(m.start))) return;
    if (!_isUIString(trText)) return;
    final key = '$namespace.${_toCamelCase(trText)}';
    results.add(_Replacement(
      key: key,
      trText: trText,
      code: _CodeRepl(start: m.start, end: m.end, text: codeReplacement),
    ));
  }

  // Pattern 1: (const )?Text('...')  or  (const )?Text("...")
  for (final m in RegExp(r'''(const\s+)?Text\(\s*(['"])([^'"$\\\n]+)\2\s*([,)])''')
      .allMatches(content)) {
    final str = m.group(3)!;
    final trailing = m.group(4)!;
    final key = '$namespace.${_toCamelCase(str)}';
    add(m, str, 'Text(context.t.$key$trailing');
  }

  // Pattern 2: named widget params
  const namedParams =
      '(hintText|labelText|helperText|counterText|errorText|tooltip|semanticsLabel)';
  for (final m in RegExp(namedParams + r'''\s*:\s*(['"])([^'"$\\\n]+)\2''')
      .allMatches(content)) {
    final paramName = m.group(1)!;
    final str = m.group(3)!;
    final key = '$namespace.${_toCamelCase(str)}';
    add(m, str, '$paramName: context.t.$key');
  }

  // Pattern 3: title: '...' (raw string, not widget)
  for (final m
      in RegExp(r'''title\s*:\s*(['"])([^'"$\\\n]+)\1''').allMatches(content)) {
    final str = m.group(2)!;
    final key = '$namespace.${_toCamelCase(str)}';
    add(m, str, 'title: context.t.$key');
  }

  results.sort((a, b) => a.code.start.compareTo(b.code.start));
  final deduped = <_Replacement>[];
  int lastEnd = -1;
  for (final r in results) {
    if (r.code.start >= lastEnd) {
      deduped.add(r);
      lastEnd = r.code.end;
    }
  }
  return deduped;
}

// ---------------------------------------------------------------------------

String _namespaceFromPath(String filePath, String mobileRoot) {
  final rel = filePath.replaceAll('\\', '/').substring(mobileRoot.length + 1);
  final featMatch = RegExp(r'/features/([^/]+)/').firstMatch(rel);
  if (featMatch != null) return 'features.${featMatch.group(1)!}';
  return 'common';
}

String _toCamelCase(String text) {
  const trMap = {
    'ğ': 'g', 'Ğ': 'g', 'ü': 'u', 'Ü': 'u', 'ş': 's', 'Ş': 's',
    'ı': 'i', 'İ': 'i', 'ö': 'o', 'Ö': 'o', 'ç': 'c', 'Ç': 'c',
  };
  var s = text;
  trMap.forEach((k, v) => s = s.replaceAll(k, v));
  final words = s.split(RegExp(r'[^a-zA-Z0-9]+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return 'unknown';
  final buf = StringBuffer(words[0].toLowerCase());
  for (int i = 1; i < words.length; i++) {
    final w = words[i];
    buf.write(w[0].toUpperCase() + w.substring(1).toLowerCase());
  }
  var result = buf.toString();
  if (result.length > 30) result = result.substring(0, 30);
  return result;
}

bool _isUIString(String s) {
  if (s.trim().isEmpty || s.length <= 2) return false;
  if (s.contains(r'$')) return false;
  if (s.startsWith('/')) return false;
  if (RegExp(r'\.(png|svg|json|dart|ttf|otf|jpg|jpeg|gif|webp)$').hasMatch(s)) return false;
  if (s.startsWith('assets/') || s.startsWith('fonts/')) return false;
  if (RegExp(r'^[A-Z_0-9]+$').hasMatch(s)) return false;
  if (RegExp(r'^[a-z][a-zA-Z0-9]*$').hasMatch(s)) return false;
  if (!RegExp(r'[a-zA-ZğüşıöçĞÜŞİÖÇ]').hasMatch(s)) return false;
  if (RegExp(r'^[\w.+-]+@[\w-]+\.[a-z]{2,}$').hasMatch(s)) return false;
  if (RegExp(r'^\d+$').hasMatch(s)) return false;
  if (s.contains('[') && s.contains(']') && (s.contains('^') || s.contains('+'))) return false;
  if (RegExp(r'^[A-Z0-9]{2,4}-[A-Z0-9]{2,4}').hasMatch(s)) return false;
  return true;
}

String _uniqueKey(String baseKey, Map<String, dynamic> json) {
  final parts = baseKey.split('.');
  int n = 2;
  while (true) {
    final candidate = [...parts.sublist(0, parts.length - 1), '${parts.last}$n'];
    if (!_keyExists(json, candidate)) return candidate.join('.');
    n++;
  }
}

bool _keyExists(Map<String, dynamic> map, List<String> parts) {
  dynamic cur = map;
  for (final p in parts) {
    if (cur is! Map<String, dynamic> || !cur.containsKey(p)) return false;
    cur = cur[p];
  }
  return true;
}

dynamic _getNested(Map<String, dynamic> map, List<String> parts) {
  dynamic cur = map;
  for (final p in parts) {
    if (cur is! Map<String, dynamic>) return null;
    cur = cur[p];
  }
  return cur;
}

void _setNested(Map<String, dynamic> map, List<String> parts, String value) {
  Map<String, dynamic> cur = map;
  for (int i = 0; i < parts.length - 1; i++) {
    cur.putIfAbsent(parts[i], () => <String, dynamic>{});
    cur = cur[parts[i]] as Map<String, dynamic>;
  }
  cur[parts.last] = value;
}

Future<String> _translate(String text, String apiKey) async {
  final client = HttpClient();
  try {
    final req = await client.postUrl(
      Uri.parse('https://api-free.deepl.com/v2/translate'),
    );
    req.headers
      ..set('Authorization', 'DeepL-Auth-Key $apiKey')
      ..set('Content-Type', 'application/json');
    req.write(jsonEncode({'text': [text], 'source_lang': 'TR', 'target_lang': 'EN'}));
    final resp = await req.close();
    final body = await resp.transform(utf8.decoder).join();
    if (resp.statusCode != 200) throw 'HTTP ${resp.statusCode}: $body';
    final data = jsonDecode(body) as Map<String, dynamic>;
    return (data['translations'] as List).first['text'] as String;
  } finally {
    client.close();
  }
}

Future<void> _runSlang(String mobileRoot) async {
  final result = await Process.run('dart', ['run', 'slang'],
      workingDirectory: mobileRoot);
  if (result.exitCode == 0) {
    stdout.writeln('  strings.g.dart güncellendi');
  } else {
    stderr.writeln('  Slang hatası: ${result.stderr}');
  }
}
