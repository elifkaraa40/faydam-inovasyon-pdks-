import 'dart:typed_data';

import 'downloaded_file.dart';

Future<DownloadedFile> downloadFile(
  Uint8List bytes,
  String fileName,
  String mimeType, {
  String subdirectory = 'Puantaj',
}) async {
  throw UnsupportedError('Bu cihazda dosya indirme desteklenmiyor.');
}

Future<OpenDownloadedFileResult> openDownloadedFile(
  DownloadedFile file,
) async =>
    OpenDownloadedFileResult.unsupported;
