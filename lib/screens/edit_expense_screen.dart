import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitzy/models/expense_model.dart';
import 'package:splitzy/models/group_model.dart';
import 'package:splitzy/services/auth_service.dart';
import 'package:splitzy/services/database_service.dart';
import 'package:splitzy/services/local_storage_service.dart';
import 'package:splitzy/utils/split_utils.dart';
import 'package:splitzy/utils/validators.dart';

class EditExpenseScreen extends StatefulWidget {
  final ExpenseModel expense;
  final GroupModel? group; // optional, for displaying group info and names

  const EditExpenseScreen({super.key, required this.expense, this.group});

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late DateTime _date;

  late String _selectedPayer;
  late List<String> _selectedMembers;
  late Map<String, String> _memberNames;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.expense.description);
    _amountController = TextEditingController(text: widget.expense.amount.toStringAsFixed(2));
    _date = widget.expense.date;

    _selectedPayer = widget.expense.payer;
    _selectedMembers = widget.expense.split.keys.toList();

    // Prefer names from group if provided, otherwise fallback to existing payerName / ids
    _memberNames = {};
    if (widget.group != null) {
      _memberNames.addAll(widget.group!.memberNames);
    }
    // Ensure payerName is set
    _memberNames[_selectedPayer] = widget.expense.payerName;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGroup = widget.expense.groupId.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Expense'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('SAVE'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Group (read-only)
            if (isGroup)
              TextFormField(
                enabled: false,
                initialValue: widget.group?.name ?? 'Group',
                decoration: const InputDecoration(
                  labelText: 'Group',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group),
                ),
              ),
            if (isGroup) const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              validator: Validators.validateExpenseDescription,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 100,
            ),
            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                hintText: '0.00',
                prefixIcon: Icon(Icons.currency_rupee),
                border: OutlineInputBorder(),
              ),
              validator: (value) => Validators.validateAmount(
                value,
                minAmount: 0.01,
                maxAmount: 999999.99,
                fieldName: 'Amount',
              ),
            ),
            const SizedBox(height: 16),

            // Date picker
            InkWell(
              onTap: _isSaving ? null : _pickDate,
              child: IgnorePointer(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  controller: TextEditingController(text: _date.toLocal().toString().split(' ').first),
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (isGroup) ...[
              // Paid by
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Paid by', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...widget.group!.members.map((member) => RadioListTile<String>(
                            title: Text(_memberNames[member] ?? member),
                            value: member,
                            groupValue: _selectedPayer,
                            onChanged: _isSaving ? null : (value) {
                              setState(() => _selectedPayer = value!);
                            },
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Split between (equal split for now)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Split between', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...widget.group!.members.map((member) => CheckboxListTile(
                            title: Text(_memberNames[member] ?? member),
                            value: _selectedMembers.contains(member),
                            onChanged: _isSaving
                                ? null
                                : (checked) {
                                    setState(() {
                                      if (checked == true) {
                                        if (!_selectedMembers.contains(member)) _selectedMembers.add(member);
                                      } else {
                                        _selectedMembers.remove(member);
                                      }
                                    });
                                  },
                          )),
                      const Divider(),
                      Builder(builder: (_) {
                        final amount = double.tryParse(_amountController.text) ?? 0.0;
                        final splitMap = SplitUtils.computeEqualSplit(amount, _selectedMembers);
                        final perPerson = _selectedMembers.isEmpty
                            ? 0.0
                            : (splitMap[_selectedMembers.first] ?? 0.0);
                        return Text(
                          'Split: ₹${perPerson.toStringAsFixed(2)} per person',
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final initial = _date;
    final first = DateTime(initial.year - 2);
    final last = DateTime(initial.year + 2);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    // Validate members
    if (widget.expense.groupId.isNotEmpty && _selectedMembers.isEmpty) {
      _showError('Please select at least one person to split the expense with');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', ''));
      final description = _descriptionController.text.trim();

      Map<String, double> splitMap;
      if (widget.expense.groupId.isNotEmpty) {
        splitMap = SplitUtils.computeEqualSplit(amount, _selectedMembers);
      } else {
        splitMap = SplitUtils.adjustCustomSplits(
          amount,
          {for (final m in _selectedMembers) m: amount / (_selectedMembers.isEmpty ? 1 : _selectedMembers.length)},
        );
      }

      final updated = widget.expense.copyWith(
        amount: amount,
        description: description,
        date: _date,
        payer: _selectedPayer,
        payerName: _memberNames[_selectedPayer] ?? widget.expense.payerName,
        split: splitMap,
      );

      final db = Provider.of<DatabaseService>(context, listen: false);
      final ok = await db.updateExpense(updated);

      // Update local cache for offline
      if (widget.expense.groupId.isNotEmpty) {
        await LocalStorageService.upsertCachedExpense(widget.expense.groupId, updated);
      }

      if (!mounted) return;
      if (ok) {
        Navigator.pop(context, true);
      } else {
        _showError(db.errorMessage ?? 'Failed to update expense');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to update expense');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
    );
  }
}
