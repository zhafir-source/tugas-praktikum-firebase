import 'package:flutter/material.dart';

import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import '../widgets/state_views.dart';
import '../widgets/transaction_tile.dart';

enum _Filter { all, income, expense }

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late final Stream<List<TransactionModel>> _stream =
      TransactionService.instance.watchAll();
  _Filter _filter = _Filter.all;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text('Transaksi',
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Cari judul transaksi',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: SegmentedButton<_Filter>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: _Filter.all, label: Text('Semua')),
                ButtonSegment(value: _Filter.income, label: Text('Pemasukan')),
                ButtonSegment(
                    value: _Filter.expense, label: Text('Pengeluaran')),
              ],
              selected: {_filter},
              onSelectionChanged: (s) => setState(() => _filter = s.first),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.hasError) return ErrorState(error: snap.error);
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snap.data!.where((t) {
                  final okType = switch (_filter) {
                    _Filter.all => true,
                    _Filter.income => t.isIncome,
                    _Filter.expense => !t.isIncome,
                  };
                  final okQuery =
                      _query.isEmpty || t.title.toLowerCase().contains(_query);
                  return okType && okQuery;
                }).toList();

                if (items.isEmpty) {
                  return const EmptyState(
                      icon: Icons.search_off_rounded,
                      message: 'Tidak ada transaksi yang cocok.');
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: items.length,
                  itemBuilder: (_, i) => TransactionTile(tx: items[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
