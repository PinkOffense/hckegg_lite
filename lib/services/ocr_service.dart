// lib/services/ocr_service.dart

import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Result from OCR processing
class OcrResult {
  final String? text;
  final String? error;
  final Uint8List? imageBytes;
  final bool requiresManualInput;

  OcrResult({
    this.text,
    this.error,
    this.imageBytes,
    this.requiresManualInput = false,
  });

  bool get isSuccess => text != null && text!.isNotEmpty && error == null;
  bool get hasImage => imageBytes != null;
}

/// Extracted data from feed bag OCR
class FeedBagData {
  final String? brand;
  final String? feedType;
  final double? weightKg;
  final double? totalPrice;
  final double? pricePerKg;
  final String? lotNumber;
  final String? expiryDate;
  final String? rawText;

  FeedBagData({
    this.brand,
    this.feedType,
    this.weightKg,
    this.totalPrice,
    this.pricePerKg,
    this.lotNumber,
    this.expiryDate,
    this.rawText,
  });
}

/// Extracted data from expense receipt OCR
class ReceiptData {
  final String? vendor;
  final double? totalAmount;
  final String? date;
  final String? description;
  final List<ReceiptItem> items;
  final String? rawText;

  ReceiptData({
    this.vendor,
    this.totalAmount,
    this.date,
    this.description,
    this.items = const [],
    this.rawText,
  });
}

/// Single item from a receipt
class ReceiptItem {
  final String description;
  final double? quantity;
  final double? unitPrice;
  final double? totalPrice;

  ReceiptItem({
    required this.description,
    this.quantity,
    this.unitPrice,
    this.totalPrice,
  });
}

/// OCR Service - handles text recognition across platforms
class OcrService {
  static final OcrService _instance = OcrService._internal();
  factory OcrService() => _instance;
  OcrService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Check if native OCR is available (mobile platforms)
  bool get isNativeOcrAvailable => !kIsWeb;

  /// Pick image from camera or gallery
  Future<XFile?> pickImage(ImageSource source) async {
    return await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
  }

  /// Process image and extract text
  Future<OcrResult> processImage(XFile image) async {
    try {
      // Read image bytes for preview
      final bytes = await image.readAsBytes();

      if (!isNativeOcrAvailable) {
        // On web, return result indicating manual input needed
        return OcrResult(
          imageBytes: bytes,
          requiresManualInput: true,
        );
      }

      // Use ML Kit on mobile
      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer();
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final extractedText = recognizedText.text;

      if (extractedText.isEmpty) {
        return OcrResult(
          imageBytes: bytes,
          error: 'no_text_found',
        );
      }

      return OcrResult(
        text: extractedText,
        imageBytes: bytes,
      );
    } catch (e) {
      return OcrResult(
        error: 'processing_error',
      );
    }
  }

  /// Parse text for feed bag data
  FeedBagData parseFeedBagText(String text) {
    final lowerText = text.toLowerCase();
    final lines = text.split('\n');

    // Brand detection
    String? brand = _extractBrand(lowerText, lines);

    // Feed type detection
    String? feedType = _extractFeedType(lowerText);

    // Weight extraction
    double? weight = _extractWeight(text);

    // Price extraction
    double? totalPrice = _extractPrice(text);

    // Calculate price per kg
    double? pricePerKg;
    if (totalPrice != null && weight != null && weight > 0) {
      pricePerKg = totalPrice / weight;
    }

    // Lot number
    String? lotNumber = _extractLotNumber(text);

    // Expiry date
    String? expiryDate = _extractExpiryDate(text);

    return FeedBagData(
      brand: brand,
      feedType: feedType,
      weightKg: weight,
      totalPrice: totalPrice,
      pricePerKg: pricePerKg,
      lotNumber: lotNumber,
      expiryDate: expiryDate,
      rawText: text,
    );
  }

  /// Parse text for expense receipt data
  ReceiptData parseReceiptText(String text) {
    final lowerText = text.toLowerCase();
    final lines = text.split('\n');

    // Vendor/Store name - usually at the top
    String? vendor = _extractVendor(lines);

    // Total amount
    double? totalAmount = _extractTotal(text, lowerText);

    // Date
    String? date = _extractReceiptDate(text);

    // Description - build from context
    String? description = _buildReceiptDescription(lowerText);

    // Try to extract individual items
    List<ReceiptItem> items = _extractReceiptItems(lines);

    return ReceiptData(
      vendor: vendor,
      totalAmount: totalAmount,
      date: date,
      description: description,
      items: items,
      rawText: text,
    );
  }

