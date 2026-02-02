import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../core/utils/validators.dart';
import '../models/feed_stock.dart';
import '../state/providers/providers.dart';
import '../l10n/locale_provider.dart';
import '../services/ocr_service.dart';
import 'base_dialog.dart';

class FeedStockDialog extends StatefulWidget {
  final FeedStock? existingStock;

  const FeedStockDialog({super.key, this.existingStock});

  @override
  State<FeedStockDialog> createState() => _FeedStockDialogState();
}

class _FeedStockDialogState extends State<FeedStockDialog> with DialogStateMixin {
  final _formKey = GlobalKey<FormState>();
  late FeedType _type;
  final _brandController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minQuantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isProcessingOcr = false;
  String? _ocrError;
  String? _extractedText;
  List<Uint8List> _capturedImages = [];
  bool _showOcrPanel = false;
  OcrConfidence _ocrConfidence = OcrConfidence.none;
  String _selectedQuality = 'standard'; // 'quick', 'standard', 'high'

  // OCR service instance
  final _ocrService = OcrService();

  // Check if running on mobile (not web)
  bool get _canUseNativeOcr => !kIsWeb;

  @override
  void initState() {
    super.initState();
    if (widget.existingStock != null) {
      _type = widget.existingStock!.type;
      _brandController.text = widget.existingStock!.brand ?? '';
      _quantityController.text = widget.existingStock!.currentQuantityKg.toString();
      _minQuantityController.text = widget.existingStock!.minimumQuantityKg.toString();
      _priceController.text = widget.existingStock!.pricePerKg?.toString() ?? '';
      _notesController.text = widget.existingStock!.notes ?? '';
    } else {
      _type = FeedType.layer;
      _minQuantityController.text = '10';
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    _quantityController.dispose();
    _minQuantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _scanFeedBag(String locale) async {
    // Show enhanced options bottom sheet
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _PhotoOptionsSheet(
        locale: locale,
        selectedQuality: _selectedQuality,
        hasExistingImages: _capturedImages.isNotEmpty,
      ),
    );

    if (result == null) return;

    final source = result['source'] as ImageSource?;
    final quality = result['quality'] as String? ?? _selectedQuality;
    final isMultiple = result['multiple'] as bool? ?? false;
    final clearExisting = result['clearExisting'] as bool? ?? false;

    _selectedQuality = quality;

    if (clearExisting) {
      setState(() {
        _capturedImages = [];
        _extractedText = null;
        _ocrError = null;
      });
    }

    // Get quality config
    final config = _getQualityConfig(quality, source ?? ImageSource.camera);

    try {
      List<XFile> images = [];

      if (isMultiple && source == ImageSource.gallery) {
        // Pick multiple images from gallery
        images = await _ocrService.pickMultipleImages(
          maxImages: 5,
          maxWidth: config.maxWidth,
          maxHeight: config.maxHeight,
          imageQuality: config.imageQuality,
        );
      } else if (source != null) {
        // Pick single image
        final image = await _ocrService.pickImage(config);
        if (image != null) {
          images = [image];
        }
      }

      if (images.isEmpty) return;

      setState(() {
        _isProcessingOcr = true;
        _ocrError = null;
        _showOcrPanel = true;
      });

      // Read image bytes for preview
      for (final image in images) {
        final bytes = await image.readAsBytes();
        setState(() {
          _capturedImages.add(bytes);
        });
      }

      // Process OCR based on platform
      if (_canUseNativeOcr) {
        final imagePaths = images.map((img) => img.path).toList();
        final ocrResult = await _ocrService.processMultipleImages(imagePaths);

        if (!ocrResult.hasText) {
          setState(() {
            _isProcessingOcr = false;
            _extractedText = null;
            _ocrConfidence = OcrConfidence.none;
            _ocrError = locale == 'pt'
                ? 'Não foi possível ler texto na imagem. Tente novamente com melhor iluminação ou use qualidade mais alta.'
                : 'Could not read text from image. Try again with better lighting or use higher quality.';
          });
          return;
        }

        setState(() {
          _extractedText = ocrResult.rawText;
          _ocrConfidence = ocrResult.confidence;
        });

        // Apply extracted data to form fields
        _applyExtractedData(ocrResult.extractedData, locale);

        setState(() {
          _isProcessingOcr = false;
        });

        // Show success message with confidence
        if (mounted) {
          _showOcrSuccessMessage(locale, ocrResult.confidence);
        }
      } else {
        // On web, we can't use ML Kit
        setState(() {
          _isProcessingOcr = false;
          _extractedText = null;
          _ocrError = locale == 'pt'
              ? 'OCR automático não disponível na web. Por favor, insira os dados manualmente ou use a app móvel.'
              : 'Automatic OCR not available on web. Please enter data manually or use the mobile app.';
        });
      }
    } catch (e) {
      setState(() {
        _isProcessingOcr = false;
        _ocrError = locale == 'pt'
            ? 'Erro ao processar imagem. Tente novamente.'
            : 'Error processing image. Please try again.';
      });
    }
  }

  ImageCaptureConfig _getQualityConfig(String quality, ImageSource source) {
    switch (quality) {
      case 'quick':
        return ImageCaptureConfig(
          source: source,
          maxWidth: 1280,
          maxHeight: 1280,
          imageQuality: 80,
        );
      case 'high':
        return ImageCaptureConfig(
          source: source,
          maxWidth: 2560,
          maxHeight: 2560,
          imageQuality: 95,
        );
      default: // standard
        return ImageCaptureConfig(
          source: source,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 90,
        );
    }
  }

  void _applyExtractedData(Map<String, dynamic> data, String locale) {
    // Apply brand
    final brand = data['brand'] as String?;
    if (brand != null && brand.isNotEmpty && _brandController.text.isEmpty) {
      _brandController.text = brand;
    }

    // Apply feed type
    final feedType = data['feedType'] as String?;
    if (feedType != null) {
      final type = _parseFeedType(feedType);
      if (type != null) {
        setState(() => _type = type);
      }
    }

    // Apply weight
    final weight = data['weightKg'] as double?;
    if (weight != null && _quantityController.text.isEmpty) {
      _quantityController.text = weight.toString();
    }

    // Apply price
    final pricePerKg = data['pricePerKg'] as double?;
    final priceTotal = data['priceTotal'] as double?;
    if (_priceController.text.isEmpty) {
      if (pricePerKg != null) {
        _priceController.text = pricePerKg.toStringAsFixed(2);
      } else if (priceTotal != null && weight != null && weight > 0) {
        final calculatedPricePerKg = priceTotal / weight;
        _priceController.text = calculatedPricePerKg.toStringAsFixed(2);
      }
    }

    // Apply notes (lot number, expiry)
    final lotNumber = data['lotNumber'] as String?;
    final expiryDate = data['expiryDate'] as String?;
    final proteinContent = data['proteinContent'] as String?;

    if (_notesController.text.isEmpty) {
      final notesLines = <String>[];
      if (lotNumber != null) {
        notesLines.add('${locale == 'pt' ? 'Lote' : 'Lot'}: $lotNumber');
      }
      if (expiryDate != null) {
        notesLines.add('${locale == 'pt' ? 'Validade' : 'Expiry'}: $expiryDate');
      }
      if (proteinContent != null) {
        notesLines.add('${locale == 'pt' ? 'Proteína' : 'Protein'}: $proteinContent');
      }
      if (notesLines.isNotEmpty) {
        _notesController.text = notesLines.join('\n');
      }
    }
  }

  FeedType? _parseFeedType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'layer':
        return FeedType.layer;
      case 'grower':
        return FeedType.grower;
      case 'starter':
        return FeedType.starter;
      case 'scratch':
        return FeedType.scratch;
      case 'supplement':
        return FeedType.supplement;
      default:
        return null;
    }
  }

  void _showOcrSuccessMessage(String locale, OcrConfidence confidence) {
    final confidenceText = switch (confidence) {
      OcrConfidence.high => locale == 'pt' ? 'Alta confiança' : 'High confidence',
      OcrConfidence.medium => locale == 'pt' ? 'Confiança média' : 'Medium confidence',
      OcrConfidence.low => locale == 'pt' ? 'Baixa confiança' : 'Low confidence',
      OcrConfidence.none => locale == 'pt' ? 'Sem dados' : 'No data',
    };

    final color = switch (confidence) {
      OcrConfidence.high => Colors.green.shade600,
      OcrConfidence.medium => Colors.orange.shade600,
      OcrConfidence.low => Colors.amber.shade700,
      OcrConfidence.none => Colors.red.shade600,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              confidence == OcrConfidence.high
                  ? Icons.check_circle
                  : Icons.info_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locale == 'pt'
                        ? 'Dados extraídos! Verifique e ajuste.'
                        : 'Data extracted! Please verify and adjust.',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    confidenceText,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _parseOcrText(String text, String locale) {
    final lowerText = text.toLowerCase();
    final lines = text.split('\n');

    // Extended brand detection - common feed brands in Portugal/Europe
    final knownBrands = [
      'luso alimentos', 'rações valouro', 'provimi', 'cargill',
      'nutreco', 'deheus', 'alltech', 'purina', 'versele-laga',
      'sorgal', 'nanta', 'cefetra', 'fertiberia', 'ovargado',
      'rações zêzere', 'montalva', 'agroportal', 'rações ribatejo',
    ];

    // Try to detect known brand first
    for (final brand in knownBrands) {
      if (lowerText.contains(brand)) {
        // Capitalize properly
        _brandController.text = brand.split(' ').map((w) =>
          w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w
        ).join(' ');
        break;
      }
    }

    // If no known brand, try to extract from first lines
    if (_brandController.text.isEmpty) {
      for (final line in lines.take(7)) {
        final trimmed = line.trim();
        // Look for lines that look like brand names (letters, maybe with numbers)
        if (trimmed.length >= 3 &&
            trimmed.length <= 40 &&
            RegExp(r'^[A-Za-zÀ-ÿ0-9\s\-\.]+$').hasMatch(trimmed) &&
            !_isCommonWord(trimmed.toLowerCase()) &&
            !RegExp(r'^\d+$').hasMatch(trimmed)) {
          _brandController.text = trimmed;
          break;
        }
      }
    }

    // Extended feed type detection
    final typePatterns = {
      FeedType.layer: [
        'poedeira', 'poedeiras', 'layer', 'laying', 'postura',
        'ovos', 'egg', 'produção', 'production', 'galinha poedeira'
      ],
      FeedType.grower: [
        'crescimento', 'grower', 'growing', 'engorda', 'fattening',
        'desenvolvimento', 'development', 'frango', 'broiler'
      ],
      FeedType.starter: [
        'starter', 'inicial', 'initiation', 'pintos', 'chicks',
        'primeiros dias', 'first days', 'arranque', 'start'
      ],
      FeedType.scratch: [
        'scratch', 'milho', 'corn', 'maize', 'cereais', 'grains',
        'cereal', 'trigo', 'wheat', 'cevada', 'barley', 'mistura'
      ],
      FeedType.supplement: [
        'suplemento', 'supplement', 'vitamina', 'vitamin', 'mineral',
        'premix', 'aditivo', 'additive', 'concentrado', 'concentrate'
      ],
    };

    for (final entry in typePatterns.entries) {
      for (final pattern in entry.value) {
        if (lowerText.contains(pattern)) {
          setState(() => _type = entry.key);
          break;
        }
      }
    }

    // Extended weight patterns
    final weightPatterns = [
      RegExp(r'(\d+(?:[.,]\d+)?)\s*kg\b', caseSensitive: false),
      RegExp(r'(\d+(?:[.,]\d+)?)\s*quilos?\b', caseSensitive: false),
      RegExp(r'(\d+(?:[.,]\d+)?)\s*kilos?\b', caseSensitive: false),
      RegExp(r'peso\s*(?:líquido)?[:\s]*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'net\s*(?:weight)?[:\s]*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'conteúdo[:\s]*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:kg|quilos?|kilos?)\s*(?:líquidos?|net)?', caseSensitive: false),
    ];

    for (final pattern in weightPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final weight = match.group(1)?.replaceAll(',', '.');
        if (weight != null) {
          final weightValue = double.tryParse(weight);
          // Common feed bag sizes: 5, 10, 15, 20, 25, 30, 40, 50 kg
          if (weightValue != null && weightValue > 0 && weightValue <= 100) {
            _quantityController.text = weight;
            break;
          }
        }
      }
    }

    // Extended price patterns
    final pricePatterns = [
      RegExp(r'€\s*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'(\d+(?:[.,]\d+)?)\s*€', caseSensitive: false),
      RegExp(r'EUR\s*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'(\d+(?:[.,]\d+)?)\s*EUR', caseSensitive: false),
      RegExp(r'preço\s*[:\s]*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'price\s*[:\s]*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'pvp\s*[:\s]*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'(\d+[.,]\d{2})\s*(?:€|EUR)?', caseSensitive: false), // Matches XX.XX format
    ];

    for (final pattern in pricePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final price = match.group(1)?.replaceAll(',', '.');
        if (price != null) {
          final priceValue = double.tryParse(price);
          if (priceValue != null && priceValue > 0 && priceValue < 500) {
            // Calculate price per kg if we have quantity
            final quantity = double.tryParse(_quantityController.text);
            if (quantity != null && quantity > 0) {
              final pricePerKg = priceValue / quantity;
              _priceController.text = pricePerKg.toStringAsFixed(2);
            } else {
              _priceController.text = price;
            }
            break;
          }
        }
      }
    }

    // Try to extract lot number or expiry date for notes
    final lotPatterns = [
      RegExp(r'lote[:\s]*([A-Z0-9\-]+)', caseSensitive: false),
      RegExp(r'lot[:\s]*([A-Z0-9\-]+)', caseSensitive: false),
      RegExp(r'batch[:\s]*([A-Z0-9\-]+)', caseSensitive: false),
    ];

    final expiryPatterns = [
      RegExp(r'validade[:\s]*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})', caseSensitive: false),
      RegExp(r'expiry[:\s]*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})', caseSensitive: false),
      RegExp(r'exp[:\s]*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})', caseSensitive: false),
      RegExp(r'best\s*before[:\s]*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})', caseSensitive: false),
    ];

    final notesLines = <String>[];

    for (final pattern in lotPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        notesLines.add('${locale == 'pt' ? 'Lote' : 'Lot'}: ${match.group(1)}');
        break;
      }
    }

    for (final pattern in expiryPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        notesLines.add('${locale == 'pt' ? 'Validade' : 'Expiry'}: ${match.group(1)}');
        break;
      }
    }

    if (notesLines.isNotEmpty && _notesController.text.isEmpty) {
      _notesController.text = notesLines.join('\n');
    }
  }

  bool _isCommonWord(String word) {
    const commonWords = [
      'ração', 'racao', 'feed', 'alimento', 'food', 'animal',
      'para', 'for', 'de', 'of', 'com', 'with', 'em', 'in',
      'aves', 'birds', 'galinhas', 'chickens', 'poultry', 'avícola',
      'peso', 'weight', 'líquido', 'liquido', 'net', 'bruto', 'gross',
      'ingredientes', 'ingredients', 'composição', 'composition',
      'modo', 'use', 'uso', 'utilização', 'instruções', 'instructions',
      'fabricado', 'manufactured', 'produzido', 'produced', 'made',
      'portugal', 'espanha', 'spain', 'france', 'europa', 'europe',
      'lote', 'lot', 'batch', 'validade', 'expiry', 'date',
      'conservar', 'store', 'armazenar', 'local', 'place',
    ];
    return commonWords.contains(word.toLowerCase());
  }

  void _clearOcrData() {
    setState(() {
      _capturedImages = [];
      _extractedText = null;
      _ocrError = null;
      _ocrConfidence = OcrConfidence.none;
      _showOcrPanel = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Provider.of<LocaleProvider>(context).code;
    final isEditing = widget.existingStock != null;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    // Responsive constraints
    final dialogWidth = isSmallScreen ? screenSize.width * 0.95 : 550.0;
    final dialogHeight = isSmallScreen ? screenSize.height * 0.9 : 800.0;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 10 : 40,
        vertical: isSmallScreen ? 24 : 40,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2,
                    color: theme.colorScheme.primary,
                    size: isSmallScreen ? 22 : 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEditing
                          ? (locale == 'pt' ? 'Editar Stock' : 'Edit Stock')
                          : (locale == 'pt' ? 'Novo Stock de Ração' : 'New Feed Stock'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 18 : 22,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // OCR Scan Button - Prominent when not editing
            if (!isEditing)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                      theme.colorScheme.secondary.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Main scan button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isProcessingOcr ? null : () => _scanFeedBag(locale),
                        icon: _isProcessingOcr
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.document_scanner),
                        label: Text(
                          _isProcessingOcr
                              ? (locale == 'pt' ? 'A processar...' : 'Processing...')
                              : (locale == 'pt' ? 'Digitalizar Saco de Ração' : 'Scan Feed Bag'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      locale == 'pt'
                          ? 'Tire uma foto do saco para preencher automaticamente'
                          : 'Take a photo of the bag to auto-fill',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!_canUseNativeOcr)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              locale == 'pt'
                                  ? 'OCR completo disponível na app móvel'
                                  : 'Full OCR available on mobile app',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            // Image Preview Panel
            if (_showOcrPanel && (_capturedImages.isNotEmpty || _ocrError != null))
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _ocrError != null
                        ? theme.colorScheme.error.withValues(alpha: 0.5)
                        : _ocrConfidence == OcrConfidence.high
                            ? Colors.green.withValues(alpha: 0.5)
                            : theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Panel header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
                      child: Row(
                        children: [
                          Icon(
                            _ocrError != null
                                ? Icons.error_outline
                                : _ocrConfidence == OcrConfidence.high
                                    ? Icons.check_circle
                                    : Icons.image,
                            size: 18,
                            color: _ocrError != null
                                ? theme.colorScheme.error
                                : _ocrConfidence == OcrConfidence.high
                                    ? Colors.green.shade600
                                    : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _ocrError != null
                                      ? (locale == 'pt' ? 'Erro na Digitalização' : 'Scan Error')
                                      : _capturedImages.length > 1
                                          ? (locale == 'pt'
                                              ? '${_capturedImages.length} Imagens Capturadas'
                                              : '${_capturedImages.length} Images Captured')
                                          : (locale == 'pt' ? 'Imagem Capturada' : 'Captured Image'),
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: _ocrError != null
                                        ? theme.colorScheme.error
                                        : _ocrConfidence == OcrConfidence.high
                                            ? Colors.green.shade600
                                            : theme.colorScheme.primary,
                                  ),
                                ),
                                if (_extractedText != null && _ocrError == null)
                                  Text(
                                    _ocrConfidence == OcrConfidence.high
                                        ? (locale == 'pt' ? 'Alta confiança' : 'High confidence')
                                        : _ocrConfidence == OcrConfidence.medium
                                            ? (locale == 'pt' ? 'Confiança média' : 'Medium confidence')
                                            : (locale == 'pt' ? 'Baixa confiança' : 'Low confidence'),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: _ocrConfidence == OcrConfidence.high
                                          ? Colors.green.shade600
                                          : _ocrConfidence == OcrConfidence.medium
                                              ? Colors.orange.shade600
                                              : Colors.amber.shade700,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: _clearOcrData,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: locale == 'pt' ? 'Fechar' : 'Close',
                          ),
                        ],
                      ),
                    ),

                    // Error message
                    if (_ocrError != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _ocrError!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => _scanFeedBag(locale),
                              icon: const Icon(Icons.refresh, size: 16),
                              label: Text(locale == 'pt' ? 'Tentar novamente' : 'Try again'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Image preview - supports multiple images
                    if (_capturedImages.isNotEmpty && _ocrError == null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image thumbnails
                            SizedBox(
                              height: 80,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _capturedImages.length,
                                itemBuilder: (context, index) => Padding(
                                  padding: EdgeInsets.only(
                                    right: index < _capturedImages.length - 1 ? 8 : 0,
                                  ),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          _capturedImages[index],
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      // Image number badge
                                      if (_capturedImages.length > 1)
                                        Positioned(
                                          top: 4,
                                          left: 4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '${index + 1}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Action buttons
                            if (_extractedText != null)
                              Wrap(
                                spacing: 8,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _showExtractedText(locale),
                                    icon: const Icon(Icons.edit_note, size: 16),
                                    label: Text(locale == 'pt' ? 'Ver/Editar texto' : 'View/Edit text'),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _scanFeedBag(locale),
                                    icon: const Icon(Icons.add_a_photo, size: 16),
                                    label: Text(locale == 'pt' ? 'Adicionar foto' : 'Add photo'),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            // Body - Form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  children: [
                    // Type dropdown
                    DropdownButtonFormField<FeedType>(
                      value: _type,
                      decoration: InputDecoration(
                        labelText: locale == 'pt' ? 'Tipo de Ração' : 'Feed Type',
                        prefixIcon: const Icon(Icons.category),
                      ),
                      items: FeedType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              Text(type.icon, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 12),
                              Text(type.displayName(locale)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _type = value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Brand
                    TextFormField(
                      controller: _brandController,
                      decoration: InputDecoration(
                        labelText: locale == 'pt' ? 'Marca (opcional)' : 'Brand (optional)',
                        prefixIcon: const Icon(Icons.label),
                        hintText: locale == 'pt' ? 'Ex: Purina, Valouro...' : 'E.g.: Purina, Cargill...',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quantity
                    TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: '${locale == 'pt' ? 'Quantidade' : 'Quantity'} (kg) *',
                        prefixIcon: const Icon(Icons.scale),
                        suffixText: 'kg',
                        hintText: locale == 'pt' ? 'Ex: 25' : 'E.g.: 25',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      enabled: !isLoading,
                      validator: FormValidators.positiveNumber(locale: locale),
                    ),
                    const SizedBox(height: 16),

                    // Min quantity
                    TextFormField(
                      controller: _minQuantityController,
                      decoration: InputDecoration(
                        labelText: locale == 'pt' ? 'Quantidade Mínima (kg)' : 'Minimum Quantity (kg)',
                        prefixIcon: const Icon(Icons.warning_amber),
                        suffixText: 'kg',
                        helperText: locale == 'pt'
                            ? 'Alerta quando abaixo deste valor'
                            : 'Alert when below this value',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),

                    // Price per kg
                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: locale == 'pt' ? 'Preço por kg (opcional)' : 'Price per kg (optional)',
                        prefixIcon: const Icon(Icons.euro),
                        prefixText: '€ ',
                        hintText: locale == 'pt' ? 'Ex: 0.85' : 'E.g.: 0.85',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: locale == 'pt' ? 'Notas (opcional)' : 'Notes (optional)',
                        prefixIcon: const Icon(Icons.note),
                        alignLabelWithHint: true,
                        hintText: locale == 'pt'
                            ? 'Lote, validade, observações...'
                            : 'Lot, expiry, observations...',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            // Error banner
            if (hasError)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DialogErrorBanner(
                  message: errorMessage!,
                  onDismiss: clearError,
                ),
              ),

            // Footer with buttons
            DialogFooter(
              onCancel: () => Navigator.pop(context),
              onSave: _save,
              cancelText: locale == 'pt' ? 'Cancelar' : 'Cancel',
              saveText: locale == 'pt' ? 'Guardar' : 'Save',
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }

  void _showExtractedText(String locale) {
    final textController = TextEditingController(text: _extractedText ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.edit_note),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                locale == 'pt' ? 'Editar Texto Extraído' : 'Edit Extracted Text',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                locale == 'pt'
                    ? 'Corrija o texto se necessário e clique em "Reprocessar" para atualizar os campos.'
                    : 'Correct the text if needed and click "Reprocess" to update fields.',
                style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                  color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: TextField(
                  controller: textController,
                  maxLines: 12,
                  style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                    hintText: locale == 'pt'
                        ? 'Cole ou edite o texto aqui...'
                        : 'Paste or edit text here...',
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(locale == 'pt' ? 'Cancelar' : 'Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              final newText = textController.text.trim();
              if (newText.isNotEmpty) {
                setState(() {
                  _extractedText = newText;
                });
                _parseOcrText(newText, locale);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(locale == 'pt'
                            ? 'Texto reprocessado com sucesso!'
                            : 'Text reprocessed successfully!'),
                      ],
                    ),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(locale == 'pt' ? 'Reprocessar' : 'Reprocess'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final locale = Provider.of<LocaleProvider>(context, listen: false).code;

    await executeSave(
      locale: locale,
      saveAction: () async {
        final now = DateTime.now();
        final stock = FeedStock(
          id: widget.existingStock?.id ?? const Uuid().v4(),
          type: _type,
          brand: _brandController.text.isEmpty ? null : _brandController.text,
          currentQuantityKg: double.parse(_quantityController.text),
          minimumQuantityKg: double.tryParse(_minQuantityController.text) ?? 10.0,
          pricePerKg: double.tryParse(_priceController.text),
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          lastUpdated: now,
          createdAt: widget.existingStock?.createdAt ?? now,
        );

        final success = await context.read<FeedStockProvider>().saveFeedStock(stock);
        if (!success) {
          throw Exception(context.read<FeedStockProvider>().error ?? 'Unknown error');
        }
      },
      onSuccess: () {
        if (mounted) {
          Navigator.pop(context);
        }
      },
    );
  }
}

/// Enhanced photo options bottom sheet with quality selection and multiple photo support
class _PhotoOptionsSheet extends StatefulWidget {
  final String locale;
  final String selectedQuality;
  final bool hasExistingImages;

  const _PhotoOptionsSheet({
    required this.locale,
    required this.selectedQuality,
    required this.hasExistingImages,
  });

  @override
  State<_PhotoOptionsSheet> createState() => _PhotoOptionsSheetState();
}

class _PhotoOptionsSheetState extends State<_PhotoOptionsSheet> {
  late String _quality;
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    _quality = widget.selectedQuality;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = widget.locale;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.document_scanner,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locale == 'pt' ? 'Digitalizar Saco de Ração' : 'Scan Feed Bag',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            locale == 'pt'
                                ? 'Tire uma foto para extrair informações automaticamente'
                                : 'Take a photo to automatically extract information',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Main options
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: theme.colorScheme.primary,
                  ),
                ),
                title: Text(locale == 'pt' ? 'Tirar Foto' : 'Take Photo'),
                subtitle: Text(
                  locale == 'pt'
                      ? 'Usar a câmera do dispositivo'
                      : 'Use device camera',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(context, {
                  'source': ImageSource.camera,
                  'quality': _quality,
                  'multiple': false,
                  'clearExisting': false,
                }),
              ),

              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.photo_library,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                title: Text(locale == 'pt' ? 'Escolher da Galeria' : 'Choose from Gallery'),
                subtitle: Text(
                  locale == 'pt'
                      ? 'Selecionar uma imagem existente'
                      : 'Select an existing image',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(context, {
                  'source': ImageSource.gallery,
                  'quality': _quality,
                  'multiple': false,
                  'clearExisting': false,
                }),
              ),

              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.photo_library_outlined,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
                title: Text(locale == 'pt' ? 'Múltiplas Fotos' : 'Multiple Photos'),
                subtitle: Text(
                  locale == 'pt'
                      ? 'Selecionar até 5 imagens da galeria'
                      : 'Select up to 5 images from gallery',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(context, {
                  'source': ImageSource.gallery,
                  'quality': _quality,
                  'multiple': true,
                  'clearExisting': !widget.hasExistingImages,
                }),
              ),

              const Divider(height: 24),

              // Advanced options toggle
              ListTile(
                leading: Icon(
                  _showAdvanced ? Icons.expand_less : Icons.expand_more,
                  color: theme.colorScheme.primary,
                ),
                title: Text(
                  locale == 'pt' ? 'Opções Avançadas' : 'Advanced Options',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () => setState(() => _showAdvanced = !_showAdvanced),
              ),

              // Advanced options panel
              if (_showAdvanced) ...[
                // Quality selection
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale == 'pt' ? 'Qualidade da Imagem' : 'Image Quality',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _QualityOption(
                              label: locale == 'pt' ? 'Rápido' : 'Quick',
                              subtitle: '1280px',
                              icon: Icons.bolt,
                              isSelected: _quality == 'quick',
                              onTap: () => setState(() => _quality = 'quick'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _QualityOption(
                              label: locale == 'pt' ? 'Normal' : 'Standard',
                              subtitle: '1920px',
                              icon: Icons.check_circle_outline,
                              isSelected: _quality == 'standard',
                              onTap: () => setState(() => _quality = 'standard'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _QualityOption(
                              label: locale == 'pt' ? 'Alta' : 'High',
                              subtitle: '2560px',
                              icon: Icons.hd,
                              isSelected: _quality == 'high',
                              onTap: () => setState(() => _quality = 'high'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        locale == 'pt'
                            ? 'Qualidade alta melhora a precisão do OCR mas demora mais'
                            : 'Higher quality improves OCR accuracy but takes longer',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tips section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            locale == 'pt' ? 'Dicas para melhor OCR' : 'Tips for better OCR',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _TipItem(
                        icon: Icons.wb_sunny_outlined,
                        text: locale == 'pt'
                            ? 'Use boa iluminação natural'
                            : 'Use good natural lighting',
                      ),
                      _TipItem(
                        icon: Icons.crop_free,
                        text: locale == 'pt'
                            ? 'Enquadre bem a etiqueta do saco'
                            : 'Frame the bag label properly',
                      ),
                      _TipItem(
                        icon: Icons.blur_off,
                        text: locale == 'pt'
                            ? 'Evite fotos desfocadas ou tremidas'
                            : 'Avoid blurry or shaky photos',
                      ),
                      _TipItem(
                        icon: Icons.collections,
                        text: locale == 'pt'
                            ? 'Tire múltiplas fotos para melhor extração'
                            : 'Take multiple photos for better extraction',
                      ),
                    ],
                  ),
                ),
              ],

              // Clear existing images option
              if (widget.hasExistingImages) ...[
                const SizedBox(height: 8),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    locale == 'pt' ? 'Limpar Imagens Existentes' : 'Clear Existing Images',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  onTap: () => Navigator.pop(context, {
                    'clearExisting': true,
                  }),
                ),
              ],

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _QualityOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _QualityOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TipItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
