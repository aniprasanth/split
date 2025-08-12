import 'package:flutter/foundation.dart';
import 'package:splitzy/models/settlement_model.dart';
import 'package:splitzy/models/expense_model.dart';
import 'dart:math';

class SettlementService {
  /// Calculate optimal settlements for given expenses
  static Future<List<SettlementTransaction>> calculateOptimalSettlements(
    List<ExpenseModel> expenses,
    List<SettlementModel> existingSettlements,
  ) async {
    return await compute(_calculateSettlements, {
      'expenses': expenses.map((e) => e.toMap()).toList(),
      'settlements': existingSettlements.map((s) => s.toMap()).toList(),
    });
  }

  static List<SettlementTransaction> _calculateSettlements(Map<String, dynamic> params) {
    final expenses = (params['expenses'] as List).cast<Map<String, dynamic>>();
    final settlements = (params['settlements'] as List).cast<Map<String, dynamic>>();

    // Calculate net balances
    final balances = _calculateNetBalances(expenses, settlements);

    // Separate creditors and debtors
    final creditors = <String, double>{};
    final debtors = <String, double>{};

    for (final entry in balances.entries) {
      if (entry.value > 0.01) {
        creditors[entry.key] = entry.value;
      } else if (entry.value < -0.01) {
        debtors[entry.key] = entry.value.abs();
      }
    }

    return _minimizeTransactions(creditors, debtors);
  }

  static Map<String, double> _calculateNetBalances(
    List<Map<String, dynamic>> expenses,
    List<Map<String, dynamic>> settlements,
  ) {
    final balances = <String, double>{};

    // Process expenses
    for (final expense in expenses) {
      final payer = expense['payer'] as String;
      final amount = (expense['amount'] as num).toDouble();
      final splits = Map<String, double>.from(expense['split'] as Map);

      // Add what payer paid
      balances[payer] = (balances[payer] ?? 0.0) + amount;

      // Subtract what each person owes
      for (final split in splits.entries) {
        balances[split.key] = (balances[split.key] ?? 0.0) - split.value;
      }
    }

    // Process existing settlements
    for (final settlement in settlements) {
      if (settlement['status'] == SettlementStatus.completed.name) {
        final fromUser = settlement['fromUserId'] as String;
        final toUser = settlement['toUserId'] as String;
        final amount = (settlement['amount'] as num).toDouble();

        balances[fromUser] = (balances[fromUser] ?? 0.0) + amount;
        balances[toUser] = (balances[toUser] ?? 0.0) - amount;
      }
    }

    // Round balances to 2 decimal places
    for (final key in balances.keys) {
      balances[key] = (balances[key]! * 100).round() / 100;
    }

    return balances;
  }

  static List<SettlementTransaction> _minimizeTransactions(
    Map<String, double> creditors,
    Map<String, double> debtors,
  ) {
    final settlements = <SettlementTransaction>[];

    // Sort by amount (descending)
    final sortedCreditors = creditors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedDebtors = debtors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    var creditorIndex = 0;
    var debtorIndex = 0;

    while (creditorIndex < sortedCreditors.length && debtorIndex < sortedDebtors.length) {
      final creditor = sortedCreditors[creditorIndex];
      final debtor = sortedDebtors[debtorIndex];

      final amount = min(creditor.value, debtor.value);

      if (amount > 0.01) {
        settlements.add(SettlementTransaction(
          from: debtor.key,
          to: creditor.key,
          amount: (amount * 100).round() / 100, // Round to 2 decimal places
        ));

        // Update remaining amounts
        creditors[creditor.key] = creditor.value - amount;
        debtors[debtor.key] = debtor.value - amount;

        // Move to next person if current one is fully settled
        if (creditors[creditor.key]! < 0.01) creditorIndex++;
        if (debtors[debtor.key]! < 0.01) debtorIndex++;
      } else {
        break;
      }
    }

    return settlements;
  }

  /// Validate a settlement amount
  static bool isValidSettlementAmount(double amount) {
    return amount > 0 && amount <= 999999.99;
  }

  /// Calculate total pending settlements for a user
  static double calculatePendingSettlements(
    String userId,
    List<SettlementModel> settlements,
  ) {
    double total = 0.0;
    
    for (final settlement in settlements) {
      if (settlement.status == SettlementStatus.pending) {
        if (settlement.fromUserId == userId) {
          total += settlement.amount;
        } else if (settlement.toUserId == userId) {
          total -= settlement.amount;
        }
      }
    }
    
    return (total * 100).round() / 100;
  }
}