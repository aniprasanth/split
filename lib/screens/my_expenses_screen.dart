import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitzy/services/database_service.dart';
import 'package:splitzy/services/auth_service.dart';
import 'package:splitzy/models/expense_model.dart';

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
          : StreamBuilder<List<ExpenseModel>>(
        stream: dbService.getAllExpenses(),
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
                    'Error loading expenses',
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

          // Filter for current user's expenses (where user is payer or involved in split)
          final allMyExpenses = snapshot.data!
              .where((e) =>
          e.payer == currentUser.uid ||
              e.split.keys.contains(currentUser.uid))
              .toList();

          // Apply date filtering
          final filteredExpenses = _applyDateFilter(allMyExpenses);

          // Calculate totals
          final totalExpenses = _calculateTotalExpenses(filteredExpenses, currentUser.uid);

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
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
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

            // Total Amount
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
                    'Total Amount',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
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

            // Breakdown
            Row(
              children: [
                Expanded(
                  child: _buildBreakdownItem(
                    'You Paid',
                    totals['paid'] ?? 0.0,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBreakdownItem(
                    'Your Share',
                    totals['share'] ?? 0.0,
                    Colors.orange,
                  ),
                ),
              ],
            ),

            if ((totals['balance'] ?? 0.0) != 0) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (totals['balance']! > 0 ? Colors.green : Colors.red).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (totals['balance']! > 0 ? Colors.green : Colors.red).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      totals['balance']! > 0 ? Icons.trending_up : Icons.trending_down,
                      color: totals['balance']! > 0 ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      totals['balance']! > 0
                          ? 'You are owed ₹${totals['balance']!.toStringAsFixed(2)}'
                          : 'You owe ₹${(-totals['balance']!).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: totals['balance']! > 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesList(List<ExpenseModel> expenses) {
    if (expenses.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No Expenses Found',
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
        ...expenses.map((expense) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              child: Icon(
                Icons.receipt,
                color: Theme.of(context).primaryColor,
              ),
            ),
            title: Text(
              expense.description.isNotEmpty ? expense.description : 'No description',
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
            trailing: Column(
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
            isThreeLine: true,
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

  Map<String, double> _calculateTotalExpenses(List<ExpenseModel> expenses, String currentUserId) {
    double totalPaid = 0.0;
    double totalShare = 0.0;
    double totalAmount = 0.0;

    for (final expense in expenses) {
      totalAmount += expense.amount;

      if (expense.payer == currentUserId) {
        totalPaid += expense.amount;
      }

      if (expense.split.containsKey(currentUserId)) {
        totalShare += expense.split[currentUserId] ?? 0.0;
      }
    }

    final balance = totalPaid - totalShare;

    return {
      'total': totalAmount,
      'paid': totalPaid,
      'share': totalShare,
      'balance': balance,
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
                        'January', 'February', 'March', 'April', 'May', 'June',
                        'July', 'August', 'September', 'October', 'November', 'December'
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
}