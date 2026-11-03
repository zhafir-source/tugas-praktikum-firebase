import 'package:cloud_firestore/cloud_firestore.dart';

enum TxType { income, expense }

extension TxTypeX on TxType {
  String get value => this == TxType.income ? 'INCOME' : 'EXPENSE';
  String get label => this == TxType.income ? 'Pemasukan' : 'Pengeluaran';
}

class TransactionModel {
  final String id;
  final String userId;
  final String title;
  final int amount; // rupiah utuh, tanpa desimal
  final TxType type;
  final String category;
  final String? notes;
  final DateTime transactionDate;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.notes,
    required this.transactionDate,
    required this.createdAt,
  });

  bool get isIncome => type == TxType.income;

  factory TransactionModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return TransactionModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      title: d['title'] ?? '',
      amount: (d['amount'] as num?)?.toInt() ?? 0,
      type: d['type'] == 'INCOME' ? TxType.income : TxType.expense,
      category: d['category'] ?? 'Lainnya',
      notes: d['notes'] as String?,
      transactionDate:
          (d['transactionDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