  // === Private helper methods ===

  String? _extractBrand(String lowerText, List<String> lines) {
    // Known feed brands
    const knownBrands = [
      'luso alimentos', 'rações valouro', 'provimi', 'cargill',
      'nutreco', 'deheus', 'alltech', 'purina', 'versele-laga',
      'sorgal', 'nanta', 'cefetra', 'fertiberia', 'ovargado',
      'rações zêzere', 'montalva', 'agroportal', 'rações ribatejo',
    ];

    for (final brand in knownBrands) {
      if (lowerText.contains(brand)) {
        return brand.split(' ').map((w) =>
          w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w
        ).join(' ');
      }
    }

    // Try first lines as potential brand name
    for (final line in lines.take(7)) {
      final trimmed = line.trim();
      if (trimmed.length >= 3 &&
          trimmed.length <= 40 &&
          RegExp(r'^[A-Za-zÀ-ÿ0-9\s\-\.]+$').hasMatch(trimmed) &&
          !_isCommonWord(trimmed.toLowerCase()) &&
          !RegExp(r'^\d+$').hasMatch(trimmed)) {
        return trimmed;
      }
    }

    return null;
  }

  String? _extractFeedType(String lowerText) {
    final typePatterns = {
      'layer': ['poedeira', 'poedeiras', 'layer', 'laying', 'postura', 'ovos', 'egg', 'produção', 'galinha poedeira'],
      'grower': ['crescimento', 'grower', 'growing', 'engorda', 'fattening', 'desenvolvimento', 'frango', 'broiler'],
      'starter': ['starter', 'inicial', 'initiation', 'pintos', 'chicks', 'primeiros dias', 'arranque'],
      'scratch': ['scratch', 'milho', 'corn', 'maize', 'cereais', 'grains', 'trigo', 'wheat', 'cevada', 'barley'],
      'supplement': ['suplemento', 'supplement', 'vitamina', 'vitamin', 'mineral', 'premix', 'aditivo', 'concentrado'],
    };

    for (final entry in typePatterns.entries) {
      for (final pattern in entry.value) {
        if (lowerText.contains(pattern)) {
          return entry.key;
        }
      }
    }

    return null;
  }

  double? _extractWeight(String text) {
    final patterns = [
      RegExp(r'(\d+(?:[.,]\d+)?)\s*kg\b', caseSensitive: false),
      RegExp(r'(\d+(?:[.,]\d+)?)\s*quilos?\b', caseSensitive: false),
      RegExp(r'(\d+(?:[.,]\d+)?)\s*kilos?\b', caseSensitive: false),
      RegExp(r'peso\s*(?:líquido)?[:\s]*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'net\s*(?:weight)?[:\s]*(\d+(?:[.,]\d+)?)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final weight = match.group(1)?.replaceAll(',', '.');
        if (weight != null) {
          final value = double.tryParse(weight);
          if (value != null && value > 0 && value <= 100) {
            return value;
          }
        }
      }
    }

    return null;
  }

