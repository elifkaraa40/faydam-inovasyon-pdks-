class DownloadedFile {
  const DownloadedFile({
    required this.fileName,
    required this.displayLocation,
    required this.mimeType,
    this.path,
    this.uri,
  });

  final String fileName;
  final String displayLocation;
  final String mimeType;
  final String? path;
  final String? uri;
}

enum OpenDownloadedFileResult {
  opened,
  noApplication,
  unsupported,
  failed,
}
