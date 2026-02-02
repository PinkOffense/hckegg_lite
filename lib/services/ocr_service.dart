import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// Configuration for image capture
class ImageCaptureConfig {
  final ImageSource source;
  final int maxWidth;
  final int maxHeight;
  final int imageQuality;
  final CameraDevice preferredCamera;

  const ImageCaptureConfig({
    required this.source,
    this.maxWidth = 2048,
    this.maxHeight = 2048,
    this.imageQuality = 90,
    this.preferredCamera = CameraDevice.rear,
  });

  /// High quality for OCR - larger images, better recognition
  static const ocrHighQuality = ImageCaptureConfig(
    source: ImageSource.camera,
    maxWidth: 2048,
    maxHeight: 2048,
    imageQuality: 95,
  );

  /// Standard quality for OCR
  static const ocrStandard = ImageCaptureConfig(
    source: ImageSource.camera,
    maxWidth: 1920,
    maxHeight: 1920,
    imageQuality: 90,
  );

  /// Low quality for quick scans
  static const ocrQuick = ImageCaptureConfig(
    source: ImageSource.camera,
    maxWidth: 1280,
    maxHeight: 1280,
    imageQuality: 80,
  );

  /// Profile photo quality
  static const profilePhoto = ImageCaptureConfig(
    source: ImageSource.camera,
    maxWidth: 512,
    maxHeight: 512,
    imageQuality: 85,
    preferredCamera: CameraDevice.front,
  );
}

/// Result of OCR processing
class OcrResult {
  final String rawText;
  final List<TextBlock> textBlocks;
  final OcrConfidence confidence;
  final Map<String, dynamic> extractedData;
  final Duration processingTime;

  const OcrResult({
    required this.rawText,
    required this.textBlocks,
    required this.confidence,
    required this.extractedData,
    required this.processingTime,
  });

  bool get hasText => rawText.isNotEmpty;
  bool get isHighConfidence => confidence == OcrConfidence.high;
}

enum OcrConfidence { high, medium, low, none }

/// Feed bag data extracted from OCR
class FeedBagData {
  final String? brand;
  final String? feedType;
  final double? weightKg;
  final double? priceTotal;
  final double? pricePerKg;
  final String? lotNumber;
  final String? expiryDate;
  final String? composition;
  final double confidence;

  const FeedBagData({
    this.brand,
    this.feedType,
    this.weightKg,
    this.priceTotal,
    this.pricePerKg,
    this.lotNumber,
    this.expiryDate,
    this.composition,
    this.confidence = 0.0,
  });

  bool get hasData => brand != null || feedType != null || weightKg != null;
}

/// Enhanced OCR service with preprocessing and smart parsing
class OcrService {
  static final OcrService _instance = OcrService._internal();
  factory OcrService() => _instance;
  OcrService._internal();

  final ImagePicker _picker = ImagePicker();
  TextRecognizer? _textRecognizer;

  bool get isAvailable => !kIsWeb;

  /// Pick image with configurable options
  Future<XFile?> pickImage(ImageCaptureConfig config) async {
    try {
      return await _picker.pickImage(
        source: config.source,
        maxWidth: config.maxWidth.toDouble(),
        maxHeight: config.maxHeight.toDouble(),
        imageQuality: config.imageQuality,
        preferredCameraDevice: config.preferredCamera,
      );
    } catch (e) {
      return null;
    }
  }

  /// Pick multiple images for batch processing
  Future<List<XFile>> pickMultipleImages({
    int maxImages = 3,
    int maxWidth = 1920,
    int maxHeight = 1920,
    int imageQuality = 90,
  }) async {
    try {
      final images = await _picker.pickMultiImage(
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
        limit: maxImages,
      );
      return images;
    } catch (e) {
      return [];
    }
  }

