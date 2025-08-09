import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitzy/services/database_service.dart';
import 'package:splitzy/models/expense_model.dart';

class NonGroupExpensesScreen extends StatelessWidget {
  const NonGroupExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Non-Group Expenses'),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<List<ExpenseModel>>(
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

          // Filter for non-group expenses (empty groupId and split between 2 people)
          final nonGroupExpenses = snapshot.data!
              .where((e) => e.groupId.isEmpty && e.split.length == 2)
              .toList();

          if (nonGroupExpenses.isEmpty) {
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
                    'No Non-Group Expenses',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Expenses shared between two people will appear here',
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
          nonGroupExpenses.sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: nonGroupExpenses.length,
            itemBuilder: (context, index) {
              final expense = nonGroupExpenses[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.receipt,
                      color: Theme.of(context).primaryColor,
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
                        'Paid by ${expense.payerName}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
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
                      Text(
                        '₹${expense.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      Text(
                        '₹${(expense.amount / expense.split.length).toStringAsFixed(2)} each',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
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
