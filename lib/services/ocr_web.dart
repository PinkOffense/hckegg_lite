// lib/services/ocr_web.dart
// Web implementation using Tesseract.js for OCR text recognition
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:typed_data';

Future<String> recognizeTextFromBytes(Uint8List imageBytes) async {
  // Check that Tesseract.js is loaded
  final tesseract = js_util.getProperty(html.window, 'Tesseract');
  if (tesseract == null) {
    throw Exception('Tesseract.js not loaded. Please refresh the page.');
  }

  // Create a Blob from the image bytes for Tesseract
  final blob = html.Blob([imageBytes]);

  // Create worker with English + Portuguese language support
  final workerPromise =
      js_util.callMethod(tesseract, 'createWorker', ['eng+por']);
  final worker = await js_util.promiseToFuture(workerPromise);

  try {
    // Run recognition on the image blob
    final resultPromise = js_util.callMethod(worker, 'recognize', [blob]);
    final result = await js_util.promiseToFuture(resultPromise);

    // Extract text from result.data.text
    final data = js_util.getProperty(result, 'data');
    final text = js_util.getProperty(data, 'text') as String? ?? '';

    return text.trim();
  } finally {
    // Always terminate the worker to free resources
    try {
      final terminatePromise = js_util.callMethod(worker, 'terminate', []);
      await js_util.promiseToFuture(terminatePromise);
    } catch (_) {
      // Ignore termination errors
    }
  }
}