  /// Process image and extract text with confidence scoring
  Future<OcrResult> processImage(String imagePath) async {
    if (!isAvailable) {
      return OcrResult(
        rawText: '',
        textBlocks: [],
        confidence: OcrConfidence.none,
        extractedData: {},
        processingTime: Duration.zero,
      );
    }

    final stopwatch = Stopwatch()..start();

    try {
      _textRecognizer ??= TextRecognizer();
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer!.processImage(inputImage);

      stopwatch.stop();

      final confidence = _calculateConfidence(recognizedText);
      final extractedData = _extractFeedBagData(recognizedText.text);

      return OcrResult(
        rawText: recognizedText.text,
        textBlocks: recognizedText.blocks,
        confidence: confidence,
        extractedData: extractedData,
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return OcrResult(
        rawText: '',
        textBlocks: [],
        confidence: OcrConfidence.none,
        extractedData: {},
        processingTime: stopwatch.elapsed,
      );
    }
  }

  /// Process multiple images and merge results
  Future<OcrResult> processMultipleImages(List<String> imagePaths) async {
    if (imagePaths.isEmpty) {
      return OcrResult(
        rawText: '',
        textBlocks: [],
        confidence: OcrConfidence.none,
        extractedData: {},
        processingTime: Duration.zero,
      );
    }

    final stopwatch = Stopwatch()..start();
    final allText = StringBuffer();
    final allBlocks = <TextBlock>[];
    final allExtractedData = <String, dynamic>{};

    for (final path in imagePaths) {
      final result = await processImage(path);
      if (result.hasText) {
        allText.writeln(result.rawText);
        allBlocks.addAll(result.textBlocks);

        // Merge extracted data, preferring non-null values
        result.extractedData.forEach((key, value) {
          if (value != null && allExtractedData[key] == null) {
            allExtractedData[key] = value;
          }
        });
      }
    }

    stopwatch.stop();

    final combinedText = allText.toString();
    final confidence = _calculateTextConfidence(combinedText);

    return OcrResult(
      rawText: combinedText,
      textBlocks: allBlocks,
      confidence: confidence,
      extractedData: allExtractedData.isEmpty
          ? _extractFeedBagData(combinedText)
          : allExtractedData,
      processingTime: stopwatch.elapsed,
    );
  }

  OcrConfidence _calculateConfidence(RecognizedText recognizedText) {
    if (recognizedText.text.isEmpty) return OcrConfidence.none;

    // Calculate based on number of blocks and text length
    final blockCount = recognizedText.blocks.length;
    final textLength = recognizedText.text.length;

    if (blockCount >= 5 && textLength >= 100) return OcrConfidence.high;
    if (blockCount >= 2 && textLength >= 30) return OcrConfidence.medium;
    return OcrConfidence.low;
  }

  OcrConfidence _calculateTextConfidence(String text) {
    if (text.isEmpty) return OcrConfidence.none;
    if (text.length >= 200) return OcrConfidence.high;
    if (text.length >= 50) return OcrConfidence.medium;
    return OcrConfidence.low;
  }

  Map<String, dynamic> _extractFeedBagData(String text) {
    final lowerText = text.toLowerCase();
    final result = <String, dynamic>{};

    // Extract brand
    result['brand'] = _extractBrand(text, lowerText);

    // Extract feed type
    result['feedType'] = _extractFeedType(lowerText);

    // Extract weight
    result['weightKg'] = _extractWeight(text, lowerText);

    // Extract price
    final priceData = _extractPrice(text, lowerText);
    result['priceTotal'] = priceData['total'];
    result['pricePerKg'] = priceData['perKg'];

    // Extract lot number
    result['lotNumber'] = _extractLotNumber(text);

    // Extract expiry date
    result['expiryDate'] = _extractExpiryDate(text);

    // Extract composition/protein content
    result['proteinContent'] = _extractProteinContent(text, lowerText);

    // Calculate confidence
    int fieldsFound = result.values.where((v) => v != null).length;
    result['confidence'] = fieldsFound / 7.0;

    return result;
  }

  String? _extractBrand(String text, String lowerText) {
    // Extended brand list - Portuguese, Spanish, and European feed brands
    const knownBrands = [
      // Portuguese brands
      'luso alimentos', 'rações valouro', 'valouro', 'sorgal', 'montalva',
      'rações zêzere', 'zêzere', 'agroportal', 'rações ribatejo', 'ribatejo',
      'ovargado', 'sapec agro', 'fertiprado', 'agromais', 'nutriaves',
      'avibom', 'raçaves', 'nutrição animal', 'ração nacional',
      // Spanish brands
      'nanta', 'coren', 'vall companys', 'guissona', 'nutreco españa',
      'cefetra', 'fertiberia', 'agroveco', 'piensos costa',
      // International brands
      'provimi', 'cargill', 'nutreco', 'deheus', 'de heus', 'alltech',
      'purina', 'versele-laga', 'versele laga', 'trouw nutrition',
      'adm animal nutrition', 'adm', 'kemin', 'dsm', 'evonik',
      'biomin', 'novus', 'zinpro', 'lallemand', 'phileo',
      // Generic/descriptive
      'alimento composto', 'ração completa', 'complete feed',
    ];

    for (final brand in knownBrands) {
      if (lowerText.contains(brand)) {
        // Capitalize properly
        return brand.split(' ').map((w) =>
          w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w
        ).join(' ');
      }
    }

    // Try to extract from first lines (often contains brand name)
    final lines = text.split('\n');
    for (final line in lines.take(5)) {
      final trimmed = line.trim();
      // Look for lines that look like brand names
      if (trimmed.length >= 3 &&
          trimmed.length <= 35 &&
          RegExp(r'^[A-Za-zÀ-ÿ0-9\s\-\.&]+$').hasMatch(trimmed) &&
          !_isCommonWord(trimmed.toLowerCase()) &&
          !RegExp(r'^\d+$').hasMatch(trimmed) &&
          !_containsOnlyNumbers(trimmed)) {
        return trimmed;
      }
    }

    return null;
  }

  String? _extractFeedType(String lowerText) {
    // Feed type patterns with priority
    const typePatterns = {
      'layer': [
        'poedeira', 'poedeiras', 'layer', 'laying', 'postura',
        'produção de ovos', 'egg production', 'galinha poedeira',
        'ponedora', 'ponedoras', 'puesta',
      ],
      'grower': [
        'crescimento', 'grower', 'growing', 'engorda', 'fattening',
        'desenvolvimento', 'development', 'frango', 'broiler',
        'crecimiento', 'acabado', 'finishing',
      ],
      'starter': [
        'starter', 'inicial', 'initiation', 'pintos', 'chicks',
        'primeiros dias', 'first days', 'arranque', 'start',
        'iniciador', 'pollitos', 'pre-starter', 'pre starter',
      ],
      'scratch': [
        'scratch', 'milho', 'corn', 'maize', 'cereais', 'grains',
        'cereal', 'trigo', 'wheat', 'cevada', 'barley', 'mistura',
        'mezcla', 'mixture', 'granulado',
      ],
      'supplement': [
        'suplemento', 'supplement', 'vitamina', 'vitamin', 'mineral',
        'premix', 'aditivo', 'additive', 'concentrado', 'concentrate',
        'núcleo', 'nucleo', 'core', 'corrector',
      ],
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

  double? _extractWeight(String text, String lowerText) {
    // Weight patterns - comprehensive list
    final weightPatterns = [
      // Explicit weight labels
      RegExp(r'peso\s*(?:líquido|liquido|neto|net)?[:\s]*(\d+(?:[.,]\d+)?)\s*(?:kg|quilos?|kilos?)', caseSensitive: false),
      RegExp(r'net\s*(?:weight|wt)?[:\s]*(\d+(?:[.,]\d+)?)\s*(?:kg|quilos?|kilos?)', caseSensitive: false),
      RegExp(r'conteúdo[:\s]*(\d+(?:[.,]\d+)?)\s*(?:kg|quilos?|kilos?)', caseSensitive: false),
      RegExp(r'contenido[:\s]*(\d+(?:[.,]\d+)?)\s*(?:kg|quilos?|kilos?)', caseSensitive: false),
      // Simple kg patterns
      RegExp(r'(\d+(?:[.,]\d+)?)\s*kg\b', caseSensitive: false),
      RegExp(r'(\d+(?:[.,]\d+)?)\s*quilos?\b', caseSensitive: false),
      RegExp(r'(\d+(?:[.,]\d+)?)\s*kilos?\b', caseSensitive: false),
      // With "saco" (bag)
      RegExp(r'saco\s*(?:de)?\s*(\d+(?:[.,]\d+)?)\s*(?:kg|quilos?|kilos?)', caseSensitive: false),
      RegExp(r'bolsa\s*(?:de)?\s*(\d+(?:[.,]\d+)?)\s*(?:kg|quilos?|kilos?)', caseSensitive: false),
    ];

    for (final pattern in weightPatterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final weightStr = match.group(1)?.replaceAll(',', '.');
        if (weightStr != null) {
          final weight = double.tryParse(weightStr);
          // Common feed bag sizes: 5, 10, 15, 20, 25, 30, 40, 50 kg
          if (weight != null && weight >= 1 && weight <= 100) {
            return weight;
          }
        }
      }
    }

    return null;
  }

  Map<String, double?> _extractPrice(String text, String lowerText) {
    double? total;
    double? perKg;

    // Price per kg patterns
    final perKgPatterns = [
      RegExp(r'€\s*(\d+(?:[.,]\d+)?)\s*/\s*kg', caseSensitive: false),
      RegExp(r'(\d+(?:[.,]\d+)?)\s*€\s*/\s*kg', caseSensitive: false),
      RegExp(r'preço\s*(?:por)?\s*kg[:\s]*€?\s*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'price\s*(?:per)?\s*kg[:\s]*€?\s*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'€/kg[:\s]*(\d+(?:[.,]\d+)?)', caseSensitive: false),
    ];

    for (final pattern in perKgPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final priceStr = match.group(1)?.replaceAll(',', '.');
        final price = double.tryParse(priceStr ?? '');
        if (price != null && price > 0 && price < 50) {
          perKg = price;
          break;
        }
      }
    }

    // Total price patterns
    final totalPatterns = [
      RegExp(r'total[:\s]*€?\s*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'pvp[:\s]*€?\s*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'preço[:\s]*€?\s*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'price[:\s]*€?\s*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'€\s*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'(\d+(?:[.,]\d+)?)\s*€', caseSensitive: false),
      RegExp(r'EUR\s*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      // Format XX.XX (typical price format)
      RegExp(r'\b(\d{1,3}[.,]\d{2})\b', caseSensitive: false),
    ];

    if (perKg == null) {
      for (final pattern in totalPatterns) {
        final match = pattern.firstMatch(text);
        if (match != null) {
          final priceStr = match.group(1)?.replaceAll(',', '.');
          final price = double.tryParse(priceStr ?? '');
          if (price != null && price > 0 && price < 500) {
            total = price;
            break;
          }
        }
      }
    }

    return {'total': total, 'perKg': perKg};
  }

  String? _extractLotNumber(String text) {
    final lotPatterns = [
      RegExp(r'lote[:\s]*([A-Z0-9\-/]+)', caseSensitive: false),
      RegExp(r'lot[:\s]*([A-Z0-9\-/]+)', caseSensitive: false),
      RegExp(r'batch[:\s]*([A-Z0-9\-/]+)', caseSensitive: false),
      RegExp(r'nº\s*lote[:\s]*([A-Z0-9\-/]+)', caseSensitive: false),
      RegExp(r'l[:\s]*([A-Z0-9]{5,15})', caseSensitive: false), // Short form
    ];

    for (final pattern in lotPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1);
      }
    }

    return null;
  }

  String? _extractExpiryDate(String text) {
    final expiryPatterns = [
      // Full date formats
      RegExp(r'validade[:\s]*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})', caseSensitive: false),
      RegExp(r'expiry[:\s]*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})', caseSensitive: false),
      RegExp(r'exp\.?[:\s]*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})', caseSensitive: false),
      RegExp(r'best\s*before[:\s]*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})', caseSensitive: false),
      RegExp(r'consumir\s*(?:antes|até)[:\s]*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})', caseSensitive: false),
      RegExp(r'caducidade[:\s]*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})', caseSensitive: false),
      // Month/year formats
      RegExp(r'validade[:\s]*(\d{1,2}[\/\-\.]\d{2,4})', caseSensitive: false),
      RegExp(r'exp\.?[:\s]*(\d{1,2}[\/\-\.]\d{2,4})', caseSensitive: false),
    ];

    for (final pattern in expiryPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1);
      }
    }

