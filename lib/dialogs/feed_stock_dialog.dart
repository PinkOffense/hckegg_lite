import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/feed_stock.dart';
import '../state/providers/providers.dart';
import '../l10n/locale_provider.dart';

class FeedStockDialog extends StatefulWidget {
  final FeedStock? existingStock;

  const FeedStockDialog({super.key, this.existingStock});

  @override
  State<FeedStockDialog> createState() => _FeedStockDialogState();
}

class _FeedStockDialogState extends State<FeedStockDialog> {
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
    final picker = ImagePicker();

    // Show options: camera or gallery
    final source = await showModalBottomSheet<ImageSource>(
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
                locale == 'pt' ? 'Digitalizar Saco de Ração' : 'Scan Feed Bag',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                locale == 'pt'
                    ? 'Tire uma foto ou escolha uma imagem do saco'
                    : 'Take a photo or choose an image of the bag',
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
                title: Text(locale == 'pt' ? 'Tirar Foto' : 'Take Photo'),
                subtitle: Text(
                  locale == 'pt'
                      ? 'Usar a câmera do dispositivo'
                      : 'Use device camera',
                ),
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
                title: Text(locale == 'pt' ? 'Escolher da Galeria' : 'Choose from Gallery'),
                subtitle: Text(
                  locale == 'pt'
                      ? 'Selecionar uma imagem existente'
                      : 'Select an existing image',
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
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

      if (_canUseNativeOcr) {
        // Use ML Kit on mobile
        final inputImage = InputImage.fromFilePath(image.path);
        final textRecognizer = TextRecognizer();
        final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
        await textRecognizer.close();
        extractedText = recognizedText.text;
      } else {
        // On web, we can't use ML Kit - show manual entry option
        setState(() {
          _isProcessingOcr = false;
          _extractedText = null;
          _ocrError = locale == 'pt'
              ? 'OCR automático não disponível na web. Por favor, insira os dados manualmente ou use a app móvel.'
              : 'Automatic OCR not available on web. Please enter data manually or use the mobile app.';
        });
        return;
      }

      if (extractedText.isEmpty) {
        setState(() {
          _isProcessingOcr = false;
          _extractedText = null;
          _ocrError = locale == 'pt'
              ? 'Não foi possível ler texto na imagem. Tente novamente com melhor iluminação.'
              : 'Could not read text from image. Try again with better lighting.';
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
                Expanded(
                  child: Text(locale == 'pt'
                      ? 'Dados extraídos! Verifique e ajuste se necessário.'
                      : 'Data extracted! Please verify and adjust if needed.'),
                ),
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
        _ocrError = locale == 'pt'
            ? 'Erro ao processar imagem. Tente novamente.'
            : 'Error processing image. Please try again.';
      });
    }
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
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
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
                      theme.colorScheme.primary.withOpacity(0.1),
                      theme.colorScheme.secondary.withOpacity(0.05),
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
            if (_showOcrPanel && (_capturedImageBytes != null || _ocrError != null))
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _ocrError != null
                        ? theme.colorScheme.error.withOpacity(0.5)
                        : theme.colorScheme.primary.withOpacity(0.3),
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
                              _ocrError != null
                                  ? (locale == 'pt' ? 'Erro na Digitalização' : 'Scan Error')
                                  : (locale == 'pt' ? 'Imagem Capturada' : 'Captured Image'),
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
                            tooltip: locale == 'pt' ? 'Fechar' : 'Close',
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
                                          locale == 'pt'
                                              ? 'Texto extraído com sucesso'
                                              : 'Text extracted successfully',
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
                                      icon: const Icon(Icons.visibility, size: 16),
                                      label: Text(
                                        locale == 'pt' ? 'Ver texto completo' : 'View full text',
                                      ),
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return locale == 'pt' ? 'Campo obrigatório' : 'Required field';
                        }
                        if (double.tryParse(value) == null) {
                          return locale == 'pt' ? 'Número inválido' : 'Invalid number';
                        }
                        return null;
                      },
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

            // Footer with buttons
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(locale == 'pt' ? 'Cancelar' : 'Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check),
                    label: Text(locale == 'pt' ? 'Guardar' : 'Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExtractedText(String locale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.text_snippet),
            const SizedBox(width: 12),
            Text(locale == 'pt' ? 'Texto Extraído' : 'Extracted Text'),
          ],
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            _extractedText ?? '',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale == 'pt' ? 'Fechar' : 'Close'),
          ),
        ],
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

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

    context.read<FeedStockProvider>().saveFeedStock(stock);
    Navigator.pop(context);
  }
}
