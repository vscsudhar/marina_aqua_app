// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ExportPlatform {
  static void downloadFile(List<int> bytes, String fileName, String mimeType) {
    try {
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..style.display = 'none';

      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();

      // Defer revocation slightly to ensure the browser has scheduled the download
      Future.delayed(const Duration(seconds: 2), () {
        html.Url.revokeObjectUrl(url);
      });
    } catch (e) {
      // Fallback: data URI
      final anchor = html.AnchorElement(
        href:
            'data:$mimeType;base64,${html.window.btoa(String.fromCharCodes(bytes))}',
      )
        ..setAttribute('download', fileName)
        ..style.display = 'none';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
    }
  }

  static void openInBrowser(String url) {
    html.window.open(url, '_blank');
  }

  static Future<String?> saveFile(List<int> bytes, String fileName) async {
    downloadFile(bytes, fileName, 'application/octet-stream');
    return fileName;
  }

  static void printPdf(List<int> bytes, {String title = 'Document'}) {
    try {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, '_blank');
      Future.delayed(const Duration(minutes: 2), () {
        html.Url.revokeObjectUrl(url);
      });
    } catch (_) {
      downloadFile(bytes, '$title.pdf', 'application/pdf');
    }
  }
}
