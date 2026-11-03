import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _rupiah =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

String formatRupiah(int value) => _rupiah.format(value);

String formatSigned(int value, {required bool income}) =>
    '${income ? '+' : '-'}${_rupiah.format(value)}';

String formatDateTime(DateTime d) =>
    DateFormat("d MMM yyyy · HH:mm", 'id_ID').format(d);

String formatDate(DateTime d) => DateFormat('d MMM yyyy', 'id_ID').format(d);

String initials(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

int parseAmount(String text) =>
    int.tryParse(text.replaceAll(RegExp(r'\D'), '')) ?? 0;

Color incomeColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF34D399)
        : const Color(0xFF16A34A);

Color expenseColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF87171)
        : const Color(0xFFDC2626);

const expenseCategories = [
  'Makanan',
  'Transport',
  'Belanja',
  'Tagihan',
  'Hiburan',
  'Lainnya',
];
const incomeCategories = ['Gaji', 'Freelance', 'Bonus', 'Lainnya'];

IconData categoryIcon(String category) {
  switch (category) {
    case 'Makanan':
      return Icons.restaurant_rounded;
    case 'Transport':
    case 'Transportasi':
      return Icons.directions_car_rounded;
    case 'Belanja':
      return Icons.shopping_bag_rounded;
    case 'Tagihan':
      return Icons.receipt_long_rounded;
    case 'Hiburan':
      return Icons.movie_rounded;
    case 'Gaji':
      return Icons.payments_rounded;
    case 'Freelance':
      return Icons.laptop_mac_rounded;
    case 'Bonus':
      return Icons.card_giftcard_rounded;
    default:
      return Icons.category_rounded;
  }
}

/// Memformat input angka dengan pemisah ribuan (1.250.000).
class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final text = NumberFormat.decimalPattern('id_ID').format(int.parse(digits));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
