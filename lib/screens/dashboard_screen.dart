import 'package:flutter/material.dart';

import '../core/utils.dart';
import '../models/transaction_model.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/transaction_service.dart';
import '../widgets/state_views.dart';
import '../widgets/transaction_tile.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onSeeAll;
  final VoidCallback onAdd;
  const DashboardScreen(
      {super.key, required this.onSeeAll, required this.onAdd});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final Stream<List<TransactionModel>> _stream =
      TransactionService.instance.watchAll();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final user = AuthService.instance.currentUser!;

    return SafeArea(
      child: StreamBuilder<List<TransactionModel>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) return ErrorState(error: snap.error);
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data!;
          final income =
              list.where((t) => t.isIncome).fold<int>(0, (s, t) => s + t.amount);
          final expense = list
              .where((t) => !t.isIncome)
              .fold<int>(0, (s, t) => s + t.amount);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              // Header: sapaan + nama pengguna aktif
              StreamBuilder<UserProfile?>(
                stream: AuthService.instance.watchProfile(user.uid),
                builder: (context, ps) {
                  final name = (ps.data?.displayName.isNotEmpty ?? false)
                      ? ps.data!.displayName
                      : (user.displayName ?? user.email ?? 'Pengguna');
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: cs.primaryContainer,
                        child: Text(initials(name),
                            style: TextStyle(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Selamat datang,',
                                style: TextStyle(color: cs.onSurfaceVariant)),
                            Text(name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tt.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Kartu saldo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primary,
                      Color.lerp(cs.primary, Colors.black, 0.3)!,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Saldo Bersih',
                        style: TextStyle(
                            color: cs.onPrimary.withValues(alpha: 0.8))),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(formatRupiah(income - expense),
                          style: tt.headlineMedium?.copyWith(
                              color: cs.onPrimary, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _Metric(
                            icon: Icons.south_west_rounded,
                            label: 'Pemasukan',
                            value: income),
                        const SizedBox(width: 12),
                        _Metric(
                            icon: Icons.north_east_rounded,
                            label: 'Pengeluaran',
                            value: expense),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Statistik total transaksi
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bar_chart_rounded, color: cs.primary),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text('Total transaksi tercatat',
                            style: TextStyle(color: cs.onSurfaceVariant))),
                    Text('${list.length}',
                        style: tt.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: widget.onAdd,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Catat Transaksi'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onSeeAll,
                      icon: const Icon(Icons.history_rounded),
                      label: const Text('Semua Riwayat'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                      child: Text('Transaksi Terbaru',
                          style: tt.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800))),
                  TextButton(
                      onPressed: widget.onSeeAll,
                      child: const Text('Lihat Semua')),
                ],
              ),
              const SizedBox(height: 8),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: EmptyState(
                      icon: Icons.receipt_long_outlined,
                      message:
                          'Belum ada transaksi.\nKetuk "Tambah Transaksi" untuk mulai mencatat.'),
                )
              else
                ...list.take(5).map((t) => TransactionTile(tx: t)),
            ],
          );
        },
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  const _Metric(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.onPrimary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: cs.onPrimary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: cs.onPrimary.withValues(alpha: 0.8),
                          fontSize: 12)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(formatRupiah(value),
                        style: TextStyle(
                            color: cs.onPrimary, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
