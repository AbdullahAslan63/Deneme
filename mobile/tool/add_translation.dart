// dart run tool/add_translation.dart <key> "<tr>"          ← EN otomatik çevrilir
// dart run tool/add_translation.dart <key> "<tr>" "<en>"   ← EN manuel
//
// API key kurulumu: mobile/tool/.deepl_key dosyasına DeepL API key'ini yaz
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.length < 2 || args.length > 3) {
    stderr.writeln('Kullanım: dart run tool/add_translation.dart <key> "<tr>" [<en>]');
    stderr.writeln('Örnek:    dart run tool/add_translation.dart features.issues.title "Arıza Bildir"');
    stderr.writeln('          dart run tool/add_translation.dart features.issues.title "Arıza Bildir" "Report Issue"');
    exit(1);
  }

  final key = args[0];
  final trValue = args[1];

  final parts = key.split('.');
  if (parts.length < 2 || parts.any((p) => p.isEmpty)) {
    stderr.writeln('Hata: key en az iki parça içermeli (örn: common.submit veya features.issues.title)');
    exit(1);
  }

  final script = File(Platform.script.toFilePath());
  final l10nDir = Directory('${script.parent.parent.path}/lib/l10n');
  final trFile = File('${l10nDir.path}/strings_tr.i18n.json');
  final enFile = File('${l10nDir.path}/strings_en.i18n.json');

  if (!trFile.existsSync() || !enFile.existsSync()) {
    stderr.writeln('Hata: l10n dosyaları bulunamadı (${l10nDir.path})');
    exit(1);
  }

  final trJson = jsonDecode(trFile.readAsStringSync()) as Map<String, dynamic>;
  final enJson = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;

  if (_keyExists(trJson, parts)) {
    stderr.writeln('Uyarı: "$key" zaten mevcut. Üzerine yazılmadı.');
    stderr.writeln('  TR: ${_getValue(trJson, parts)}');
    stderr.writeln('  EN: ${_getValue(enJson, parts)}');
    exit(1);
  }

  String enValue;
  if (args.length == 3) {
    enValue = args[2];
  } else {
    stdout.writeln('DeepL ile çevriliyor...');
    enValue = await _translateWithDeepl(trValue, script.parent.path);
    stdout.writeln('  EN (DeepL): $enValue');
  }

  _setNestedValue(trJson, parts, trValue);
  _setNestedValue(enJson, parts, enValue);

  const encoder = JsonEncoder.withIndent('  ');
  trFile.writeAsStringSync('${encoder.convert(trJson)}\n');
  enFile.writeAsStringSync('${encoder.convert(enJson)}\n');

  stdout.writeln('Eklendi: $key');
  stdout.writeln('  TR: $trValue');
  stdout.writeln('  EN: $enValue');
}

Future<String> _translateWithDeepl(String text, String toolDir) async {
  final keyFile = File('$toolDir/.deepl_key');
  if (!keyFile.existsSync()) {
    stderr.writeln('Hata: DeepL API key bulunamadı.');
    stderr.writeln('  → mobile/tool/.deepl_key dosyasına API key\'ini yaz.');
    stderr.writeln('  → Ücretsiz key: https://www.deepl.com/pro-api');
    exit(1);
  }

  final apiKey = keyFile.readAsStringSync().trim();
  if (apiKey.isEmpty) {
    stderr.writeln('Hata: .deepl_key dosyası boş.');
    exit(1);
  }

  final body = jsonEncode({
    'text': [text],
    'source_lang': 'TR',
    'target_lang': 'EN',
  });

  final client = HttpClient();
  try {
    final request = await client.postUrl(
      Uri.parse('https://api-free.deepl.com/v2/translate'),
    );
    request.headers
      ..set('Authorization', 'DeepL-Auth-Key $apiKey')
      ..set('Content-Type', 'application/json');
    request.write(body);

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode != 200) {
      stderr.writeln('DeepL API hatası (${response.statusCode}): $responseBody');
      exit(1);
    }

    final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    final translations = decoded['translations'] as List<dynamic>;
    return (translations.first as Map<String, dynamic>)['text'] as String;
  } on SocketException {
    stderr.writeln('Hata: İnternet bağlantısı yok veya DeepL erişilemiyor.');
    exit(1);
  } finally {
    client.close();
  }
}

bool _keyExists(Map<String, dynamic> map, List<String> parts) {
  dynamic current = map;
  for (final part in parts) {
    if (current is! Map<String, dynamic> || !current.containsKey(part)) return false;
    current = current[part];
  }
  return true;
}

dynamic _getValue(Map<String, dynamic> map, List<String> parts) {
  dynamic current = map;
  for (final part in parts) {
    if (current is! Map<String, dynamic>) return null;
    current = current[part];
  }
  return current;
}

void _setNestedValue(Map<String, dynamic> map, List<String> parts, String value) {
  Map<String, dynamic> current = map;
  for (int i = 0; i < parts.length - 1; i++) {
    current.putIfAbsent(parts[i], () => <String, dynamic>{});
    current = current[parts[i]] as Map<String, dynamic>;
  }
  current[parts.last] = value;
}
