import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:file_picker_web/file_picker_web.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:printing/printing_web.dart';
import 'package:web/web.dart' as web;

class AppPickedFile {
  final Uint8List bytes;
  final String name;
  final int size;

  const AppPickedFile({
    required this.bytes,
    required this.name,
    required this.size,
  });
}

void initializeFilePicker() {
  try {
    FilePickerWeb.registerWith(webPluginRegistrar);
  } catch (_) {}
  try {
    PrintingPlugin.registerWith(webPluginRegistrar);
  } catch (_) {}
}

Future<AppPickedFile?> pickImageFile({
  List<String> allowedExtensions = const ['png', 'jpg', 'jpeg', 'webp', 'svg'],
}) async {
  // Ensure the web plugin is registered just in case
  initializeFilePicker();

  final completer = Completer<AppPickedFile?>();
  final uploadInput = web.document.createElement('input') as web.HTMLInputElement;
  uploadInput.type = 'file';
  uploadInput.accept = allowedExtensions.map((e) => '.$e').join(',');
  uploadInput.style.display = 'none';

  final body = web.document.body;
  if (body != null) {
    body.appendChild(uploadInput);
  }

  void cleanup() {
    uploadInput.remove();
  }

  uploadInput.addEventListener(
    'change',
    ((web.Event _) {
      final files = uploadInput.files;
      if (files == null || files.length == 0) {
        cleanup();
        if (!completer.isCompleted) completer.complete(null);
        return;
      }

      final file = files.item(0);
      if (file == null) {
        cleanup();
        if (!completer.isCompleted) completer.complete(null);
        return;
      }

      final reader = web.FileReader();
      reader.addEventListener(
        'loadend',
        ((web.Event _) {
          cleanup();
          final result = reader.result;
          if (result != null) {
            final arrayBuffer = result as JSArrayBuffer;
            final bytes = arrayBuffer.toDart.asUint8List();
            if (!completer.isCompleted) {
              completer.complete(AppPickedFile(
                bytes: bytes,
                name: file.name,
                size: file.size,
              ));
            }
          } else {
            if (!completer.isCompleted) completer.complete(null);
          }
        }).toJS,
      );

      reader.addEventListener(
        'error',
        ((web.Event _) {
          cleanup();
          if (!completer.isCompleted) completer.complete(null);
        }).toJS,
      );

      reader.readAsArrayBuffer(file);
    }).toJS,
  );

  uploadInput.addEventListener(
    'cancel',
    ((web.Event _) {
      cleanup();
      if (!completer.isCompleted) completer.complete(null);
    }).toJS,
  );

  uploadInput.click();
  return completer.future;
}
