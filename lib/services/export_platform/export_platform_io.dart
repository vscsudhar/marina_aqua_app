import 'dart:io';

class ExportPlatform {
  static void downloadFile(List<int> bytes, String fileName, String mimeType) {
    saveFile(bytes, fileName);
  }

  static void openInBrowser(String url) {
    // Open URL using process
    if (Platform.isWindows) {
      Process.run('start', [url], runInShell: true);
    } else if (Platform.isMacOS) {
      Process.run('open', [url]);
    } else if (Platform.isLinux) {
      Process.run('xdg-open', [url]);
    }
  }

  static Future<String?> saveFile(List<int> bytes, String fileName) async {
    try {
      // Find downloads or user home directory
      String targetDir;
      if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\';
        targetDir = '$userProfile\\Downloads';
      } else {
        final home = Platform.environment['HOME'] ?? '.';
        targetDir = '$home/Downloads';
      }

      final dir = Directory(targetDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final file = File('${dir.path}${Platform.pathSeparator}$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (_) {
      final currentFile = File(fileName);
      await currentFile.writeAsBytes(bytes);
      return currentFile.path;
    }
  }

  static void printPdf(List<int> bytes, {String title = 'Document'}) {
    // Printing.layoutPdf handles native printing on desktop/mobile
  }
}
