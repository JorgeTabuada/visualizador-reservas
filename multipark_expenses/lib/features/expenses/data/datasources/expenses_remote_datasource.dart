import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/expense_model.dart';
import '../../domain/entities/expense_entity.dart';
import '../../../../core/constants/app_constants.dart';

/// Interface do datasource remoto de despesas
abstract class ExpensesRemoteDataSource {
  Future<ExpenseModel> createExpense(ExpenseModel expense);
  Future<ExpenseModel> getExpenseById(String id);
  Future<List<ExpenseModel>> getExpenses({
    String? projectId,
    String? departmentId,
    String? userId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit,
    String? lastDocumentId,
  });
  Future<ExpenseModel> updateExpense(ExpenseModel expense);
  Future<void> deleteExpense(String id);
  Future<String> uploadReceiptImage({
    required File image,
    required String expenseId,
  });
  Stream<List<ExpenseModel>> watchExpenses({
    String? projectId,
    String? userId,
  });
}

/// Implementação do datasource de despesas com Firebase
class ExpensesRemoteDataSourceImpl implements ExpensesRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final _uuid = const Uuid();

  ExpensesRemoteDataSourceImpl({
    required this.firestore,
    required this.storage,
  });

  CollectionReference get _expensesCollection =>
      firestore.collection(AppConstants.expensesCollection);

  Reference get _receiptStorage =>
      storage.ref().child(AppConstants.receiptImagesPath);

  @override
  Future<ExpenseModel> createExpense(ExpenseModel expense) async {
    final docRef = _expensesCollection.doc();
    final newExpense = ExpenseModel(
      id: docRef.id,
      organizationId: expense.organizationId,
      projectId: expense.projectId,
      departmentId: expense.departmentId,
      categoryId: expense.categoryId,
      createdBy: expense.createdBy,
      assignedTo: expense.assignedTo,
      receiptData: expense.receiptData,
      extractedData: expense.extractedData,
      items: expense.items,
      paymentInfo: expense.paymentInfo,
      approval: expense.approval,
      tags: expense.tags,
      notes: expense.notes,
      metadata: expense.metadata,
      createdAt: DateTime.now(),
    );

    await docRef.set(newExpense.toJson());
    return newExpense;
  }

  @override
  Future<ExpenseModel> getExpenseById(String id) async {
    final doc = await _expensesCollection.doc(id).get();
    if (!doc.exists) {
      throw Exception('Despesa não encontrada');
    }
    return ExpenseModel.fromFirestore(doc);
  }

  @override
  Future<List<ExpenseModel>> getExpenses({
    String? projectId,
    String? departmentId,
    String? userId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    String? lastDocumentId,
  }) async {
    Query query = _expensesCollection
        .where('deletedAt', isNull: true)
        .orderBy('createdAt', descending: true);

    // Aplicar filtros
    if (projectId != null) {
      query = query.where('projectId', isEqualTo: projectId);
    }
    if (departmentId != null) {
      query = query.where('departmentId', isEqualTo: departmentId);
    }
    if (userId != null) {
      query = query.where('createdBy', isEqualTo: userId);
    }
    if (status != null) {
      query = query.where('approval.status', isEqualTo: status);
    }
    if (startDate != null) {
      query = query.where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('createdAt',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    // Paginação
    if (lastDocumentId != null) {
      final lastDoc = await _expensesCollection.doc(lastDocumentId).get();
      if (lastDoc.exists) {
        query = query.startAfterDocument(lastDoc);
      }
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => ExpenseModel.fromFirestore(doc)).toList();
  }

  @override
  Future<ExpenseModel> updateExpense(ExpenseModel expense) async {
    final updateData = expense.toJson();
    updateData['updatedAt'] = FieldValue.serverTimestamp();

    await _expensesCollection.doc(expense.id).update(updateData);

    final updatedDoc = await _expensesCollection.doc(expense.id).get();
    return ExpenseModel.fromFirestore(updatedDoc);
  }

  @override
  Future<void> deleteExpense(String id) async {
    // Soft delete - marca como eliminado em vez de remover
    await _expensesCollection.doc(id).update({
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<String> uploadReceiptImage({
    required File image,
    required String expenseId,
  }) async {
    final fileName = '${expenseId}_${_uuid.v4()}.jpg';
    final ref = _receiptStorage.child(fileName);

    // Upload com metadados
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {
        'expenseId': expenseId,
        'uploadedAt': DateTime.now().toIso8601String(),
      },
    );

    final uploadTask = await ref.putFile(image, metadata);
    return await uploadTask.ref.getDownloadURL();
  }

  @override
  Stream<List<ExpenseModel>> watchExpenses({
    String? projectId,
    String? userId,
  }) {
    Query query = _expensesCollection
        .where('deletedAt', isNull: true)
        .orderBy('createdAt', descending: true)
        .limit(50);

    if (projectId != null) {
      query = query.where('projectId', isEqualTo: projectId);
    }
    if (userId != null) {
      query = query.where('createdBy', isEqualTo: userId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ExpenseModel.fromFirestore(doc))
          .toList();
    });
  }
}
