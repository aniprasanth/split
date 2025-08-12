import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitzy/models/group_model.dart';
import 'package:splitzy/models/expense_model.dart';
import 'package:splitzy/services/database_service.dart';
import 'package:splitzy/services/auth_service.dart';
import 'package:splitzy/services/contacts_service.dart';
import 'package:splitzy/utils/validators.dart';
import 'package:splitzy/utils/split_utils.dart';
import 'package:splitzy/utils/async_operation_mixin.dart';
import 'dart:async';

// Assuming SplitType enum exists
enum SplitType { equal, custom }

// Assuming SplitCalculationService exists
class SplitCalculationService {
  static Future<Map<String, double>> calculateSplitAsync({
    required double amount,
    required List<String> members,
    required SplitType splitType,
    Map<String, double>? customRatios,
  }) async {
    if (splitType == SplitType.equal) {
      return SplitUtils.computeEqualSplit(amount, members);
    } else {
      return SplitUtils.adjustCustomSplits(amount, customRatios ?? {});
    }
  }
}

mixin AsyncOperationMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> performAsyncOperation({
    required Future<void> Function() operation,
    Duration timeout = const Duration(seconds: 30),
    void Function()? onSuccess,
    void Function(dynamic)? onError,
  }) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await operation().timeout(timeout);
      if (!mounted) return;
      onSuccess?.call();
    } catch (e) {
      if (!mounted) return;
      onError?.call(e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class AddExpenseScreen extends StatefulWidget {
  final GroupModel? group;

  const AddExpenseScreen({
    super.key,
    this.group,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> with AsyncOperationMixin {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  late SplitType _selectedSplitType = SplitType.equal;
  final Map<String, double> _customRatios = {};

  GroupModel? _selectedGroup;
  String _selectedPayer = '';
  List<String> _selectedMembers = [];
  List<String> _availableMembers = [];
  Map<String, String> _memberNames = {};
  bool _isRequestingPermission = false;
  List<GroupModel> _userGroups = [];

  @override
  void initState() {
    super.initState();
    _selectedGroup = widget.group;
    _loadUserGroups();

    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser != null) {
      _selectedPayer = currentUser.uid;
      if (_selectedGroup == null) {
        _availableMembers = [currentUser.uid];
        _memberNames = {currentUser.uid: currentUser.displayName.isNotEmpty ? currentUser.displayName : 'You'};
        _selectedMembers = [currentUser.uid];
      }
    }

    if (_selectedGroup != null) {
      _initializeGroupData();
    }
  }

  void _initializeGroupData() {
    if (_selectedGroup == null) return;

    _availableMembers = [..._selectedGroup!.members];
    _memberNames = Map.from(_selectedGroup!.memberNames);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    if (currentUser != null && _availableMembers.contains(currentUser.uid)) {
      _selectedPayer = currentUser.uid;
    } else {
      _selectedPayer = _availableMembers.first;
    }
    _selectedMembers = [..._availableMembers];
  }

  void _loadUserGroups() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser == null) return;

    final dbService = Provider.of<DatabaseService>(context, listen: false);
    dbService.getUserGroups(currentUser.uid).listen((groups) {
      if (mounted) {
        setState(() {
          _userGroups = groups;
          if (widget.group != null && _selectedGroup == null) {
            _selectedGroup = widget.group;
            _initializeGroupData();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        actions: [
          TextButton(
            onPressed: isLoading
                ? null
                : () {
                    FocusScope.of(context).unfocus();
                    _saveExpense();
                  },
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('SAVE'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Group',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (widget.group != null && _selectedGroup != null)
                      TextFormField(
                        enabled: false,
                        initialValue: _selectedGroup!.name,
                        decoration: const InputDecoration(
                          labelText: 'Group',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.group),
                        ),
                      )
                    else
                      DropdownButtonFormField<GroupModel?>(
                        value: _selectedGroup,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Choose a group',
                        ),
                        items: [
                          const DropdownMenuItem<GroupModel?>(
                            value: null,
                            child: Text('None'),
                          ),
                          ..._userGroups.map((group) {
                            return DropdownMenuItem(
                              value: group,
                              child: Text(group.name),
                            );
                          })
                        ],
                        onChanged: isLoading
                            ? null
                            : (group) {
                                setState(() {
                                  _selectedGroup = group;
                                  if (group != null) {
                                    _initializeGroupData();
                                  } else {
                                    final authService = Provider.of<AuthService>(context, listen: false);
                                    final currentUser = authService.currentUser;
                                    if (currentUser != null) {
                                      if (_availableMembers.isEmpty) {
                                        _availableMembers = [currentUser.uid];
                                        _memberNames = {
                                          currentUser.uid:
                                              currentUser.displayName.isNotEmpty ? currentUser.displayName : 'You'
                                        };
                                        _selectedPayer = currentUser.uid;
                                        _selectedMembers = [currentUser.uid];
                                      }
                                    }
                                  }
                                });
                              },
                        validator: (value) => null,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              enabled: !isLoading,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'What was this expense for?',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              validator: Validators.validateExpenseDescription,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 100,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              enabled: !isLoading,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                hintText: '0.00',
                prefixIcon: Icon(Icons.currency_rupee),
                border: OutlineInputBorder(),
                helperText: 'Enter amount in ₹',
              ),
              validator: (value) => Validators.validateAmount(
                value,
                minAmount: 0.01,
                maxAmount: 999999.99,
                fieldName: 'Amount',
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paid by',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ..._availableMembers.map((member) => RadioListTile<String>(
                          title: Text(_memberNames[member] ?? member),
                          value: member,
                          groupValue: _selectedPayer,
                          onChanged: isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedPayer = value!;
                                  });
                                },
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Split between',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (_selectedGroup == null)
                          TextButton.icon(
                            onPressed: (isLoading || _isRequestingPermission)
                                ? null
                                : _showAddPersonDialog,
                            icon: (isLoading || _isRequestingPermission)
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.person_add),
                            label: Text(_isRequestingPermission ? 'Loading...' : 'Add Person'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._availableMembers.map((member) => CheckboxListTile(
                          title: Text(_memberNames[member] ?? member),
                          value: _selectedMembers.contains(member),
                          onChanged: isLoading
                              ? null
                              : (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selectedMembers.add(member);
                                    } else {
                                      _selectedMembers.remove(member);
                                    }
                                  });
                                },
                        )),
                    if (_selectedMembers.isNotEmpty) ...[
                      const Divider(),
                      Builder(builder: (_) {
                        final amount = double.tryParse(_amountController.text) ?? 0.0;
                        final splitMap = SplitUtils.computeEqualSplit(amount, _selectedMembers);
                        final perPerson = _selectedMembers.isEmpty ? 0.0 : (splitMap[_selectedMembers.first] ?? 0.0);
                        return Text(
                          'Split: ₹${perPerson.toStringAsFixed(2)} per person',
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: isLoading ? null : _saveExpense,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Adding...'),
                      ],
                    )
                  : const Text(
                      'Add Expense',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPersonDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Person'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_add),
                  ),
                  autofocus: true,
                  onSubmitted: (name) {
                    if (name.trim().isNotEmpty) {
                      _addPersonToExpense(name.trim());
                      Navigator.of(context).pop();
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Consumer<ContactsService>(
                  builder: (context, contactsService, child) {
                    if (contactsService.hasPermission) {
                      if (contactsService.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (contactsService.contacts.isEmpty) {
                        return const Center(child: Text('No contacts found'));
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Or select from contacts:'),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              itemCount: contactsService.contacts.length,
                              itemBuilder: (context, index) {
                                final contact = contactsService.contacts[index];
                                return ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.person),
                                  ),
                                  title: Text(contact.displayName),
                                  onTap: () {
                                    _addPersonToExpense(contact.displayName);
                                    Navigator.of(context).pop();
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          const Text('To select from contacts, grant permission:'),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () async {
                              setState(() => _isRequestingPermission = true);
                              setDialogState(() {});

                              final granted = await contactsService.requestPermission();

                              if (mounted) {
                                setState(() => _isRequestingPermission = false);

                                if (granted) {
                                  setDialogState(() {});
                                } else {
                                  showErrorSnackBar('Permission denied. You can still add people manually.');
                                }
                              }
                            },
                            icon: const Icon(Icons.contacts),
                            label: const Text('Grant contacts permission'),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    _addPersonToExpense(name);
                    Navigator.of(context).pop();
                  } else {
                    showErrorSnackBar('Please enter a name');
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _addPersonToExpense(String name) {
    if (!mounted || name.trim().isEmpty) return;

    if (_availableMembers.contains(name)) {
      showErrorSnackBar('Person "$name" is already added');
      return;
    }

    setState(() {
      _availableMembers.add(name);
      _memberNames[name] = name;
      if (!_selectedMembers.contains(name)) {
        _selectedMembers.add(name);
      }
    });

    showSuccessSnackBar('Person "$name" added successfully!');
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await performAsyncOperation(
      operation: () async {
        if (_selectedGroup == null && _availableMembers.length <= 1) {
          throw Exception('Please select a group or add people to split with');
        }

        if (_selectedMembers.isEmpty) {
          throw Exception('Please select at least one person');
        }

        if (_selectedGroup == null && _selectedMembers.length < 2) {
          throw Exception('Please add at least one more person');
        }

        final description = _descriptionController.text.trim();
        final amount = double.tryParse(_amountController.text.trim());

        if (amount == null || amount <= 0) {
          throw Exception('Please enter a valid amount');
        }

        final authService = Provider.of<AuthService>(context, listen: false);
        final currentUser = authService.currentUser;

        if (currentUser == null) {
          throw Exception('Please sign in to add an expense');
        }

        final splits = await SplitCalculationService.calculateSplitAsync(
          amount: amount,
          members: _selectedMembers,
          splitType: _selectedSplitType,
          customRatios: _customRatios.isNotEmpty ? _customRatios : null,
        );

        final expense = ExpenseModel.create(
          groupId: _selectedGroup?.id ?? '',
          payer: _selectedPayer,
          payerName: _memberNames[_selectedPayer] ?? _selectedPayer,
          amount: amount,
          description: description,
          splitType: _selectedSplitType,
          customRatios: _customRatios.isNotEmpty ? _customRatios : null,
          split: splits,
          date: DateTime.now(),
        );

        final dbService = Provider.of<DatabaseService>(context, listen: false);
        final success = await dbService.addExpense(expense);

        if (!success) {
          throw Exception(dbService.errorMessage ?? 'Failed to save expense');
        }
      },
      timeout: const Duration(seconds: 30),
      onSuccess: () {
        showSuccessSnackBar('Expense "${_descriptionController.text.trim()}" added successfully!');
        navigator.pop(true);
      },
      onError: (error) {
        showErrorSnackBar(error.toString());
      },
    );
  }
}