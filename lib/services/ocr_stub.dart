// lib/services/ocr_stub.dart
// Stub for non-web platforms (native OCR uses ML Kit directly)
import 'dart:typed_data';

Future<String> recognizeTextFromBytes(Uint8List imageBytes) async {
  throw UnsupportedError('Web OCR is not available on this platform');
}
