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

  /// Opens a tab synchronously inside the click gesture to prevent popup blocking,
  /// then navigates it to the signed URL once loaded.
  static Future<void> openAsyncUrlInBrowser(
      Future<String> Function() urlLoader) async {
    final win = html.window.open('about:blank', '_blank');
    try {
      final url = await urlLoader();
      (win as dynamic).location.href = url;
    } catch (e) {
      try {
        (win as dynamic).close();
      } catch (_) {}
      rethrow;
    }
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
      final win = html.window.open(url, '_blank');
      // If popup blocker prevented opening a new tab, trigger direct download
      // ignore: unnecessary_null_comparison
      if (win == null) {
        downloadFile(u8, '$title.pdf', 'application/pdf');
      }
      Future.delayed(const Duration(minutes: 2), () {
        html.Url.revokeObjectUrl(url);
      });
    } catch (_) {
      downloadFile(bytes, '$title.pdf', 'application/pdf');
    }
  }
}
