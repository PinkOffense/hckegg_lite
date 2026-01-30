// lib/widgets/ocr_scanner_widget.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_service.dart';

/// Type of OCR scan
enum OcrScanType {
  feedBag,
  receipt,
}

/// Widget for OCR scanning with manual text correction
class OcrScannerWidget extends StatefulWidget {
  final String locale;
  final OcrScanType scanType;
  final Function(String text)? onTextExtracted;
  final Function(FeedBagData data)? onFeedBagParsed;
  final Function(ReceiptData data)? onReceiptParsed;

  const OcrScannerWidget({
    super.key,
    required this.locale,
    required this.scanType,
    this.onTextExtracted,
    this.onFeedBagParsed,
    this.onReceiptParsed,
  });

  @override
  State<OcrScannerWidget> createState() => _OcrScannerWidgetState();
}

class _OcrScannerWidgetState extends State<OcrScannerWidget> {
  final OcrService _ocrService = OcrService();
  final TextEditingController _textController = TextEditingController();

  bool _isProcessing = false;
  String? _error;
  Uint8List? _imageBytes;
  bool _showTextEditor = false;
  bool _hasExtractedText = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    final source = await _showSourcePicker();
    if (source == null) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final image = await _ocrService.pickImage(source);
      if (image == null) {
        setState(() => _isProcessing = false);
        return;
      }

      final result = await _ocrService.processImage(image);

      setState(() {
        _imageBytes = result.imageBytes;
        _isProcessing = false;
      });

