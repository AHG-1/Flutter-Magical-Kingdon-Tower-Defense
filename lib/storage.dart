import 'storage_stub.dart' if (dart.library.io) 'storage_io.dart' as impl;

Future<String?> loadMetaSave() => impl.loadMetaSave();
Future<void> writeMetaSave(String json) => impl.writeMetaSave(json);
