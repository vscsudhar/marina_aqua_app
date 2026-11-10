import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

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
  // No-op on mobile/desktop
}

Future<AppPickedFile?> pickImageFile({
  List<String> allowedExtensions = const ['png', 'jpg', 'jpeg', 'webp', 'svg'],
}) async {
  final files = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: allowedExtensions,
  );

  if (files.isEmpty) {
    return null;
  }

  final file = files.first;
  final bytes = await file.xFile.readAsBytes();
  final size = await file.xFile.length();

  return AppPickedFile(
    bytes: bytes,
    name: file.name,
    size: size > 0 ? size : bytes.length,
  );
}