      if (result.requiresManualInput) {
        // On web, show manual text input
        setState(() {
          _showTextEditor = true;
          _textController.text = '';
        });
        _showManualInputInfo();
      } else if (result.error != null) {
        setState(() {
          _error = _getErrorMessage(result.error!);
        });
      } else if (result.isSuccess) {
        setState(() {
          _textController.text = result.text!;
          _hasExtractedText = true;
          _showTextEditor = true;
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _error = _getErrorMessage('processing_error');
      });
    }
  }

  Future<ImageSource?> _showSourcePicker() async {
    return showModalBottomSheet<ImageSource>(
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
                _getScanTitle(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getScanSubtitle(),
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
                title: Text(widget.locale == 'pt' ? 'Tirar Foto' : 'Take Photo'),
                subtitle: Text(widget.locale == 'pt'
                    ? 'Usar a câmera do dispositivo'
                    : 'Use device camera'),
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
                title: Text(widget.locale == 'pt' ? 'Escolher da Galeria' : 'Choose from Gallery'),
                subtitle: Text(widget.locale == 'pt'
                    ? 'Selecionar uma imagem existente'
                    : 'Select an existing image'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showManualInputInfo() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(widget.locale == 'pt'
                    ? 'OCR automático não disponível. Cole ou digite o texto do documento.'
                    : 'Auto OCR not available. Paste or type document text.'),
              ),
            ],
          ),
          backgroundColor: Colors.blue.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _processText() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _error = widget.locale == 'pt'
            ? 'Por favor, insira o texto do documento'
            : 'Please enter the document text';
      });
      return;
    }

    // Notify parent of raw text
    widget.onTextExtracted?.call(text);

    // Parse based on scan type
    if (widget.scanType == OcrScanType.feedBag) {
      final data = _ocrService.parseFeedBagText(text);
      widget.onFeedBagParsed?.call(data);
    } else {
      final data = _ocrService.parseReceiptText(text);
      widget.onReceiptParsed?.call(data);
    }

    // Show success
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(widget.locale == 'pt'
                    ? 'Dados extraídos! Verifique e ajuste se necessário.'
                    : 'Data extracted! Please verify and adjust if needed.'),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    // Close editor
    setState(() {
      _showTextEditor = false;
    });
  }

  void _clearData() {
    setState(() {
      _imageBytes = null;
      _textController.clear();
      _error = null;
      _showTextEditor = false;
      _hasExtractedText = false;
    });
  }

  String _getScanTitle() {
    if (widget.scanType == OcrScanType.feedBag) {
      return widget.locale == 'pt' ? 'Digitalizar Saco de Ração' : 'Scan Feed Bag';
    }
    return widget.locale == 'pt' ? 'Digitalizar Recibo' : 'Scan Receipt';
  }

  String _getScanSubtitle() {
    if (widget.scanType == OcrScanType.feedBag) {
      return widget.locale == 'pt'
          ? 'Tire uma foto ou escolha uma imagem do saco'
          : 'Take a photo or choose an image of the bag';
    }
    return widget.locale == 'pt'
        ? 'Tire uma foto ou escolha uma imagem do recibo'
        : 'Take a photo or choose an image of the receipt';
  }

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'no_text_found':
        return widget.locale == 'pt'
            ? 'Não foi possível ler texto na imagem. Tente novamente com melhor iluminação.'
            : 'Could not read text from image. Try again with better lighting.';
      case 'processing_error':
        return widget.locale == 'pt'
            ? 'Erro ao processar imagem. Tente novamente.'
            : 'Error processing image. Please try again.';
      default:
        return widget.locale == 'pt'
            ? 'Erro desconhecido. Tente novamente.'
            : 'Unknown error. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Scan button
        Container(
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
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isProcessing ? null : _startScan,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(widget.scanType == OcrScanType.feedBag
                          ? Icons.document_scanner
                          : Icons.receipt_long),
                  label: Text(
                    _isProcessing
                        ? (widget.locale == 'pt' ? 'A processar...' : 'Processing...')
                        : _getScanTitle(),
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
                widget.scanType == OcrScanType.feedBag
                    ? (widget.locale == 'pt'
                        ? 'Tire uma foto do saco para preencher automaticamente'
                        : 'Take a photo of the bag to auto-fill')
                    : (widget.locale == 'pt'
                        ? 'Tire uma foto do recibo para preencher automaticamente'
                        : 'Take a photo of the receipt to auto-fill'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (!_ocrService.isNativeOcrAvailable)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.edit_note,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.locale == 'pt'
                            ? 'Entrada manual de texto disponível'
                            : 'Manual text entry available',
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

        // Error message
        if (_error != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.error.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _error = null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

        // Image preview and text editor
        if (_imageBytes != null || _showTextEditor)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
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
                        _showTextEditor ? Icons.edit_note : Icons.image,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _showTextEditor
                              ? (widget.locale == 'pt' ? 'Texto do Documento' : 'Document Text')
                              : (widget.locale == 'pt' ? 'Imagem Capturada' : 'Captured Image'),
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      if (_showTextEditor && _hasExtractedText)
                        TextButton.icon(
                          onPressed: _processText,
                          icon: const Icon(Icons.check, size: 16),
                          label: Text(widget.locale == 'pt' ? 'Aplicar' : 'Apply'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: _clearData,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: widget.locale == 'pt' ? 'Fechar' : 'Close',
                      ),
                    ],
                  ),
                ),

                // Image thumbnail + text editor
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image thumbnail
                      if (_imageBytes != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _imageBytes!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      if (_imageBytes != null) const SizedBox(width: 12),
                      // Text editor or status
                      Expanded(
                        child: _showTextEditor
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.locale == 'pt'
                                        ? 'Edite o texto se necessário:'
                                        : 'Edit text if needed:',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _textController,
                                    maxLines: 4,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontFamily: 'monospace',
                                    ),
                                    decoration: InputDecoration(
                                      hintText: widget.locale == 'pt'
                                          ? 'Cole ou digite o texto aqui...'
                                          : 'Paste or type text here...',
                                      contentPadding: const EdgeInsets.all(12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      isDense: true,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.tonal(
                                      onPressed: _processText,
                                      child: Text(widget.locale == 'pt'
                                          ? 'Processar Texto'
                                          : 'Process Text'),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: Colors.green.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      widget.locale == 'pt'
                                          ? 'Imagem carregada. Clique para editar texto.'
                                          : 'Image loaded. Click to edit text.',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.green.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
