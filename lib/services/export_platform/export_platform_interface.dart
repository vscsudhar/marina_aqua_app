abstract class ExportPlatform {
  static void downloadFile(List<int> bytes, String fileName, String mimeType) {
    throw UnsupportedError(
        'Cannot download file without platform implementation');
  }

  static void openInBrowser(String url) {
    throw UnsupportedError(
        'Cannot open browser without platform implementation');
  }

  static Future<String?> saveFile(List<int> bytes, String fileName) async {
    throw UnsupportedError('Cannot save file without platform implementation');
  }
}
