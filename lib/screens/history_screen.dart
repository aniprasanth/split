import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:splitzy/services/database_service.dart';
import 'package:splitzy/services/auth_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Transaction History'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Settlements'),
          ],
        ),
      ),
      body: Consumer2<AuthService, DatabaseService>(
        builder: (context, authService, dbService, child) {
          final currentUser = authService.currentUser;
          if (currentUser == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('User not authenticated'),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildExpensesTab(dbService, currentUser.uid),
              _buildSettlementsTab(dbService, currentUser.uid),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExpensesTab(DatabaseService dbService, String userId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: dbService.getTransactionHistory(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                const Text('Error loading transaction history'),
              ],
            ),
          );
        }

        final transactions = snapshot.data ?? [];
        final expenses = transactions.where((t) => t['type'] == 'expense').toList();

        if (expenses.isEmpty) {
          return _buildEmptyState('No expenses found', Icons.receipt_long);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            final isHistorical = expense['isHistorical'] ?? false;
            final isDeleted = expense['isDeleted'] ?? false;
            final deletedGroupName = expense['deletedGroupName'];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isDeleted
                      ? Colors.red.shade100
                      : isHistorical
                      ? Colors.orange.shade100
                      : Colors.green.shade100,
                  child: Icon(
                    isDeleted ? Icons.delete : Icons.receipt,
                    color: isDeleted
                        ? Colors.red.shade700
                        : isHistorical
                        ? Colors.orange.shade700
                        : Colors.green.shade700,
                  ),
                ),
                title: Text(
                  expense['description'] ?? 'Unknown Expense',
                  style: TextStyle(
                    decoration: isDeleted ? TextDecoration.lineThrough : null,
                    color: isDeleted ? Colors.grey : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${(expense['amount'] ?? 0).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDeleted ? Colors.grey : null,
                      ),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy').format(
                        expense['date'] is String
                            ? DateTime.parse(expense['date'])
                            : expense['date'],
                      ),
                      style: TextStyle(
                        color: isDeleted ? Colors.grey : Colors.grey.shade600,
                      ),
                    ),
                    if (isDeleted && deletedGroupName != null)
                      Text(
                        'From deleted group: $deletedGroupName',
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 12,
                        ),
                      ),
                    if (isHistorical && !isDeleted)
                      Text(
                        'Historical transaction',
                        style: TextStyle(
                          color: Colors.orange.shade600,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                trailing: Text(
                  expense['payerName'] ?? 'Unknown',
                  style: TextStyle(
                    color: isDeleted ? Colors.grey : null,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettlementsTab(DatabaseService dbService, String userId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: dbService.getTransactionHistory(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                const Text('Error loading settlement history'),
              ],
            ),
          );
        }

        final transactions = snapshot.data ?? [];
        final settlements = transactions.where((t) => t['type'] == 'settlement').toList();

        if (settlements.isEmpty) {
          return _buildEmptyState('No settlements found', Icons.payment);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: settlements.length,
          itemBuilder: (context, index) {
            final settlement = settlements[index];
            final isHistorical = settlement['isHistorical'] ?? false;
            final isDeleted = settlement['isDeleted'] ?? false;
            final status = settlement['status'] ?? 'pending';
            final deletedGroupName = settlement['deletedGroupName'];

            MaterialColor statusColor;
            IconData statusIcon;
            String statusText;

            switch (status) {
              case 'completed':
                statusColor = Colors.green;
                statusIcon = Icons.check_circle;
                statusText = 'Completed';
                break;
              case 'cancelled':
                statusColor = Colors.red;
                statusIcon = Icons.cancel;
                statusText = 'Cancelled';
                break;
              default:
                statusColor = Colors.orange;
                statusIcon = Icons.pending;
                statusText = 'Pending';
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isDeleted
                      ? Colors.red.shade100
                      : statusColor.shade100,
                  child: Icon(
                    isDeleted ? Icons.delete : statusIcon,
                    color: isDeleted
                        ? Colors.red.shade700
                        : statusColor.shade700,
                  ),
                ),
                title: Text(
                  '${settlement['fromUserName'] ?? 'Unknown'} → ${settlement['toUserName'] ?? 'Unknown'}',
                  style: TextStyle(
                    decoration: isDeleted ? TextDecoration.lineThrough : null,
                    color: isDeleted ? Colors.grey : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${(settlement['amount'] ?? 0).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDeleted ? Colors.grey : null,
                      ),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy').format(
                        settlement['date'] is String
                            ? DateTime.parse(settlement['date'])
                            : settlement['date'],
                      ),
                      style: TextStyle(
                        color: isDeleted ? Colors.grey : Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: isDeleted ? Colors.grey : statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isDeleted && deletedGroupName != null)
                      Text(
                        'From deleted group: $deletedGroupName',
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 12,
                        ),
                      ),
                    if (isHistorical && !isDeleted)
                      Text(
                        'Historical transaction',
                        style: TextStyle(
                          color: Colors.orange.shade600,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                trailing: Text(
                  settlement['paymentMethod'] ?? 'Cash',
                  style: TextStyle(
                    color: isDeleted ? Colors.grey : null,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your transaction history will appear here',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}