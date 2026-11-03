import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/utils.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/transaction_service.dart';
import '../widgets/confirm_dialog.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Keluar dari akun?',
      message: 'Sesi Anda di perangkat ini akan diakhiri.',
      confirmLabel: 'Keluar',
      destructive: true,
    );
    if (ok) await AuthService.instance.signOut(); // AuthGate -> Login
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final user = AuthService.instance.currentUser!;

    return SafeArea(
      child: StreamBuilder<UserProfile?>(
        stream: AuthService.instance.watchProfile(user.uid),
        builder: (context, snap) {
          final p = snap.data;
          final name = (p?.displayName.isNotEmpty ?? false)
              ? p!.displayName
              : (user.displayName ?? 'Pengguna');
          final email = p?.email ?? user.email ?? '-';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Profil',
                  style:
                      tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: cs.primaryContainer,
                      child: Text(initials(name),
                          style: tt.headlineSmall?.copyWith(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 12),
                    Text(name,
                        style: tt.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    Text(email, style: TextStyle(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text('UID: ${user.uid.substring(0, 8)}…',
                        style: TextStyle(color: cs.outline, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: TransactionService.instance.watchRaw(),
                builder: (context, ts) {
                  final count = ts.data?.size ?? 0;
                  final meta = ts.data?.metadata;
                  final sync = meta == null
                      ? '...'
                      : meta.hasPendingWrites
                          ? 'Menunggu sinkronisasi'
                          : meta.isFromCache
                              ? 'Offline (cache)'
                              : 'Aktif';
                  return Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                            icon: Icons.receipt_long_outlined,
                            label: 'Total Entri',
                            value: '$count data'),
                        const Divider(height: 1),
                        _InfoRow(
                            icon: Icons.sync_rounded,
                            label: 'Sinkronisasi',
                            value: sync),
                        const Divider(height: 1),
                        _InfoRow(
                            icon: Icons.event_outlined,
                            label: 'Bergabung',
                            value: p == null ? '-' : formatDate(p.createdAt)),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: () => _logout(context),
                style: OutlinedButton.styleFrom(
                    foregroundColor: cs.error,
                    side: BorderSide(color: cs.error)),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Keluar dari Akun'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

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
