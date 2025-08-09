import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:splitzy/services/database_service.dart';
import 'package:splitzy/services/auth_service.dart';
import 'package:splitzy/models/expense_model.dart';
import 'package:splitzy/models/settlement_model.dart';
import 'package:splitzy/models/group_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ExpenseModel> _expenses = [];
  List<SettlementModel> _settlements = [];
  List<GroupModel> _groups = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        setState(() {
          _errorMessage = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      final dbService = Provider.of<DatabaseService>(context, listen: false);

      // Load user groups first
      final groupsStream = dbService.getUserGroups(currentUser.uid);
      groupsStream.listen((groups) async {
        _groups = groups;

        // Load expenses for all groups
        List<ExpenseModel> allExpenses = [];
        List<SettlementModel> allSettlements = [];

        for (final group in groups) {
          // Load expenses
          final expensesStream = dbService.getGroupExpenses(group.id);
          await for (final expenses in expensesStream.take(1)) {
            allExpenses.addAll(expenses);
          }

          // Load settlements
          final settlementsStream = dbService.getGroupSettlements(group.id);
          await for (final settlements in settlementsStream.take(1)) {
            allSettlements.addAll(settlements);
          }
        }

        // Sort by date (most recent first)
        allExpenses.sort((a, b) => b.date.compareTo(a.date));
        allSettlements.sort((a, b) => b.date.compareTo(a.date));

        if (mounted) {
          setState(() {
            _expenses = allExpenses;
            _settlements = allSettlements;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load history: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.receipt),
              text: 'Expenses',
            ),
            Tab(
              icon: Icon(Icons.account_balance),
              text: 'Settlements',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadHistory,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildExpensesTab(),
                    _buildSettlementsTab(),
                  ],
                ),
    );
  }

  Widget _buildExpensesTab() {
    if (_expenses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No expenses found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Start by adding your first expense!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _expenses.length,
        itemBuilder: (context, index) {
          final expense = _expenses[index];
          final group = _groups.firstWhere(
            (g) => g.id == expense.groupId,
            orElse: () => GroupModel(
              id: expense.groupId,
              name: 'Unknown Group',
              members: [],
              memberNames: {},
              createdBy: '',
            ),
          );

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(
                  Icons.receipt,
                  color: Colors.white,
                ),
              ),
              title: Text(
                expense.description,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Group: ${group.name}'),
                  Text('Paid by: ${expense.payerName}'),
                  Text(
                    'Date: ${DateFormat('MMM dd, yyyy').format(expense.date)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${expense.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Text(
                    '${expense.split.length} people',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              onTap: () => _showExpenseDetails(expense, group),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettlementsTab() {
    if (_settlements.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No settlements found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Settlements will appear here when debts are paid',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _settlements.length,
        itemBuilder: (context, index) {
          final settlement = _settlements[index];
          final group = _groups.firstWhere(
            (g) => g.id == settlement.groupId,
            orElse: () => GroupModel(
              id: settlement.groupId,
              name: 'Unknown Group',
              members: [],
              memberNames: {},
              createdBy: '',
            ),
          );

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green,
                child: const Icon(
                  Icons.account_balance,
                  color: Colors.white,
                ),
              ),
              title: Text(
                '${settlement.fromUserName} → ${settlement.toUserName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Group: ${group.name}'),
                  Text(
                    'Date: ${DateFormat('MMM dd, yyyy').format(settlement.date)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              trailing: Text(
                '₹${settlement.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green,
                ),
              ),
              onTap: () => _showSettlementDetails(settlement, group),
            ),
          );
        },
      ),
    );
  }

  void _showExpenseDetails(ExpenseModel expense, GroupModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(expense.description),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Group', group.name),
            _buildDetailRow('Amount', '₹${expense.amount.toStringAsFixed(2)}'),
            _buildDetailRow('Paid by', expense.payerName),
            _buildDetailRow('Date', DateFormat('MMMM dd, yyyy').format(expense.date)),
            const SizedBox(height: 16),
            const Text(
              'Split Details:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...expense.split.entries.map((entry) {
              final memberName = group.getMemberName(entry.key);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(memberName),
                    Text('₹${entry.value.toStringAsFixed(2)}'),
                  ],
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSettlementDetails(SettlementModel settlement, GroupModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settlement Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Group', group.name),
            _buildDetailRow('Amount', '₹${settlement.amount.toStringAsFixed(2)}'),
            _buildDetailRow('From', settlement.fromUserName),
            _buildDetailRow('To', settlement.toUserName),
            _buildDetailRow('Date', DateFormat('MMMM dd, yyyy').format(settlement.date)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
