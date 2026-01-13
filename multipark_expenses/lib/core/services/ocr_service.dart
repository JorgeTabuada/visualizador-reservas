import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../constants/app_constants.dart';

/// Resultado do processamento OCR de uma fatura
class OcrResult {
  final String rawText;
  final double confidence;
  final String? vendor;
  final String? vendorTaxId;
  final String? invoiceNumber;
  final DateTime? invoiceDate;
  final DateTime? dueDate;
  final double? subtotal;
  final double? taxAmount;
  final double? totalAmount;
  final String? currency;
  final List<OcrLineItem> items;
  final String? paymentMethod;

  OcrResult({
    required this.rawText,
    required this.confidence,
    this.vendor,
    this.vendorTaxId,
    this.invoiceNumber,
    this.invoiceDate,
    this.dueDate,
    this.subtotal,
    this.taxAmount,
    this.totalAmount,
    this.currency,
    this.items = const [],
    this.paymentMethod,
  });

  bool get isValid => confidence >= AppConstants.ocrMinConfidence;

  Map<String, dynamic> toJson() => {
        'rawText': rawText,
        'confidence': confidence,
        'vendor': vendor,
        'vendorTaxId': vendorTaxId,
        'invoiceNumber': invoiceNumber,
        'invoiceDate': invoiceDate?.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'subtotal': subtotal,
        'taxAmount': taxAmount,
        'totalAmount': totalAmount,
        'currency': currency,
        'items': items.map((e) => e.toJson()).toList(),
        'paymentMethod': paymentMethod,
      };
}

/// Item de linha extraído da fatura
class OcrLineItem {
  final String description;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final int? taxRate;

  OcrLineItem({
    required this.description,
    this.quantity = 1,
    required this.unitPrice,
    required this.totalPrice,
    this.taxRate,
  });

  Map<String, dynamic> toJson() => {
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'totalPrice': totalPrice,
        'taxRate': taxRate,
      };
}