  double? _extractPrice(String text) {
    final patterns = [
      RegExp(r'€\s*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'(\d+(?:[.,]\d+)?)\s*€', caseSensitive: false),
      RegExp(r'EUR\s*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'preço\s*[:\s]*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'pvp\s*[:\s]*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'(\d+[.,]\d{2})\s*(?:€|EUR)?', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final price = match.group(1)?.replaceAll(',', '.');
        if (price != null) {
          final value = double.tryParse(price);
          if (value != null && value > 0 && value < 1000) {
            return value;
          }
        }
      }
    }

    return null;
  }

  String? _extractLotNumber(String text) {
    final patterns = [
      RegExp(r'lote[:\s]*([A-Z0-9\-]+)', caseSensitive: false),
      RegExp(r'lot[:\s]*([A-Z0-9\-]+)', caseSensitive: false),
      RegExp(r'batch[:\s]*([A-Z0-9\-]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1);
      }
    }

    return null;
  }

  String? _extractExpiryDate(String text) {
    final patterns = [
      RegExp(r'validade[:\s]*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})', caseSensitive: false),
      RegExp(r'expiry[:\s]*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})', caseSensitive: false),
      RegExp(r'exp[:\s]*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})', caseSensitive: false),
      RegExp(r'best\s*before[:\s]*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1);
      }
    }

    return null;
  }

  String? _extractVendor(List<String> lines) {
    // Known store chains in Portugal
    const knownStores = [
      'continente', 'pingo doce', 'lidl', 'aldi', 'intermarché',
      'mercadona', 'minipreço', 'jumbo', 'auchan', 'el corte inglés',
      'agriloja', 'agriarea', 'loja do campo', 'agricampo',
      'bricomarché', 'leroy merlin', 'aki', 'maxmat',
    ];

    // Check first 5 lines for store name
    for (final line in lines.take(5)) {
      final cleanLine = line.trim().toLowerCase();
      for (final store in knownStores) {
        if (cleanLine.contains(store)) {
          return store.split(' ').map((w) =>
            w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w
          ).join(' ');
        }
      }
      // If line looks like a company name
      if (line.trim().length >= 3 &&
          line.trim().length <= 50 &&
          RegExp(r'^[A-Za-zÀ-ÿ0-9\s\-\.,]+$').hasMatch(line.trim())) {
        return line.trim();
      }
    }

    return null;
  }

  double? _extractTotal(String text, String lowerText) {
    final patterns = [
      // Total patterns
      RegExp(r'total[:\s]*€?\s*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'total[:\s]*(\d+(?:[.,]\d+)?)\s*€', caseSensitive: false),
      RegExp(r'a\s*pagar[:\s]*€?\s*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'valor\s*total[:\s]*€?\s*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      // Generic price at end of receipt
      RegExp(r'€\s*(\d+(?:[.,]\d{2}))(?:\s*$|\n)', caseSensitive: false),
    ];

    double? highestAmount;

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amount = match.group(1)?.replaceAll(',', '.');
        if (amount != null) {
          final value = double.tryParse(amount);
          if (value != null && value > 0 && value < 10000) {
            if (highestAmount == null || value > highestAmount) {
              highestAmount = value;
            }
          }
        }
      }
    }

    return highestAmount;
  }

  String? _extractReceiptDate(String text) {
    final patterns = [
      RegExp(r'(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})', caseSensitive: false),
      RegExp(r'(\d{4}[\/\-]\d{1,2}[\/\-]\d{1,2})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1);
      }
    }

    return null;
  }

  String? _buildReceiptDescription(String lowerText) {
    // Determine category based on content
    if (lowerText.contains('ração') || lowerText.contains('feed') ||
        lowerText.contains('alimento') || lowerText.contains('milho')) {
      return 'feed';
    }
    if (lowerText.contains('vacina') || lowerText.contains('medicamento') ||
        lowerText.contains('veterinár')) {
      return 'veterinary';
    }
    if (lowerText.contains('equipamento') || lowerText.contains('bebedouro') ||
        lowerText.contains('comedouro') || lowerText.contains('gaiola')) {
      return 'equipment';
    }
    if (lowerText.contains('luz') || lowerText.contains('água') ||
        lowerText.contains('electric') || lowerText.contains('gás')) {
      return 'utilities';
    }

    return null;
  }

  List<ReceiptItem> _extractReceiptItems(List<String> lines) {
    final items = <ReceiptItem>[];

    // Pattern: description quantity price
    final itemPattern = RegExp(
      r'^(.+?)\s+(\d+(?:[.,]\d+)?)\s*[xX]?\s*(\d+(?:[.,]\d+)?)\s*€?$',
    );

    for (final line in lines) {
      final match = itemPattern.firstMatch(line.trim());
      if (match != null) {
        items.add(ReceiptItem(
          description: match.group(1)?.trim() ?? '',
          quantity: double.tryParse(match.group(2)?.replaceAll(',', '.') ?? ''),
          unitPrice: double.tryParse(match.group(3)?.replaceAll(',', '.') ?? ''),
        ));
      }
    }

    return items;
  }

  bool _isCommonWord(String word) {
    const commonWords = [
      'ração', 'racao', 'feed', 'alimento', 'food', 'animal',
      'para', 'for', 'de', 'of', 'com', 'with', 'em', 'in',
      'aves', 'birds', 'galinhas', 'chickens', 'poultry', 'avícola',
      'peso', 'weight', 'líquido', 'net', 'bruto', 'gross',
      'ingredientes', 'ingredients', 'composição', 'composition',
      'total', 'subtotal', 'iva', 'vat', 'taxa', 'tax',
    ];
    return commonWords.contains(word);
  }
}
