// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

class ExportPlatform {
  static void downloadFile(List<int> bytes, String fileName, String mimeType) {
    final u8 = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    try {
      final blob = html.Blob([u8], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..style.display = 'none';

      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();

      // Defer revocation slightly to ensure the browser has scheduled the download
      Future.delayed(const Duration(seconds: 5), () {
        html.Url.revokeObjectUrl(url);
      });
    } catch (e) {
      // Fallback: data URI
      final anchor = html.AnchorElement(
        href: 'data:$mimeType;base64,${base64Encode(u8)}',
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
      final u8 = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
      final blob = html.Blob([u8], 'application/pdf');
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
