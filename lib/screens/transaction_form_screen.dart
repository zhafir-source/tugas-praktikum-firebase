import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/utils.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

/// Dipakai untuk tambah (existing == null) maupun edit transaksi.
class TransactionFormScreen extends StatefulWidget {
  final TransactionModel? existing;
  const TransactionFormScreen({super.key, this.existing});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _title = TextEditingController();
  final _notes = TextEditingController();
  TxType _type = TxType.expense;
  String _category = expenseCategories.first;
  DateTime _date = DateTime.now();
  bool _saving = false;

  bool get _isEdit => widget.existing != null;
  List<String> get _categories {
    final base =
        _type == TxType.income ? incomeCategories : expenseCategories;
    return base.contains(_category) ? base : [...base, _category];
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _type = e.type;
      _category = e.category;
      _date = e.transactionDate;
      _title.text = e.title;
      _notes.text = e.notes ?? '';
      _amount.text = ThousandsFormatter()
          .formatEditUpdate(
              const TextEditingValue(), TextEditingValue(text: '${e.amount}'))
          .text;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_date));
    if (!mounted) return;
    setState(() => _date = DateTime(
        d.year, d.month, d.day, t?.hour ?? _date.hour, t?.minute ?? _date.minute));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
    try {
      final svc = TransactionService.instance;
      if (_isEdit) {
        await svc.update(widget.existing!.id,
            title: _title.text.trim(),
            amount: parseAmount(_amount.text),
            type: _type,
            category: _category,
            notes: notes,
            date: _date);
      } else {
        await svc.add(
            title: _title.text.trim(),
            amount: parseAmount(_amount.text),
            type: _type,
            category: _category,
            notes: notes,
            date: _date);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color =
        _type == TxType.income ? incomeColor(context) : expenseColor(context);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Transaksi' : 'Catat Transaksi')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SegmentedButton<TxType>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                      value: TxType.income,
                      label: Text('Pemasukan'),
                      icon: Icon(Icons.south_west_rounded)),
                  ButtonSegment(
                      value: TxType.expense,
                      label: Text('Pengeluaran'),
                      icon: Icon(Icons.north_east_rounded)),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() {
                  _type = s.first;
                  final list = _type == TxType.income
                      ? incomeCategories
                      : expenseCategories;
                  if (!list.contains(_category)) _category = list.first;
                }),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                  ThousandsFormatter(),
                ],
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800, color: color),
                decoration: const InputDecoration(
                  labelText: 'Nominal Transaksi',
                  prefixText: 'Rp ',
                ),
                validator: (v) => parseAmount(v ?? '') <= 0
                    ? 'Nominal harus lebih dari 0'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Judul Transaksi'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Judul wajib diisi'
                    : null,
              ),
              const SizedBox(height: 20),
              Text('Kategori',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories
                    .map((c) => ChoiceChip(
                          avatar: Icon(categoryIcon(c), size: 18),
                          label: Text(c),
                          selected: _category == c,
                          onSelected: (_) => setState(() => _category = c),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Transaksi',
                    suffixIcon: Icon(Icons.calendar_today_rounded),
                  ),
                  child: Text(formatDateTime(_date)),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                    labelText: 'Catatan (Opsional)', alignLabelWithHint: true),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: cs.onPrimary))
                          : const Text('Simpan Transaksi'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