    return null;
  }

  String? _extractProteinContent(String text, String lowerText) {
    final proteinPatterns = [
      RegExp(r'proteína\s*(?:bruta)?[:\s]*(\d+(?:[.,]\d+)?)\s*%', caseSensitive: false),
      RegExp(r'protein[:\s]*(\d+(?:[.,]\d+)?)\s*%', caseSensitive: false),
      RegExp(r'pb[:\s]*(\d+(?:[.,]\d+)?)\s*%', caseSensitive: false),
      RegExp(r'crude\s*protein[:\s]*(\d+(?:[.,]\d+)?)', caseSensitive: false),
    ];

    for (final pattern in proteinPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return '${match.group(1)}%';
      }
    }

    return null;
  }

  bool _isCommonWord(String word) {
    const commonWords = [
      // Portuguese
      'ração', 'racao', 'alimento', 'para', 'de', 'com', 'em', 'os', 'as',
      'aves', 'galinhas', 'frangos', 'peso', 'líquido', 'liquido', 'bruto',
      'ingredientes', 'composição', 'composicao', 'modo', 'uso', 'utilização',
      'fabricado', 'produzido', 'portugal', 'espanha', 'lote', 'validade',
      'conservar', 'armazenar', 'local', 'seco', 'fresco', 'protegido',
      'indicações', 'indicacoes', 'avisos', 'atenção', 'atencao',
      // English
      'feed', 'food', 'animal', 'for', 'of', 'with', 'in', 'the',
      'birds', 'chickens', 'poultry', 'weight', 'net', 'gross',
      'ingredients', 'composition', 'use', 'instructions',
      'manufactured', 'produced', 'made', 'lot', 'batch', 'expiry', 'date',
      'store', 'keep', 'place', 'dry', 'cool', 'protected',
      // Spanish
      'pienso', 'alimento', 'animales', 'contenido', 'neto',
      'ingredientes', 'composición', 'fabricado', 'producido',
    ];
    return commonWords.contains(word.toLowerCase());
  }

  bool _containsOnlyNumbers(String text) {
    return RegExp(r'^[\d\s\.,]+$').hasMatch(text);
  }

  /// Close resources
  Future<void> dispose() async {
    await _textRecognizer?.close();
    _textRecognizer = null;
  }
}
