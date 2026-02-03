import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../core/utils/validators.dart';
import '../models/feed_stock.dart';
import '../state/providers/providers.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import '../services/ocr_service.dart' as web_ocr;
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
  Uint8List? _capturedImageBytes;
  bool _showOcrPanel = false;

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
    final t = (String k) => Translations.of(locale, k);
    final picker = ImagePicker();

    // On web, camera is not available — go directly to gallery/file picker
    ImageSource? source;
    if (kIsWeb) {
      source = ImageSource.gallery;
    } else {
      // Show options: camera or gallery (mobile only)
      source = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  t('scan_title'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t('scan_desc'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(t('take_photo')),
                  subtitle: Text(t('use_camera')),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.photo_library,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  title: Text(t('choose_from_gallery')),
                  subtitle: Text(t('select_existing')),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
    }

    if (source == null) return;

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
        requestFullMetadata: false,
      );

      if (image == null) return;

      setState(() {
        _isProcessingOcr = true;
        _ocrError = null;
        _showOcrPanel = true;
      });

      // Read image bytes for preview
      final bytes = await image.readAsBytes();
      setState(() {
        _capturedImageBytes = bytes;
      });

      // Process OCR based on platform
      String extractedText = '';

      if (!kIsWeb) {
        // Use ML Kit on mobile
        final inputImage = InputImage.fromFilePath(image.path);
        final textRecognizer = TextRecognizer();
        final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
        await textRecognizer.close();
        extractedText = recognizedText.text;
      } else {
        // On web, use Tesseract.js for OCR
        extractedText = await web_ocr.recognizeTextFromBytes(bytes);
      }

      if (extractedText.isEmpty) {
        setState(() {
          _isProcessingOcr = false;
          _extractedText = null;
          _ocrError = t('ocr_no_text');
        });
        return;
      }

      setState(() {
        _extractedText = extractedText;
      });

      // Parse the extracted text
      _parseOcrText(extractedText, locale);

      setState(() {
        _isProcessingOcr = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(t('data_extracted'))),
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

    } catch (e) {
      setState(() {
        _isProcessingOcr = false;
        _ocrError = t('error_processing');
      });
    }
  }

  void _parseOcrText(String text, String locale) {
    final t = (String k) => Translations.of(locale, k);
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

    // Extended price patterns (works for both bag labels and invoices)
    final pricePatterns = [
      RegExp(r'€\s*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'(\d+(?:[.,]\d+)?)\s*€', caseSensitive: false),
      RegExp(r'EUR\s*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'(\d+(?:[.,]\d+)?)\s*EUR', caseSensitive: false),
      RegExp(r'preço\s*[:\s]*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'price\s*[:\s]*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'pvp\s*[:\s]*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      // Invoice-specific: total, subtotal
      RegExp(r'total\s*[:\s]*€?\s*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'subtotal\s*[:\s]*€?\s*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'valor\s*[:\s]*€?\s*(\d+(?:[.,]\d+)?)', caseSensitive: false),
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

    // Try to extract lot number, expiry date, invoice info for notes
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

    // Invoice-specific patterns
    final invoicePatterns = [
      RegExp(r'(?:fatura|factura|invoice|fat\.?)\s*(?:n[ºo°.]?\s*)?[:\s]*([A-Z0-9\-\/]+)', caseSensitive: false),
    ];

    final nifPatterns = [
      RegExp(r'(?:nif|contribuinte|tax\s*id)[:\s]*(\d{9})', caseSensitive: false),
    ];

    final supplierPatterns = [
      RegExp(r'(?:fornecedor|supplier|empresa|company)[:\s]*(.+)', caseSensitive: false),
    ];

    final notesLines = <String>[];

    // Extract invoice number
    for (final pattern in invoicePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        notesLines.add('${t('invoice_number')}: ${match.group(1)}');
        break;
      }
    }

    // Extract NIF/Tax ID
    for (final pattern in nifPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        notesLines.add('${t('nif_tax')}: ${match.group(1)}');
        break;
      }
    }

    // Extract supplier name
    for (final pattern in supplierPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final supplier = match.group(1)?.trim();
        if (supplier != null && supplier.length >= 3 && supplier.length <= 60) {
          notesLines.add('${t('supplier_label')}: $supplier');
          // Also use supplier as brand if brand is empty
          if (_brandController.text.isEmpty) {
            _brandController.text = supplier;
          }
          break;
        }
      }
    }

    for (final pattern in lotPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        notesLines.add('${t('lot_label')}: ${match.group(1)}');
        break;
      }
    }

    for (final pattern in expiryPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        notesLines.add('${t('expiry_label')}: ${match.group(1)}');
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
      _capturedImageBytes = null;
      _extractedText = null;
      _ocrError = null;
      _showOcrPanel = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);
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
                      isEditing ? t('edit_stock') : t('new_feed_stock'),
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
                              ? t('processing_ocr')
                              : kIsWeb
                                  ? t('upload_image')
                                  : t('scan_feed_or_invoice'),
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
                      kIsWeb ? t('upload_desc') : t('photo_desc'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (kIsWeb)
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
                              t('ocr_tesseract_info'),
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
            if (_showOcrPanel && (_capturedImageBytes != null || _ocrError != null))
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _ocrError != null
                        ? theme.colorScheme.error.withValues(alpha: 0.5)
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
                            _ocrError != null ? Icons.error_outline : Icons.image,
                            size: 18,
                            color: _ocrError != null
                                ? theme.colorScheme.error
                                : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _ocrError != null ? t('scan_error') : t('captured_image'),
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _ocrError != null
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: _clearOcrData,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: t('close'),
                          ),
                        ],
                      ),
                    ),

                    // Error message
                    if (_ocrError != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Text(
                          _ocrError!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),

                    // Image preview
                    if (_capturedImageBytes != null && _ocrError == null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                _capturedImageBytes!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Extracted info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_extractedText != null) ...[
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 14,
                                          color: Colors.green.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          t('text_extracted_ok'),
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: Colors.green.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      onPressed: () => _showExtractedText(locale),
                                      icon: const Icon(Icons.edit_note, size: 16),
                                      label: Text(t('edit_text')),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
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
                        labelText: t('feed_type_label'),
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
                        labelText: t('brand_label'),
                        prefixIcon: const Icon(Icons.label),
                        hintText: t('brand_hint'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quantity
                    TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: '${t('quantity_label')} (kg) *',
                        prefixIcon: const Icon(Icons.scale),
                        suffixText: 'kg',
                        hintText: t('quantity_hint'),
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
                        labelText: t('min_quantity_label'),
                        prefixIcon: const Icon(Icons.warning_amber),
                        suffixText: 'kg',
                        helperText: t('min_quantity_helper'),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),

                    // Price per kg
                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: t('price_per_kg_label'),
                        prefixIcon: const Icon(Icons.euro),
                        prefixText: '€ ',
                        hintText: t('price_hint'),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: t('notes_label'),
                        prefixIcon: const Icon(Icons.note),
                        alignLabelWithHint: true,
                        hintText: t('notes_hint'),
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
              cancelText: t('cancel'),
              saveText: t('save'),
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }

  void _showExtractedText(String locale) {
    final t = (String k) => Translations.of(locale, k);
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
                t('edit_extracted_text'),
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
                t('correct_text_desc'),
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
                    hintText: t('paste_edit_hint'),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t('cancel')),
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
                        Text(t('text_reprocessed')),
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
            label: Text(t('reprocess')),
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
