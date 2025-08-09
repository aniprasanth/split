import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitzy/services/database_service.dart';
import 'package:splitzy/services/auth_service.dart';
import 'package:splitzy/models/expense_model.dart';

class MyExpensesScreen extends StatelessWidget {
  const MyExpensesScreen({super.key});

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
                final myExpenses = snapshot.data!
                    .where((e) =>
                        e.payer == currentUser.uid ||
                        e.split.keys.contains(currentUser.uid))
                    .toList();

                if (myExpenses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                          'Your expenses will appear here',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // Sort by date (newest first)
                myExpenses.sort((a, b) => b.date.compareTo(a.date));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: myExpenses.length,
                  itemBuilder: (context, index) {
                    final expense = myExpenses[index];
                    final isPayer = expense.payer == currentUser.uid;
                    final myShare = expense.split[currentUser.uid] ?? 0.0;
                    final isGroupExpense = expense.groupId.isNotEmpty;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: isPayer
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          child: Icon(
                            isPayer ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isPayer ? Colors.green : Colors.orange,
                          ),
                        ),
                        title: Text(
                          expense.description,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              isPayer
                                  ? 'You paid'
                                  : 'Paid by ${expense.payerName}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (isGroupExpense) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Group expense',
                                style: TextStyle(
                                  color: Colors.blue.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 2),
                            Text(
                              '${expense.date.day}/${expense.date.month}/${expense.date.year}',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (isPayer) ...[
                              Text(
                                '₹${expense.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.green.shade600,
                                ),
                              ),
                              Text(
                                'You paid',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ] else ...[
                              Text(
                                '₹${myShare.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.orange.shade600,
                                ),
                              ),
                              Text(
                                'Your share',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}