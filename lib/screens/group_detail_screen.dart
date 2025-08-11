import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitzy/models/group_model.dart';
import 'package:splitzy/screens/add_expense_screen.dart';
import 'package:splitzy/services/database_service.dart';
import 'package:splitzy/models/expense_model.dart';
import 'package:splitzy/models/settlement_model.dart';
import 'package:splitzy/screens/edit_expense_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final GroupModel group;

  const GroupDetailScreen({
    super.key,
    required this.group,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late GroupModel currentGroup;
  bool _isUpdatingGroup = false;
  bool _isDeletingGroup = false;
  bool _isManagingMembers = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    currentGroup = widget.group;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentGroup.name),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Expenses', icon: Icon(Icons.receipt)),
            Tab(text: 'Balances', icon: Icon(Icons.account_balance)),
            Tab(text: 'Friends', icon: Icon(Icons.people)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Edit Group'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'members',
                child: Row(
                  children: [
                    Icon(Icons.person_add),
                    SizedBox(width: 8),
                    Text('Manage Members'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Group', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (String value) {
              switch (value) {
                case 'edit':
                  _showEditGroupDialog();
                  break;
                case 'members':
                  _showManageMembersDialog();
                  break;
                case 'delete':
                  _showDeleteGroupDialog();
                  break;
              }
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExpensesTab(),
          _buildBalancesTab(),
          _buildFriendsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddExpenseScreen(group: currentGroup),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  Widget _buildExpensesTab() {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    return StreamBuilder<List<ExpenseModel>>(
      stream: dbService.getGroupExpenses(currentGroup.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final expenses = snapshot.data ?? [];
        if (expenses.isEmpty) {
          return _buildEmptyExpenses();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            return Dismissible(
              key: Key(expense.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.red,
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              confirmDismiss: (direction) => _showDeleteExpenseDialog(expense),
              onDismissed: (direction) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${expense.description} deleted'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        // TODO: Implement undo functionality
                      },
                    ),
                  ),
                );
              },
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    child: Icon(
                      Icons.receipt,
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                  title: Text(
                    expense.description,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Paid by ${expense.payerName} • ${expense.date.toLocal().toString().split(' ').first}')
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '₹${expense.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) async {
                          switch (value) {
                            case 'edit':
                              final updated = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditExpenseScreen(
                                    expense: expense,
                                    group: currentGroup,
                                  ),
                                ),
                              );
                              if (updated == true && mounted) {
                                final scaffoldMessenger = ScaffoldMessenger.of(context);
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(content: Text('Expense updated')),
                                );
                              }
                              break;
                            case 'delete':
                              await _showDeleteExpenseDialog(expense);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditExpenseScreen(
                          expense: expense,
                          group: currentGroup,
                        ),
                      ),
                    );
                    if (updated == true && mounted) {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('Expense updated')),
                      );
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyExpenses() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No expenses yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first expense to get started',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalancesTab() {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    return StreamBuilder<List<ExpenseModel>>(
      stream: dbService.getGroupExpenses(currentGroup.id),
      builder: (context, expenseSnapshot) {
        if (expenseSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final expenses = expenseSnapshot.data ?? [];
        // Start with balances from expenses
        final balances = dbService.calculateBalances(expenses);

        return StreamBuilder<List<SettlementModel>>(
          stream: dbService.getSettlements(currentGroup.id),
          builder: (context, settlementSnapshot) {
            if (settlementSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final settlements = settlementSnapshot.data ?? [];
            // Apply completed settlements to balances
            for (final s in settlements.where((s) => s.status == SettlementStatus.completed)) {
              balances[s.fromUser] = (balances[s.fromUser] ?? 0) + s.amount;
              balances[s.toUser] = (balances[s.toUser] ?? 0) - s.amount;
            }

            // Remove near-zero balances
            final entries = balances.entries
                .where((e) => e.value.abs() > 0.01)
                .toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            if (entries.isEmpty) {
              return _buildEmptyBalances();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final amount = entry.value;
                final owesYou = amount > 0; // positive means they owe you
                final name = currentGroup.memberNames[entry.key] ?? entry.key;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: owesYou ? Colors.green.shade100 : Colors.red.shade100,
                      child: Icon(
                        owesYou ? Icons.arrow_downward : Icons.arrow_upward,
                        color: owesYou ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      owesYou ? 'owes you' : 'you owe',
                      style: TextStyle(
                        color: owesYou ? Colors.green.shade600 : Colors.red.shade600,
                      ),
                    ),
                    trailing: Text(
                      '₹${amount.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: owesYou ? Colors.green.shade600 : Colors.red.shade600,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyBalances() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No balances yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add expenses to see balances',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: currentGroup.members.length,
      itemBuilder: (context, index) {
        final memberId = currentGroup.members[index];
        final memberName = currentGroup.memberNames[memberId] ?? memberId;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.person),
            title: Text(memberName),
          ),
        );
      },
    );
  }

  Future<void> _showEditGroupDialog() async {
    final nameController = TextEditingController(text: currentGroup.name);

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Group'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: _isUpdatingGroup ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isUpdatingGroup ? null : () async {
                  final newName = nameController.text.trim();
                  if (newName.isEmpty) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('Group name cannot be empty')),
                    );
                    return;
                  }

                  setDialogState(() => _isUpdatingGroup = true);
                  final dbService = Provider.of<DatabaseService>(context, listen: false);
                  final updatedGroup = currentGroup.copyWith(name: newName);

                  // Store context references before the async gap
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(dialogContext);

                  try {
                    final success = await dbService.updateGroup(updatedGroup);
                    if (!mounted) return;

                    if (success) {
                      setState(() {
                        currentGroup = updatedGroup;
                      });
                      navigator.pop();
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('Group updated successfully!')),
                      );
                    } else {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('Failed to update group')),
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Error updating group: $e')),
                    );
                  } finally {
                    if (mounted) setDialogState(() => _isUpdatingGroup = false);
                  }
                },
                child: _isUpdatingGroup
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showManageMembersDialog() async {
    final newMemberController = TextEditingController();
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Manage Members'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // List existing members
                  if (currentGroup.members.isNotEmpty)
                    ...currentGroup.members.map((member) => ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(member),
                      trailing: (member != 'You' && member != currentGroup.createdBy)
                          ? IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: _isManagingMembers ? null : () async {
                          setDialogState(() => _isManagingMembers = true);
                          final dbService = Provider.of<DatabaseService>(context, listen: false);
                          final success = await dbService.removeMemberFromGroup(currentGroup.id, member);
                          if (!mounted) return;
                          if (success) {
                            setDialogState(() {
                              List<String> newMembers = List.from(currentGroup.members);
                              newMembers.remove(member);
                              Map<String, String> newMemberNames = Map.from(currentGroup.memberNames);
                              newMemberNames.remove(member);

                              currentGroup = currentGroup.copyWith(
                                members: newMembers,
                                memberNames: newMemberNames,
                              );
                            });
                            setState(() {}); // Update the main screen
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to remove member')),
                            );
                          }
                          setDialogState(() => _isManagingMembers = false);
                        },
                      )
                          : null,
                    )),
                  const SizedBox(height: 16),
                  // Add new member
                  TextField(
                    controller: newMemberController,
                    decoration: InputDecoration(
                      labelText: 'Add new member',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _isManagingMembers ? null : () => _addNewMember(newMemberController, setDialogState),
                      ),
                    ),
                    onSubmitted: _isManagingMembers ? null : (_) => _addNewMember(newMemberController, setDialogState),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isManagingMembers ? null : () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  // FIXED: Added proper context handling for async operations
  void _addNewMember(TextEditingController controller, StateSetter setDialogState) async {
    final newMemberName = controller.text.trim();
    if (newMemberName.isEmpty) return;

    // For demo, use name as both ID and name. In real app, use contact picker or email/UID.
    final newMemberId = newMemberName;
    if (currentGroup.members.contains(newMemberId)) return;

    setDialogState(() => _isManagingMembers = true);
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    // Store context reference before async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final success = await dbService.addMemberToGroup(currentGroup.id, newMemberId, newMemberName);

    // Check if widget is still mounted after async operation
    if (!mounted) return;

    if (success) {
      setDialogState(() {
        List<String> newMembers = List.from(currentGroup.members);
        newMembers.add(newMemberId);
        Map<String, String> newMemberNames = Map.from(currentGroup.memberNames);
        newMemberNames[newMemberId] = newMemberName;
        currentGroup = currentGroup.copyWith(
          members: newMembers,
          memberNames: newMemberNames,
        );
      });
      setState(() {}); // Update the main screen
      controller.clear();
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Failed to add member')),
      );
    }
    setDialogState(() => _isManagingMembers = false);
  }

  Future<void> _showDeleteGroupDialog() async {
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Delete Group'),
            content: Text('Are you sure you want to delete "${currentGroup.name}"? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: _isDeletingGroup ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isDeletingGroup ? null : () async {
                  setDialogState(() => _isDeletingGroup = true);
                  final dbService = Provider.of<DatabaseService>(context, listen: false);

                  // Store context references before async operations
                  final navigator = Navigator.of(context);
                  final dialogNavigator = Navigator.of(dialogContext);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);

                  try {
                    final success = await dbService.deleteGroup(currentGroup.id);
                    if (!mounted) return;

                    dialogNavigator.pop(); // Close dialog
                    if (success) {
                      navigator.pop(); // Go back to previous screen
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('Group deleted successfully!')),
                      );
                    } else {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('Failed to delete group')),
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Error deleting group: $e')),
                    );
                  } finally {
                    if (mounted) setDialogState(() => _isDeletingGroup = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: _isDeletingGroup
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Delete'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<bool> _showDeleteExpenseDialog(ExpenseModel expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text(
          'Are you sure you want to delete "${expense.description}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return false;

    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final success = await dbService.deleteExpense(expense.id, currentGroup.id);
    
    if (!mounted) return false;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${expense.description} deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              // TODO: Implement undo functionality
            },
          ),
        ),
      );
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dbService.errorMessage ?? 'Failed to delete expense'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }
}
