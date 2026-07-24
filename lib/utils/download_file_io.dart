import 'dart:io';

import 'package:flutter/services.dart';

import 'downloaded_file.dart';

const _fileChannel = MethodChannel('com.faydam.pdkspro/files');

Future<DownloadedFile> downloadFile(
  Uint8List bytes,
  String fileName,
  String mimeType, {
  String subdirectory = 'Puantaj',
}) async {
  if (Platform.isAndroid) {
    final value = await _fileChannel.invokeMapMethod<String, dynamic>(
      'saveFile',
      {
        'bytes': bytes,
        'fileName': fileName,
        'mimeType': mimeType,
        'subdirectory': subdirectory,
      },
    );
    if (value == null) {
      throw const FileSystemException('Dosya kaydedilemedi.');
    }
    return DownloadedFile(
      fileName: value['fileName']?.toString() ?? fileName,
      displayLocation:
          value['displayLocation']?.toString() ?? 'Downloads/$subdirectory',
      mimeType: mimeType,
      path: value['path']?.toString(),
      uri: value['uri']?.toString(),
    );
  }

  final profile = Platform.environment['USERPROFILE'];
  final downloads = Platform.isWindows && profile != null
      ? Directory('$profile${Platform.pathSeparator}Downloads')
      : Directory.systemTemp;
  final directory =
      Directory('${downloads.path}${Platform.pathSeparator}$subdirectory');
  if (!await directory.exists()) await directory.create(recursive: true);
  final file = File('${directory.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return DownloadedFile(
    fileName: fileName,
    displayLocation: directory.path,
    mimeType: mimeType,
    path: file.path,
    uri: file.uri.toString(),
  );
}

Future<OpenDownloadedFileResult> openDownloadedFile(
  DownloadedFile file,
) async {
  try {
    if (Platform.isAndroid) {
      final opened = await _fileChannel.invokeMethod<bool>(
        'openFile',
        {
          'uri': file.uri,
          'path': file.path,
          'mimeType': file.mimeType,
        },
      );
      return opened == true
          ? OpenDownloadedFileResult.opened
          : OpenDownloadedFileResult.noApplication;
    }

    final path = file.path;
    if (path == null || path.isEmpty) {
      return OpenDownloadedFileResult.unsupported;
    }
    if (Platform.isWindows) {
      await Process.start(
        'rundll32.exe',
        ['url.dll,FileProtocolHandler', path],
        mode: ProcessStartMode.detached,
      );
      return OpenDownloadedFileResult.opened;
    }
    if (Platform.isMacOS) {
      await Process.start('open', [path], mode: ProcessStartMode.detached);
      return OpenDownloadedFileResult.opened;
    }
    if (Platform.isLinux) {
      await Process.start('xdg-open', [path], mode: ProcessStartMode.detached);
      return OpenDownloadedFileResult.opened;
    }
    return OpenDownloadedFileResult.unsupported;
  } on PlatformException catch (error) {
    return error.code == 'NO_APPLICATION'
        ? OpenDownloadedFileResult.noApplication
        : OpenDownloadedFileResult.failed;
  } catch (_) {
    return OpenDownloadedFileResult.failed;
  }
}
