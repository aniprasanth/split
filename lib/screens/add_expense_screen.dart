import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // for kDebugMode
import 'package:provider/provider.dart';
import 'package:splitzy/models/group_model.dart';
import 'package:splitzy/models/expense_model.dart';
import 'package:splitzy/services/database_service.dart';
import 'package:splitzy/services/auth_service.dart';
import 'package:splitzy/services/contacts_service.dart';
import 'package:splitzy/utils/validators.dart';

class AddExpenseScreen extends StatefulWidget {
  final GroupModel? group;

  const AddExpenseScreen({
    super.key,
    this.group,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  GroupModel? _selectedGroup;
  String _selectedPayer = '';
  List<String> _selectedMembers = [];
  List<String> _availableMembers = [];
  Map<String, String> _memberNames = {};
  bool _isLoading = false;
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
      // For non-group expenses, initialize with current user
      if (_selectedGroup == null) {
        _availableMembers = [currentUser.uid];
        _memberNames = {currentUser.uid: currentUser.displayName};
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
          // Only set a default group if one was passed in via constructor
          // Otherwise, keep _selectedGroup as null (None)
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
            onPressed: _isLoading ? null : _saveExpense,
            child: _isLoading
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
            // Group Selection
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
                    DropdownButtonFormField<GroupModel?>(
                      value: _selectedGroup,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Choose a group',
                      ),
                      items: [
                        if (widget.group == null)
                          DropdownMenuItem<GroupModel?>(
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
                      onChanged: widget.group != null || _isLoading ? null : (group) {
                        setState(() {
                          _selectedGroup = group;
                          if (group != null) {
                            _initializeGroupData();
                          } else {
                            // For non-group expense, reset to current user only
                            final authService = Provider.of<AuthService>(context, listen: false);
                            final currentUser = authService.currentUser;
                            if (currentUser != null) {
                              _availableMembers = [currentUser.uid];
                              _memberNames = {currentUser.uid: currentUser.displayName};
                              _selectedPayer = currentUser.uid;
                              _selectedMembers = [currentUser.uid];
                            }
                          }
                        });
                      },
                      validator: (value) => null, // No validation needed for group
                      disabledHint: widget.group != null && _selectedGroup != null
                          ? Text(_selectedGroup!.name)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              enabled: !_isLoading,
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

            // Amount
            TextFormField(
              controller: _amountController,
              enabled: !_isLoading,
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

            if (_selectedGroup != null) ...[
              // Paid by
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
                        onChanged: _isLoading ? null : (value) {
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

              // Split between
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
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: _isLoading || (_selectedGroup == null && _selectedMembers.length >= 2) ? null : _showAddPersonDialog,
                                icon: const Icon(Icons.person_add),
                                label: const Text('Add Person'),
                              ),
                              TextButton(
                                onPressed: _isLoading ? null : () {
                                  setState(() {
                                    if (_selectedMembers.length == _availableMembers.length) {
                                      _selectedMembers.clear();
                                    } else {
                                      _selectedMembers = [..._availableMembers];
                                    }
                                  });
                                },
                                child: Text(
                                  _selectedMembers.length == _availableMembers.length
                                      ? 'None'
                                      : 'All',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._availableMembers.map((member) => CheckboxListTile(
                        title: Text(_memberNames[member] ?? member),
                        value: _selectedMembers.contains(member),
                        onChanged: _isLoading || (_selectedGroup == null && _selectedMembers.length >= 2 && !_selectedMembers.contains(member)) ? null : (checked) {
                          setState(() {
                            if (checked == true && (_selectedGroup != null || _selectedMembers.length < 2)) {
                              _selectedMembers.add(member);
                            } else {
                              _selectedMembers.remove(member);
                            }
                          });
                        },
                      )),
                      if (_selectedMembers.isNotEmpty) ...[
                        const Divider(),
                        Text(
                          'Split: ₹${_calculateSplitAmount().toStringAsFixed(2)} per person',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveExpense,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
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
    final contactsService = Provider.of<ContactsService>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Person'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Enter name',
                border: OutlineInputBorder(),
              ),
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
            if (contactsService.hasPermission) ...[
              const Text('Or select from contacts:'),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: Consumer<ContactsService>(
                  builder: (context, contactsService, child) {
                    if (contactsService.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (contactsService.contacts.isEmpty) {
                      return const Center(child: Text('No contacts found'));
                    }

                    return ListView.builder(
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
                    );
                  },
                ),
              ),
            ] else ...[
              TextButton.icon(
                onPressed: () async {
                  // Store context reference before async operation
                  final currentContext = context;
                  final granted = await contactsService.requestPermission();

                  // Check if widget is still mounted before using context
                  if (granted && mounted) {
                    if (currentContext.mounted) {
                      Navigator.of(currentContext).pop();
                    }
                    _showAddPersonDialog();
                  }
                },
                icon: const Icon(Icons.contacts),
                label: const Text('Grant contacts permission'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _addPersonToExpense(String name) {
    if (!_availableMembers.contains(name)) {
      setState(() {
        _availableMembers.add(name);
        _memberNames[name] = name;
        _selectedMembers.add(name);
      });
    }
  }

  double _calculateSplitAmount() {
    if (_selectedMembers.isEmpty || _amountController.text.trim().isEmpty) {
      return 0.0;
    }
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    return amount / _selectedMembers.length;
  }

  Future<void> _saveExpense() async {
    // Prevent multiple simultaneous calls
    if (_isLoading) return;
    
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // For non-group expenses, allow if no group is selected but members exist
    if (_selectedGroup == null && _availableMembers.isEmpty) {
      _showErrorSnackBar('Please select a group or add people to split with');
      return;
    }

    // Validate member selection
    if (_selectedMembers.isEmpty) {
      _showErrorSnackBar('Please select at least one person to split the expense with');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final description = _descriptionController.text.trim();
      final amountText = _amountController.text.trim();

      // Validate amount
      if (amountText.isEmpty) {
        throw Exception('Please enter an amount');
      }

      final amount = double.tryParse(amountText);
      if (amount == null) {
        throw Exception('Please enter a valid amount');
      }

      if (amount <= 0) {
        throw Exception('Amount must be greater than 0');
      }

      // Debug logging (only in debug mode)
      if (kDebugMode) {
        debugPrint('=== Adding Expense ===');
        debugPrint('Group: ${_selectedGroup?.name ?? 'Non-group expense'}');
        debugPrint('Description: $description');
        debugPrint('Amount: ₹$amount');
        debugPrint('Paid by: $_selectedPayer');
        debugPrint('Split between: $_selectedMembers');
        debugPrint('Split amount per person: ₹${(amount / _selectedMembers.length).toStringAsFixed(2)}');
      }

      // Get auth service to get current user info
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Calculate split amounts
      final splitAmount = amount / _selectedMembers.length;
      final splitMap = <String, double>{};
      for (final memberId in _selectedMembers) {
        splitMap[memberId] = splitAmount;
      }

      // Create expense model using the factory method
      final expense = ExpenseModel.create(
        groupId: _selectedGroup?.id ?? '', // Empty string for non-group expenses
        payer: _selectedPayer,
        payerName: _memberNames[_selectedPayer] ?? _selectedPayer,
        amount: amount,
        description: description,
        split: splitMap,
        date: DateTime.now(),
      );

      // Save to database using Provider
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final success = await databaseService.addExpense(expense);

      if (!success) {
        throw Exception(databaseService.errorMessage ?? 'Failed to save expense');
      }

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Expense "$description" added successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Return to previous screen
      Navigator.pop(context, true); // Return true to indicate success

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving expense: $e');
      }

      if (!mounted) return;

      _showErrorSnackBar('Failed to add expense. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

