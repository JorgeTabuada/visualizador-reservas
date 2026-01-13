import 'dart:io';
import 'package:dartz/dartz.dart';
import '../repositories/expenses_repository.dart';
import '../../../../core/utils/failures.dart';
import '../../../../core/services/ocr_service.dart';

/// Use case para digitalizar um recibo com OCR
class ScanReceiptUseCase {
  final ExpensesRepository repository;

  ScanReceiptUseCase(this.repository);

  Future<Either<Failure, OcrResult>> call(File image) async {
    return await repository.scanReceipt(image);
  }
}
