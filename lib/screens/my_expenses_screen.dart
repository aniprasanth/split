import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitzy/services/database_service.dart';
import 'package:splitzy/services/auth_service.dart';
import 'package:splitzy/models/expense_model.dart';
import 'package:splitzy/models/settlement_model.dart';
import 'package:splitzy/screens/edit_expense_screen.dart';
import 'package:rxdart/rxdart.dart';

class MyExpensesScreen extends StatefulWidget {
  const MyExpensesScreen({super.key});

  @override
  State<MyExpensesScreen> createState() => _MyExpensesScreenState();
}

class _MyExpensesScreenState extends State<MyExpensesScreen> {
  DateTime? _selectedMonth;
  int? _selectedYear;

  @override
  void initState() {
    super.initState();
    // Default to current month and year
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _selectedYear = now.year;
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Expenses'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter expenses',
          ),
        ],
      ),
      body: currentUser == null
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text('User not authenticated'),
          ],
        ),
      )
          : StreamBuilder<Map<String, dynamic>>(
        stream: _getExpensesAndSettlementsData(currentUser.uid, dbService),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading data',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final allMyExpenses = data['expenses'] as List<ExpenseModel>;
          final settlements = data['settlements'] as List<SettlementModel>;

          // Filter for current user's expenses (where user is payer or involved in split)
          final myExpenses = allMyExpenses
              .where((e) =>
          e.payer == currentUser.uid ||
              e.split.keys.contains(currentUser.uid))
              .toList();

          // Apply date filtering
          final filteredExpenses = _applyDateFilter(myExpenses);

          // Calculate totals including settlements for real-time balance updates
          final totalExpenses = _calculateTotalExpensesWithSettlements(
              filteredExpenses, settlements, currentUser.uid);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter Info
                _buildFilterInfo(),
                const SizedBox(height: 16),

                // Total Expenses Card (FIRST)
                _buildTotalExpensesCard(totalExpenses),
                const SizedBox(height: 20),

                // Expenses List
                _buildExpensesList(filteredExpenses),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterInfo() {
    String filterText = 'All expenses';
    if (_selectedMonth != null && _selectedYear != null) {
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      filterText = '${months[_selectedMonth!.month - 1]} $_selectedYear';
    } else if (_selectedYear != null) {
      filterText = 'Year $_selectedYear';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.filter_list,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filtered by:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    filterText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedMonth != null || _selectedYear != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedMonth = null;
                    _selectedYear = null;
                  });
                },
                child: const Text('Clear'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalExpensesCard(Map<String, double> totals) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Total Expenses',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Total Amount (Your Share)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Your Share',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                      Theme.of(context).primaryColor.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${totals['total']?.toStringAsFixed(2) ?? '0.00'}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Total Paid
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Total Paid',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${totals['paid']?.toStringAsFixed(2) ?? '0.00'}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),

            // Balance
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (totals['balance'] ?? 0) >= 0
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    (totals['balance'] ?? 0) >= 0 ? 'You Are Owed' : 'You Owe',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: (totals['balance'] ?? 0) >= 0
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (totals['balance'] ?? 0) >= 0
                        ? '₹${totals['balance']?.toStringAsFixed(2) ?? '0.00'}'
                        : '₹${(totals['balance'] ?? 0).abs().toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: (totals['balance'] ?? 0) >= 0
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (totals['balance'] ?? 0) >= 0
                        ? 'Others owe you this amount'
                        : 'You owe others this amount',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: (totals['balance'] ?? 0) >= 0
                          ? Colors.green.shade600
                          : Colors.red.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesList(List<ExpenseModel> expenses) {
    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No expenses found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'No expenses found for the selected period',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Sort expenses by date (newest first)
    expenses.sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Expenses',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...expenses.map((expense) => Dismissible(
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
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                Theme.of(context).primaryColor.withValues(alpha: 0.1),
                child: Icon(
                  Icons.receipt,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              title: Text(
                expense.description.isNotEmpty
                    ? expense.description
                    : 'No description',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Paid by: ${expense.payerName}'),
                  Text(
                    '${expense.date.day}/${expense.date.month}/${expense.date.year}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '₹${expense.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${expense.split.length} people',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
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
                              ),
                            ),
                          );
                          if (updated == true && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Expense updated')),
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
              isThreeLine: true,
              onTap: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditExpenseScreen(
                      expense: expense,
                    ),
                  ),
                );
                if (updated == true && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Expense updated')),
                  );
                }
              },
            ),
          ),
        )),
      ],
    );
  }

  List<ExpenseModel> _applyDateFilter(List<ExpenseModel> expenses) {
    if (_selectedMonth == null && _selectedYear == null) {
      return expenses;
    }

    return expenses.where((expense) {
      if (_selectedMonth != null) {
        return expense.date.year == _selectedMonth!.year &&
            expense.date.month == _selectedMonth!.month;
      } else if (_selectedYear != null) {
        return expense.date.year == _selectedYear!;
      }
      return true;
    }).toList();
  }

  Stream<Map<String, dynamic>> _getExpensesAndSettlementsData(
      String userId, DatabaseService dbService) {
    return Rx.combineLatest2(
      dbService.getAllExpenses(),
      dbService.getAllSettlementsForUser(userId),
          (List<ExpenseModel> expenses, List<SettlementModel> settlements) {
        return {
          'expenses': expenses,
          'settlements': settlements,
        };
      },
    );
  }

  Map<String, double> _calculateTotalExpenses(
      List<ExpenseModel> expenses, String currentUserId) {
    double totalPaid = 0.0; // money you actually paid
    double totalOwed = 0.0; // money you owe to others (your share in expenses you didn't pay)
    double totalOwedToYou = 0.0; // money others owe you (your share in expenses you paid)

    for (final expense in expenses) {
      final userShare = expense.split[currentUserId] ?? 0.0;

      if (expense.payer == currentUserId) {
        // You paid this expense
        totalPaid += expense.amount;
        // Calculate how much others owe you (total amount minus your share)
        totalOwedToYou += (expense.amount - userShare);
      } else if (expense.split.containsKey(currentUserId)) {
        // Someone else paid, you owe your share
        totalOwed += userShare;
      }
    }

    // Total Amount: Shows only what you owe (your share in all expenses)
    final totalOwedAmount = totalOwed;

    // Balance: What others owe you minus what you owe others
    final balance = totalOwedToYou - totalOwed;

    return {
      'total': totalOwedAmount, // Your share only
      'paid': totalPaid, // What you actually paid
      'owedToYou': totalOwedToYou, // What others owe you
      'balance': balance, // Net balance (positive = others owe you, negative = you owe others)
    };
  }

  Map<String, double> _calculateTotalExpensesWithSettlements(
      List<ExpenseModel> expenses,
      List<SettlementModel> settlements,
      String currentUserId) {
    // First calculate base totals from expenses
    final baseTotals = _calculateTotalExpenses(expenses, currentUserId);

    // Apply settlements to adjust the balance
    double settlementAdjustment = 0.0;

    for (final settlement in settlements) {
      if (settlement.status == SettlementStatus.completed) {
        if (settlement.fromUser == currentUserId) {
          // You paid someone - reduce what others owe you
          settlementAdjustment -= settlement.amount;
        } else if (settlement.toUser == currentUserId) {
          // Someone paid you - increase what others owe you
          settlementAdjustment += settlement.amount;
        }
      }
    }

    // Update the balance with settlement adjustments
    final adjustedBalance = baseTotals['balance']! + settlementAdjustment;

    return {
      'total': baseTotals['total']!, // Your share remains the same
      'paid': baseTotals['paid']!, // What you paid remains the same
      'owedToYou': baseTotals['owedToYou']! + settlementAdjustment, // Adjusted for settlements
      'balance': adjustedBalance, // Net balance after settlements
    };
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Expenses'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filter by:'),
              const SizedBox(height: 16),

              // Year Filter
              DropdownButtonFormField<int?>(
                decoration: const InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(),
                ),
                value: _selectedYear,
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('All years'),
                  ),
                  ...List.generate(5, (index) {
                    final year = DateTime.now().year - index;
                    return DropdownMenuItem<int?>(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    _selectedYear = value;
                    if (value == null) {
                      _selectedMonth = null;
                    }
                  });
                },
              ),

              const SizedBox(height: 16),

              // Month Filter (only if year is selected)
              if (_selectedYear != null) ...[
                DropdownButtonFormField<DateTime?>(
                  decoration: const InputDecoration(
                    labelText: 'Month',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedMonth,
                  items: [
                    const DropdownMenuItem<DateTime?>(
                      value: null,
                      child: Text('All months'),
                    ),
                    ...List.generate(12, (index) {
                      final month = index + 1;
                      final date = DateTime(_selectedYear!, month);
                      final monthNames = [
                        'January',
                        'February',
                        'March',
                        'April',
                        'May',
                        'June',
                        'July',
                        'August',
                        'September',
                        'October',
                        'November',
                        'December'
                      ];
                      return DropdownMenuItem<DateTime?>(
                        value: date,
                        child: Text(monthNames[index]),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedMonth = value;
                    });
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // Values are already updated in the dialog
                });
                Navigator.of(context).pop();
              },
              child: const Text('Apply Filter'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showDeleteExpenseDialog(ExpenseModel expense) async {
    // Capture ScaffoldMessengerState and DatabaseService before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final dbService = Provider.of<DatabaseService>(context, listen: false);

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

    final success = await dbService.deleteExpense(expense.id, expense.groupId);

    if (!mounted) return false;

    if (success) {
      scaffoldMessenger.showSnackBar(
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
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(dbService.errorMessage ?? 'Failed to delete expense'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }
}