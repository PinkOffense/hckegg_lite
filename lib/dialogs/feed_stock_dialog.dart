import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/feed_stock.dart';
import '../state/app_state.dart';
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

  // Check if running on mobile (not web)
  bool get _isMobile => !kIsWeb;

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
    if (!_isMobile) {
      setState(() {
        _ocrError = locale == 'pt'
            ? 'A digitalização OCR só está disponível na app móvel (iOS/Android)'
            : 'OCR scanning is only available on the mobile app (iOS/Android)';
      });
      return;
    }

    final picker = ImagePicker();

    // Show options: camera or gallery
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(locale == 'pt' ? 'Tirar Foto' : 'Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(locale == 'pt' ? 'Escolher da Galeria' : 'Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
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
      });

      // Process OCR
      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer();
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final extractedText = recognizedText.text;

      if (extractedText.isEmpty) {
        setState(() {
          _isProcessingOcr = false;
          _ocrError = locale == 'pt'
              ? 'Não foi possível ler texto na imagem'
              : 'Could not read text from image';
        });
        return;
      }

      // Parse the extracted text
      _parseOcrText(extractedText, locale);

      setState(() {
        _isProcessingOcr = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locale == 'pt'
                ? 'Dados extraídos com sucesso!'
                : 'Data extracted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      setState(() {
        _isProcessingOcr = false;
        _ocrError = locale == 'pt'
            ? 'Erro ao processar imagem: $e'
            : 'Error processing image: $e';
      });
    }
  }

  void _parseOcrText(String text, String locale) {
    final lowerText = text.toLowerCase();
    final lines = text.split('\n');

    // Try to detect feed type
    if (lowerText.contains('poedeira') || lowerText.contains('layer') || lowerText.contains('postura')) {
      setState(() => _type = FeedType.layer);
    } else if (lowerText.contains('crescimento') || lowerText.contains('grower') || lowerText.contains('engorda')) {
      setState(() => _type = FeedType.grower);
    } else if (lowerText.contains('starter') || lowerText.contains('inicial') || lowerText.contains('pintos')) {
      setState(() => _type = FeedType.starter);
    } else if (lowerText.contains('scratch') || lowerText.contains('milho') || lowerText.contains('cereais')) {
      setState(() => _type = FeedType.scratch);
    } else if (lowerText.contains('suplemento') || lowerText.contains('supplement') || lowerText.contains('vitamina')) {
      setState(() => _type = FeedType.supplement);
    }

    // Try to extract brand (usually one of the first lines with letters)
    for (final line in lines.take(5)) {
      final trimmed = line.trim();
      if (trimmed.length > 2 &&
          RegExp(r'^[A-Za-zÀ-ÿ\s]+$').hasMatch(trimmed) &&
          !_isCommonWord(trimmed.toLowerCase())) {
        _brandController.text = trimmed;
        break;
      }
    }

    // Try to extract weight/quantity (look for kg patterns)
    final weightPatterns = [
      RegExp(r'(\d+(?:[.,]\d+)?)\s*kg', caseSensitive: false),
      RegExp(r'(\d+(?:[.,]\d+)?)\s*quilos?', caseSensitive: false),
      RegExp(r'peso\s*[:\s]*(\d+(?:[.,]\d+)?)', caseSensitive: false),
    ];

    for (final pattern in weightPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final weight = match.group(1)?.replaceAll(',', '.');
        if (weight != null) {
          final weightValue = double.tryParse(weight);
          if (weightValue != null && weightValue > 0 && weightValue <= 1000) {
            _quantityController.text = weight;
            break;
          }
        }
      }
    }

    // Try to extract price (look for € or EUR patterns)
    final pricePatterns = [
      RegExp(r'€\s*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'(\d+(?:[.,]\d+)?)\s*€', caseSensitive: false),
      RegExp(r'EUR\s*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'preço\s*[:\s]*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'price\s*[:\s]*(\d+(?:[.,]\d+)?)', caseSensitive: false),
    ];

    for (final pattern in pricePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final price = match.group(1)?.replaceAll(',', '.');
        if (price != null) {
          final priceValue = double.tryParse(price);
          if (priceValue != null && priceValue > 0 && priceValue < 100) {
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

    // Store the raw OCR text in notes for reference
    if (_notesController.text.isEmpty) {
      _notesController.text = locale == 'pt'
          ? 'Texto extraído:\n$text'
          : 'Extracted text:\n$text';
    }
  }

  bool _isCommonWord(String word) {
    const commonWords = [
      'ração', 'racao', 'feed', 'alimento', 'food',
      'para', 'for', 'de', 'of', 'com', 'with',
      'aves', 'birds', 'galinhas', 'chickens', 'poultry',
      'peso', 'weight', 'líquido', 'liquido', 'net',
      'ingredientes', 'ingredients', 'composição', 'composition',
    ];
    return commonWords.contains(word);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Provider.of<LocaleProvider>(context).code;
    final isEditing = widget.existingStock != null;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    // Responsive constraints
    final dialogWidth = isSmallScreen ? screenSize.width * 0.95 : 500.0;
    final dialogHeight = isSmallScreen ? screenSize.height * 0.85 : 750.0;

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
                  // Scan button - only show on mobile and when not editing
                  if (!isEditing && _isMobile)
                    IconButton(
                      onPressed: _isProcessingOcr ? null : () => _scanFeedBag(locale),
                      icon: _isProcessingOcr
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.camera_alt),
                      tooltip: locale == 'pt' ? 'Digitalizar Saco' : 'Scan Bag',
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // OCR hint - only show on mobile when not editing
            if (!isEditing && _isMobile && _ocrError == null && !_isProcessingOcr)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        locale == 'pt'
                            ? 'Toque na câmera para digitalizar o saco de ração'
                            : 'Tap the camera to scan the feed bag',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Error message
            if (_ocrError != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: theme.colorScheme.errorContainer,
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 18,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _ocrError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _ocrError = null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            // Body
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

    Provider.of<AppState>(context, listen: false).saveFeedStock(stock);
    Navigator.pop(context);
  }
}
