import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitzy/models/group_model.dart';
import 'package:splitzy/models/expense_model.dart';
import 'package:splitzy/services/database_service.dart';
import 'package:splitzy/services/auth_service.dart';
import 'package:splitzy/services/contacts_service.dart';
import 'package:splitzy/utils/validators.dart';
import 'package:splitzy/utils/split_utils.dart';

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
      // For non-group expenses, initialize with current user
      if (_selectedGroup == null) {
        _availableMembers = [currentUser.uid];
        // Fixed: Remove null-aware operator since displayName can't be null
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
            onPressed: _isLoading
                ? null
                : () {
              FocusScope.of(context).unfocus();
              _saveExpense();
            },
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
                        onChanged: _isLoading
                            ? null
                            : (group) {
                          setState(() {
                            _selectedGroup = group;
                            if (group != null) {
                              _initializeGroupData();
                            } else {
                              // For non-group expense, initialize with current user
                              final authService = Provider.of<AuthService>(context, listen: false);
                              final currentUser = authService.currentUser;
                              if (currentUser != null) {
                                // Initialize with current user if no members exist
                                if (_availableMembers.isEmpty) {
                                  _availableMembers = [currentUser.uid];
                                  // Fixed: Remove null-aware operator
                                  _memberNames = {currentUser.uid: currentUser.displayName.isNotEmpty ? currentUser.displayName : 'You'};
                                  _selectedPayer = currentUser.uid;
                                  _selectedMembers = [currentUser.uid];
                                }
                                // Keep existing members if they were already added
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

            // Show payer and split UI for both group and non-group expenses
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
                        // Show Add Person button only for non-group expenses
                        if (_selectedGroup == null)
                          TextButton.icon(
                            onPressed: (_isLoading || _isRequestingPermission) ? null : _showAddPersonDialog,
                            icon: (_isLoading || _isRequestingPermission) 
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
                      onChanged: _isLoading ? null : (checked) {
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
                        final perPerson = _selectedMembers.isEmpty
                            ? 0.0
                            : (splitMap[_selectedMembers.first] ?? 0.0);
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
    final nameController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
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
                              setDialogState(() {}); // Trigger rebuild
                              
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              final granted = await contactsService.requestPermission();
                              
                              if (mounted) {
                                setState(() => _isRequestingPermission = false);
                                
                                if (granted) {
                                  setDialogState(() {}); // Trigger rebuild to show contacts
                                } else {
                                  scaffoldMessenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Permission denied. You can still add people manually.'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
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
    if (!_availableMembers.contains(name)) {
      setState(() {
        _availableMembers.add(name);
        _memberNames[name] = name;
        // Auto-select new member for splitting
        if (!_selectedMembers.contains(name)) {
          _selectedMembers.add(name);
        }
      });
    }
  }

  // Removed per-call split calculation in build that could cause heavy rebuild loops.

  Future<void> _saveExpense() async {
    // Prevent multiple simultaneous calls
    if (_isLoading) return;

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // For non-group expenses, allow if no group is selected but members exist
    if (_selectedGroup == null && _availableMembers.length <= 1) {
      _showErrorSnackBar('Please select a group or add people to split the expense with');
      return;
    }

    // Validate member selection
    if (_selectedMembers.isEmpty) {
      _showErrorSnackBar('Please select at least one person to split the expense with');
      return;
    }

    // For non-group expenses, ensure at least 2 people are involved
    if (_selectedGroup == null && _selectedMembers.length < 2) {
      _showErrorSnackBar('Please add at least one more person to split the expense');
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

      // Get auth service to get current user info
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Calculate split amounts with proper rounding
      Map<String, double> splitMap;
      if (_selectedGroup != null) {
        splitMap = SplitUtils.computeEqualSplit(amount, _selectedMembers);
      } else {
        // Non-group expense: split only among selected people (should typically be 2 people)
        splitMap = SplitUtils.adjustCustomSplits(
          amount,
          {
            for (final memberId in _selectedMembers) memberId: amount / _selectedMembers.length,
          },
        );
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

      // Save to database using Provider (async write)
      final databaseService = Provider.of<DatabaseService>(context, listen: false);

      // Store context-dependent objects before async operation
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      // Move DB write to async and keep UI responsive
      final success = await databaseService.addExpense(expense);

      if (!success) {
        throw Exception(databaseService.errorMessage ?? 'Failed to save expense');
      }

      if (!mounted) return;

      // Show success message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Expense "$description" added successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Return to previous screen
      navigator.pop(true); // Return true to indicate success

    } catch (e) {
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
