import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/transaction_model.dart';

class TransactionService {
  TransactionService._();
  static final instance = TransactionService._();

  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // Data tiap pengguna terisolasi di /users/{uid}/transactions
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(_uid).collection('transactions');

  /// Seluruh transaksi, terbaru lebih dulu (real-time).
  Stream<List<TransactionModel>> watchAll() => _col
      .orderBy('transactionDate', descending: true)
      .snapshots()
      .map((s) => s.docs.map(TransactionModel.fromDoc).toList());

  /// Snapshot mentah (dengan metadata) untuk status sinkronisasi.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchRaw() =>
      _col.snapshots(includeMetadataChanges: true);

  /// Satu transaksi + status apakah masih menunggu sinkronisasi.
  Stream<({TransactionModel tx, bool pending})?> watchOne(String id) =>
      _col.doc(id).snapshots(includeMetadataChanges: true).map((d) {
        if (!d.exists) return null;
        return (
          tx: TransactionModel.fromDoc(d),
          pending: d.metadata.hasPendingWrites
        );
      });

  Future<void> add({
    required String title,
    required int amount,
    required TxType type,
    required String category,
    String? notes,
    required DateTime date,
  }) {
    final ref = _col.doc();
    return _commit(ref.set({
      'id': ref.id,
      'userId': _uid,
      'title': title,
      'amount': amount,
      'type': type.value,
      'category': category,
      'notes': notes,
      'transactionDate': Timestamp.fromDate(date),
      'createdAt': Timestamp.now(),
    }));
  }

  Future<void> update(
    String id, {
    required String title,
    required int amount,
    required TxType type,
    required String category,
    String? notes,
    required DateTime date,
  }) =>
      _commit(_col.doc(id).update({
        'title': title,
        'amount': amount,
        'type': type.value,
        'category': category,
        'notes': notes,
        'transactionDate': Timestamp.fromDate(date),
      }));

  Future<void> delete(String id) => _commit(_col.doc(id).delete());

  /// Saat offline, Future Firestore baru selesai ketika server membalas.
  /// Data sudah tersimpan di cache lokal dan akan tersinkron otomatis,
  /// jadi UI tidak perlu menunggu lebih dari beberapa detik.
  Future<void> _commit(Future<void> write) async {
    try {
      await write.timeout(const Duration(seconds: 3));
    } on TimeoutException {
      // lanjut: antrean tulis offline
    }
  }
}
