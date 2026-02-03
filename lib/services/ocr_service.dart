// lib/services/ocr_service.dart
// Conditional import: uses Tesseract.js on web, stub on native
export 'ocr_stub.dart' if (dart.library.html) 'ocr_web.dart';
