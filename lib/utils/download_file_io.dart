import 'dart:io';
import 'dart:typed_data';

Future<String> downloadFile(
  Uint8List bytes,
  String fileName,
  String mimeType,
) async {
  final profile = Platform.environment['USERPROFILE'];
  final directory = Platform.isWindows && profile != null
      ? Directory('$profile${Platform.pathSeparator}Downloads')
      : Directory.systemTemp;
  if (!await directory.exists()) await directory.create(recursive: true);
  final file = File('${directory.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
