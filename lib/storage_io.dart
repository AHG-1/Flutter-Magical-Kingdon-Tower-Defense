import 'dart:io';

File _saveFile() {
  final home = Platform.environment['LOCALAPPDATA'] ??
      Platform.environment['HOME'] ??
      Directory.systemTemp.path;
  final dir = Directory('$home${Platform.pathSeparator}reino_magico');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  return File('${dir.path}${Platform.pathSeparator}meta_save.json');
}

Future<String?> loadMetaSave() async {
  try {
    final f = _saveFile();
    if (await f.exists()) return await f.readAsString();
  } catch (_) {}
  return null;
}

Future<void> writeMetaSave(String json) async {
  try {
    final f = _saveFile();
    await f.writeAsString(json);
  } catch (_) {}
}
