import 'package:flutter/material.dart';

import '../core/utils.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/state_views.dart';
import 'transaction_form_screen.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;
  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late final _stream =
      TransactionService.instance.watchOne(widget.transactionId);

  Future<void> _delete(TransactionModel tx) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Hapus transaksi?',
      message: '"${tx.title}" akan dihapus permanen dan tidak bisa dikembalikan.',
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (!ok || !mounted) return;
    await TransactionService.instance.delete(tx.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Transaksi')),
      body: StreamBuilder<({TransactionModel tx, bool pending})?>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) return ErrorState(error: snap.error);
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data;
          if (data == null) {
            return const EmptyState(
                icon: Icons.inbox_outlined,
                message: 'Transaksi tidak ditemukan.');
          }
          final tx = data.tx;
          final color =
              tx.isIncome ? incomeColor(context) : expenseColor(context);

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Chip(
                        label: Text(tx.type.label),
                        side: BorderSide.none,
                        backgroundColor: color.withValues(alpha: 0.18),
                        labelStyle: TextStyle(
                            color: color, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        child: Text(
                          formatSigned(tx.amount, income: tx.isIncome),
                          style: tt.displaySmall?.copyWith(
                              color: color, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(tx.title,
                          textAlign: TextAlign.center,
                          style: tt.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('Tercatat pada ${formatDateTime(tx.transactionDate)}',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      _Row(
                          icon: categoryIcon(tx.category),
                          label: 'Kategori',
                          value: tx.category),
                      const Divider(height: 1),
                      _Row(
                          icon: Icons.cloud_done_outlined,
                          label: 'Status Sinkronisasi',
                          value: data.pending
                              ? 'Menunggu sinkronisasi'
                              : 'Tersimpan di Cloud'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Catatan Tambahan',
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  (tx.notes == null || tx.notes!.isEmpty)
                      ? 'Tidak ada catatan.'
                      : tx.notes!,
                  style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => TransactionFormScreen(existing: tx))),
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Edit Data'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _delete(tx),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: cs.error,
                      side: BorderSide(color: cs.error)),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Hapus'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: cs.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label, style: TextStyle(color: cs.onSurfaceVariant))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