/// Serviço de OCR para processamento de faturas
class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Processa uma imagem e extrai os dados da fatura
  Future<OcrResult> processReceipt(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final rawText = recognizedText.text;
      final confidence = _calculateConfidence(recognizedText);

      // Extrair dados estruturados do texto
      final extractedData = _extractInvoiceData(rawText);

      return OcrResult(
        rawText: rawText,
        confidence: confidence,
        vendor: extractedData['vendor'],
        vendorTaxId: extractedData['vendorTaxId'],
        invoiceNumber: extractedData['invoiceNumber'],
        invoiceDate: extractedData['invoiceDate'],
        dueDate: extractedData['dueDate'],
        subtotal: extractedData['subtotal'],
        taxAmount: extractedData['taxAmount'],
        totalAmount: extractedData['totalAmount'],
        currency: extractedData['currency'] ?? AppConstants.defaultCurrency,
        items: extractedData['items'] ?? [],
        paymentMethod: extractedData['paymentMethod'],
      );
    } catch (e) {
      return OcrResult(
        rawText: '',
        confidence: 0.0,
      );
    }
  }

  /// Calcula a confiança média do reconhecimento
  double _calculateConfidence(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return 0.0;

    double totalConfidence = 0.0;
    int count = 0;

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        // ML Kit não fornece confidence diretamente, estimamos baseado na qualidade
        totalConfidence += _estimateLineConfidence(line);
        count++;
      }
    }

    return count > 0 ? totalConfidence / count : 0.0;
  }

  /// Estima a confiança de uma linha baseado em heurísticas
  double _estimateLineConfidence(TextLine line) {
    // Heurísticas básicas para estimar qualidade
    final text = line.text;

    // Linhas muito curtas ou muito longas têm menor confiança
    if (text.length < 3 || text.length > 100) return 0.6;

    // Texto com muitos caracteres especiais estranhos
    final specialChars = RegExp(r'[^\w\s\d€$.,;:/-]');
    final specialCount = specialChars.allMatches(text).length;
    if (specialCount > text.length * 0.3) return 0.5;

    return 0.85;
  }

  /// Extrai dados estruturados do texto da fatura
  Map<String, dynamic> _extractInvoiceData(String rawText) {
    final data = <String, dynamic>{};
    final lines = rawText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    // Extrair NIF/NIPC (formato português)
    data['vendorTaxId'] = _extractTaxId(rawText);

    // Extrair número da fatura
    data['invoiceNumber'] = _extractInvoiceNumber(rawText);

    // Extrair datas
    data['invoiceDate'] = _extractDate(rawText, ['data', 'date', 'emissão']);
    data['dueDate'] = _extractDate(rawText, ['vencimento', 'due', 'pagamento']);

    // Extrair valores monetários
    final amounts = _extractMonetaryValues(rawText);
    data['totalAmount'] = amounts['total'];
    data['subtotal'] = amounts['subtotal'];
    data['taxAmount'] = amounts['tax'];

    // Extrair vendor (primeira linha não-numérica geralmente)
    data['vendor'] = _extractVendor(lines);

    // Extrair método de pagamento
    data['paymentMethod'] = _extractPaymentMethod(rawText);

    // Extrair itens
    data['items'] = _extractLineItems(lines);

    return data;
  }

  /// Extrai NIF/NIPC português
  String? _extractTaxId(String text) {
    // Padrão NIF português: 9 dígitos, pode ter "PT" prefixo
    final patterns = [
      RegExp(r'(?:PT|NIF|NIPC)[:\s]*(\d{9})', caseSensitive: false),
      RegExp(r'(?:contribuinte|fiscal)[:\s]*(\d{9})', caseSensitive: false),
      RegExp(r'\b(\d{9})\b'), // Fallback: qualquer sequência de 9 dígitos
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final nif = match.group(1);
        if (nif != null && _isValidPortugueseNif(nif)) {
          return 'PT$nif';
        }
      }
    }
    return null;
  }

  /// Valida NIF português
  bool _isValidPortugueseNif(String nif) {
    if (nif.length != 9) return false;
    if (!RegExp(r'^\d{9}$').hasMatch(nif)) return false;

    // Validação do dígito de controlo
    final firstDigit = int.parse(nif[0]);
    if (![1, 2, 3, 5, 6, 7, 8, 9].contains(firstDigit)) return false;

    int sum = 0;
    for (int i = 0; i < 8; i++) {
      sum += int.parse(nif[i]) * (9 - i);
    }

    final checkDigit = 11 - (sum % 11);
    final expectedCheckDigit = checkDigit >= 10 ? 0 : checkDigit;

    return int.parse(nif[8]) == expectedCheckDigit;
  }

  /// Extrai número da fatura
  String? _extractInvoiceNumber(String text) {
    final patterns = [
      RegExp(r'(?:fatura|factura|invoice|recibo|receipt)[:\s#]*([A-Z0-9/-]+)', caseSensitive: false),
      RegExp(r'(?:FT|FR|FS|NC|ND)[:\s]*(\d{4}[/-]\d+)', caseSensitive: false),
      RegExp(r'(?:doc|documento)[:\s#]*([A-Z0-9/-]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }
    return null;
  }

  /// Extrai data do texto
  DateTime? _extractDate(String text, List<String> keywords) {
    // Padrões de data comuns em Portugal
    final datePatterns = [
      RegExp(r'(\d{2})[/-](\d{2})[/-](\d{4})'), // DD/MM/YYYY
      RegExp(r'(\d{4})[/-](\d{2})[/-](\d{2})'), // YYYY-MM-DD
      RegExp(r'(\d{2})[/-](\d{2})[/-](\d{2})'), // DD/MM/YY
    ];

    final lowerText = text.toLowerCase();

    for (final keyword in keywords) {
      final keywordIndex = lowerText.indexOf(keyword);
      if (keywordIndex != -1) {
        // Procurar data perto da keyword
        final searchArea = text.substring(
          keywordIndex,
          (keywordIndex + 50).clamp(0, text.length),
        );

        for (final pattern in datePatterns) {
          final match = pattern.firstMatch(searchArea);
          if (match != null) {
            return _parseDate(match);
          }
        }
      }
    }

    // Fallback: procurar qualquer data no texto
    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return _parseDate(match);
      }
    }

    return null;
  }

  DateTime? _parseDate(RegExpMatch match) {
    try {
      final groups = match.groups([1, 2, 3]).whereType<String>().toList();
      if (groups.length != 3) return null;

      int day, month, year;

      if (groups[0].length == 4) {
        // YYYY-MM-DD
        year = int.parse(groups[0]);
        month = int.parse(groups[1]);
        day = int.parse(groups[2]);
      } else {
        // DD/MM/YYYY ou DD/MM/YY
        day = int.parse(groups[0]);
        month = int.parse(groups[1]);
        year = int.parse(groups[2]);

        if (year < 100) {
          year += year > 50 ? 1900 : 2000;
        }
      }

      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  /// Extrai valores monetários
  Map<String, double?> _extractMonetaryValues(String text) {
    final values = <String, double?>{
      'total': null,
      'subtotal': null,
      'tax': null,
    };

    // Padrões para valores monetários
    final amountPattern = RegExp(r'(\d+[.,]?\d*)\s*(?:€|EUR)?', caseSensitive: false);

    // Procurar total
    final totalPatterns = [
      RegExp(r'total[:\s]*(\d+[.,]\d{2})', caseSensitive: false),
      RegExp(r'valor\s*total[:\s]*(\d+[.,]\d{2})', caseSensitive: false),
      RegExp(r'a\s*pagar[:\s]*(\d+[.,]\d{2})', caseSensitive: false),
    ];

    for (final pattern in totalPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        values['total'] = _parseAmount(match.group(1));
        break;
      }
    }

    // Procurar IVA
    final taxPatterns = [
      RegExp(r'(?:IVA|VAT)[:\s]*(\d+[.,]\d{2})', caseSensitive: false),
      RegExp(r'taxa[:\s]*(\d+[.,]\d{2})', caseSensitive: false),
    ];

    for (final pattern in taxPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        values['tax'] = _parseAmount(match.group(1));
        break;
      }
    }

    // Procurar subtotal
    final subtotalPatterns = [
      RegExp(r'subtotal[:\s]*(\d+[.,]\d{2})', caseSensitive: false),
      RegExp(r'base\s*(?:tributável)?[:\s]*(\d+[.,]\d{2})', caseSensitive: false),
    ];

    for (final pattern in subtotalPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        values['subtotal'] = _parseAmount(match.group(1));
        break;
      }
    }

    // Se temos total e IVA mas não subtotal, calcular
    if (values['total'] != null && values['tax'] != null && values['subtotal'] == null) {
      values['subtotal'] = values['total']! - values['tax']!;
    }

    return values;
  }

  double? _parseAmount(String? value) {
    if (value == null) return null;
    try {
      // Normalizar formato: trocar vírgula por ponto
      final normalized = value.replaceAll(',', '.');
      return double.parse(normalized);
    } catch (_) {
      return null;
    }
  }

  /// Extrai nome do vendedor
  String? _extractVendor(List<String> lines) {
    // Geralmente o nome da empresa está nas primeiras linhas
    for (final line in lines.take(5)) {
      // Ignorar linhas que parecem ser datas, valores ou números
      if (RegExp(r'^\d+[.,/-]').hasMatch(line)) continue;
      if (RegExp(r'^\d+[.,]\d{2}$').hasMatch(line)) continue;
      if (line.length < 3) continue;

      // Retornar primeira linha que parece ser um nome
      if (RegExp(r'^[A-Za-zÀ-ÿ\s,.-]+$').hasMatch(line) && line.length > 3) {
        return line;
      }
    }
    return lines.isNotEmpty ? lines.first : null;
  }

  /// Extrai método de pagamento
  String? _extractPaymentMethod(String text) {
    final lowerText = text.toLowerCase();

    if (lowerText.contains('multibanco') || lowerText.contains('mb')) {
      return AppConstants.paymentCompanyCard;
    }
    if (lowerText.contains('mbway') || lowerText.contains('mb way')) {
      return AppConstants.paymentMBWay;
    }
    if (lowerText.contains('numerário') || lowerText.contains('dinheiro') || lowerText.contains('cash')) {
      return AppConstants.paymentCash;
    }
    if (lowerText.contains('transferência') || lowerText.contains('transfer')) {
      return AppConstants.paymentTransfer;
    }
    if (lowerText.contains('cartão') || lowerText.contains('visa') || lowerText.contains('mastercard')) {
      return AppConstants.paymentCompanyCard;
    }

    return null;
  }

  /// Extrai itens de linha
  List<OcrLineItem> _extractLineItems(List<String> lines) {
    final items = <OcrLineItem>[];

    // Padrão comum: descrição seguida de quantidade x preço = total
    final itemPattern = RegExp(
      r'(.+?)\s+(\d+)\s*[xX]\s*(\d+[.,]\d{2})\s*=?\s*(\d+[.,]\d{2})?',
    );

    for (final line in lines) {
      final match = itemPattern.firstMatch(line);
      if (match != null) {
        final description = match.group(1)?.trim();
        final quantity = int.tryParse(match.group(2) ?? '1') ?? 1;
        final unitPrice = _parseAmount(match.group(3)) ?? 0.0;
        final totalPrice = _parseAmount(match.group(4)) ?? (quantity * unitPrice);

        if (description != null && description.isNotEmpty) {
          items.add(OcrLineItem(
            description: description,
            quantity: quantity,
            unitPrice: unitPrice,
            totalPrice: totalPrice,
          ));
        }
      }
    }

    return items;
  }

  /// Liberta recursos do OCR
  void dispose() {
    _textRecognizer.close();
  }
}
