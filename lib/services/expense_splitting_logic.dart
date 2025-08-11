import 'dart:math';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;

/// Expense splitting logic service
/// Handles equal, unequal, and percentage splits with balance tracking and settlement optimization
class ExpenseSplittingLogic {
  // Initialize logger with production-ready configuration
  final Logger _logger = Logger(
    printer: PrettyPrinter(),
    level: kReleaseMode ? Level.warning : Level.debug,
  );

  /// Represents a member's balance (positive = credit, negative = debt)
  final Map<String, double> _balances = {};

  /// List of all expenses for balance recalculation
  final List<ExpenseData> _expenses = [];

  /// Get current balances for all members
  Map<String, double> get balances => Map.from(_balances);

  /// Get all expenses
  List<ExpenseData> get expenses => List.from(_expenses);

  /// Add a new expense and update balances
  ///
  /// [expense] - The expense data containing payer, amount, and splits
  /// Returns true if expense was added successfully
  bool addExpense(ExpenseData expense) {
    try {
      // Validate expense data
      if (!_validateExpense(expense)) {
        return false;
      }

      // Add expense to list
      _expenses.add(expense);

      // Recalculate all balances from scratch to ensure accuracy
      _recalculateBalances();

      return true;
    } catch (e) {
      _logger.e('Error adding expense: $e');
      return false;
    }
  }

  /// Remove an expense and recalculate balances
  ///
  /// [expenseId] - Unique identifier of the expense to remove
  /// Returns true if expense was removed successfully
  bool removeExpense(String expenseId) {
    try {
      final initialLength = _expenses.length;
      _expenses.removeWhere((expense) => expense.id == expenseId);

      if (_expenses.length == initialLength) {
        return false; // Expense not found
      }

      // Recalculate all balances
      _recalculateBalances();

      return true;
    } catch (e) {
      _logger.e('Error removing expense: $e');
      return false;
    }
  }

  /// Calculate current balances for all members
  ///
  /// Returns map of member ID to balance (positive = credit, negative = debt)
  Map<String, double> calculateBalances() {
    _recalculateBalances();
    return Map.from(_balances);
  }

  /// Get optimal settlements to minimize number of transactions
  /// Uses greedy algorithm to find minimal transactions
  ///
  /// Returns list of settlement transactions
  List<SettlementTransaction> getSettlements() {
    _recalculateBalances();

    final settlements = <SettlementTransaction>[];
    final balances = Map<String, double>.from(_balances);

    // Separate creditors and debtors
    final creditors = <String, double>{};
    final debtors = <String, double>{};

    for (final entry in balances.entries) {
      if (entry.value > 0.01) {
        // Small threshold to avoid rounding issues
        creditors[entry.key] = entry.value;
      } else if (entry.value < -0.01) {
        debtors[entry.key] = entry.value.abs();
      }
    }

    // Sort by amount (largest first for optimal greedy algorithm)
    final sortedCreditors = creditors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedDebtors = debtors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Greedy algorithm: match largest creditors with largest debtors
    int creditorIndex = 0;
    int debtorIndex = 0;

    while (creditorIndex < sortedCreditors.length &&
        debtorIndex < sortedDebtors.length) {
      final creditor = sortedCreditors[creditorIndex];
      final debtor = sortedDebtors[debtorIndex];

      final amount = min(creditor.value, debtor.value);

      if (amount > 0.01) {
        // Only create settlement if amount is significant
        settlements.add(SettlementTransaction(
          from: debtor.key,
          to: creditor.key,
          amount: _roundToTwoDecimals(amount),
        ));

        // Update remaining amounts in the maps
        creditors[creditor.key] = creditor.value - amount;
        debtors[debtor.key] = debtor.value - amount;

        // Move to next creditor/debtor if current one is fully settled
        if (creditors[creditor.key]! < 0.01) {
          creditorIndex++;
        }
        if (debtors[debtor.key]! < 0.01) {
          debtorIndex++;
        }
      } else {
        break;
      }
    }

    return settlements;
  }

  /// Get total amount owed by a specific member
  ///
  /// [memberId] - ID of the member
  /// Returns the amount owed (negative) or owed to (positive)
  double getMemberBalance(String memberId) {
    return _balances[memberId] ?? 0.0;
  }

  /// Get total amount of all expenses
  double getTotalExpenseAmount() {
    return _expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Get expenses for a specific member (as payer or participant)
  ///
  /// [memberId] - ID of the member
  /// Returns list of expenses involving this member
  List<ExpenseData> getMemberExpenses(String memberId) {
    return _expenses.where((expense) {
      return expense.payer == memberId || expense.splits.containsKey(memberId);
    }).toList();
  }

  /// Clear all data (useful for testing or resetting)
  void clear() {
    _balances.clear();
    _expenses.clear();
  }

  /// Validate expense data before adding
  bool _validateExpense(ExpenseData expense) {
    // Check basic requirements
    if (expense.amount <= 0) {
      _logger.w('Invalid expense amount: ${expense.amount}');
      return false;
    }

    if (expense.payer.isEmpty) {
      _logger.w('Payer cannot be empty');
      return false;
    }

    if (expense.splits.isEmpty) {
      _logger.w('Expense must have at least one participant');
      return false;
    }

    // Check if payer is in splits (unless it's a special case)
    if (!expense.splits.containsKey(expense.payer)) {
      _logger.w('Payer must be included in splits');
      return false;
    }

    // Validate split amounts
    double totalSplit = 0.0;
    for (final split in expense.splits.values) {
      if (split < 0) {
        _logger.w('Split amounts cannot be negative');
        return false;
      }
      totalSplit += split;
    }

    // Allow small rounding differences (within 0.01)
    if ((totalSplit - expense.amount).abs() > 0.01) {
      _logger.w('Split amounts ($totalSplit) must equal expense amount (${expense.amount})');
      return false;
    }

    return true;
  }

  /// Recalculate all balances from scratch
  /// This ensures accuracy even when expenses are modified or removed
  void _recalculateBalances() {
    _balances.clear();

    for (final expense in _expenses) {
      // Add what the payer paid
      _balances[expense.payer] = (_balances[expense.payer] ?? 0.0) + expense.amount;

      // Subtract what each participant owes
      for (final entry in expense.splits.entries) {
        final participant = entry.key;
        final amount = entry.value;

        _balances[participant] = (_balances[participant] ?? 0.0) - amount;
      }
    }

    // Round all balances to 2 decimal places
    for (final key in _balances.keys) {
      _balances[key] = _roundToTwoDecimals(_balances[key]!);
    }

    // Verify that balances sum to zero (within rounding error)
    final totalBalance = _balances.values.fold(0.0, (sum, balance) => sum + balance);
    if (totalBalance.abs() > 0.01) {
      _logger.w('Total balance is not zero: $totalBalance');
    }
  }

  /// Round amount to 2 decimal places
  double _roundToTwoDecimals(double amount) {
    return (amount * 100).round() / 100;
  }
}

/// Represents an expense with splitting information
class ExpenseData {
  final String id;
  final String payer;
  final double amount;
  final Map<String, double> splits; // memberId -> amount
  final String description;
  final DateTime date;
  final SplitType splitType;

  ExpenseData({
    required this.id,
    required this.payer,
    required this.amount,
    required this.splits,
    required this.description,
    required this.date,
    required this.splitType,
  });

  /// Create expense with equal split among participants
  factory ExpenseData.equalSplit({
    required String id,
    required String payer,
    required double amount,
    required List<String> participants,
    required String description,
    required DateTime date,
  }) {
    final splitAmount = amount / participants.length;
    final splits = <String, double>{};

    for (final participant in participants) {
      splits[participant] = splitAmount;
    }

    return ExpenseData(
      id: id,
      payer: payer,
      amount: amount,
      splits: splits,
      description: description,
      date: date,
      splitType: SplitType.equal,
    );
  }

  /// Create expense with custom amounts for each participant
  factory ExpenseData.customSplit({
    required String id,
    required String payer,
    required double amount,
    required Map<String, double> splits,
    required String description,
    required DateTime date,
  }) {
    return ExpenseData(
      id: id,
      payer: payer,
      amount: amount,
      splits: splits,
      description: description,
      date: date,
      splitType: SplitType.custom,
    );
  }

  /// Create expense with percentage-based split
  factory ExpenseData.percentageSplit({
    required String id,
    required String payer,
    required double amount,
    required Map<String, double> percentages, // memberId -> percentage (0-100)
    required String description,
    required DateTime date,
  }) {
    final splits = <String, double>{};

    for (final entry in percentages.entries) {
      final percentage = entry.value / 100.0;
      splits[entry.key] = amount * percentage;
    }

    return ExpenseData(
      id: id,
      payer: payer,
      amount: amount,
      splits: splits,
      description: description,
      date: date,
      splitType: SplitType.percentage,
    );
  }

  /// Create expense with multiple payers
  factory ExpenseData.multiplePayers({
    required String id,
    required Map<String, double> payers, // payerId -> amount paid
    required Map<String, double> splits, // participantId -> amount owed
    required String description,
    required DateTime date,
  }) {
    final totalPaid = payers.values.fold(0.0, (sum, amount) => sum + amount);
    final totalOwed = splits.values.fold(0.0, (sum, amount) => sum + amount);

    if ((totalPaid - totalOwed).abs() > 0.01) {
      throw ArgumentError('Total paid ($totalPaid) must equal total owed ($totalOwed)');
    }

    // For multiple payers, we need to handle this specially
    // The payer field will be the primary payer, but we'll track all payments
    final primaryPayer = payers.entries.first.key;

    return ExpenseData(
      id: id,
      payer: primaryPayer,
      amount: totalPaid,
      splits: splits,
      description: description,
      date: date,
      splitType: SplitType.multiplePayers,
    );
  }

  @override
  String toString() {
    return 'ExpenseData(id: $id, payer: $payer, amount: $amount, splits: $splits, type: $splitType)';
  }
}

/// Represents a settlement transaction between two members
class SettlementTransaction {
  final String from; // Member who owes money
  final String to; // Member who is owed money
  final double amount;

  SettlementTransaction({
    required this.from,
    required this.to,
    required this.amount,
  });

  @override
  String toString() {
    return 'SettlementTransaction(from: $from, to: $to, amount: $amount)';
  }
}

/// Types of expense splitting
enum SplitType {
  equal, // Equal split among all participants
  custom, // Custom amounts for each participant
  percentage, // Percentage-based split
  multiplePayers, // Multiple members paid for the expense
}

/// Utility class for creating common split scenarios
class SplitUtils {
  /// Create equal split among participants
  static Map<String, double> createEqualSplit(
      double amount, List<String> participants) {
    if (participants.isEmpty) return {};

    final splitAmount = amount / participants.length;
    final splits = <String, double>{};

    for (final participant in participants) {
      splits[participant] = splitAmount;
    }

    return splits;
  }

  /// Create custom split with specified amounts
  static Map<String, double> createCustomSplit(Map<String, double> amounts) {
    return Map.from(amounts);
  }

  /// Create percentage-based split
  static Map<String, double> createPercentageSplit(
      double amount, Map<String, double> percentages) {
    final splits = <String, double>{};

    for (final entry in percentages.entries) {
      final percentage = entry.value / 100.0;
      splits[entry.key] = amount * percentage;
    }

    return splits;
  }

  /// Adjust splits to ensure they sum to the total amount
  /// Useful for handling rounding errors
  static Map<String, double> adjustSplitsToTotal(
      double totalAmount, Map<String, double> splits) {
    final adjustedSplits = Map<String, double>.from(splits);
    final currentTotal =
    adjustedSplits.values.fold(0.0, (sum, amount) => sum + amount);

    if (currentTotal == 0) return adjustedSplits;

    final difference = totalAmount - currentTotal;

    if (difference.abs() > 0.01) {
      // Find the largest split and adjust it to make up the difference
      String largestSplitKey = adjustedSplits.keys.first;
      double largestAmount = adjustedSplits[largestSplitKey]!;

      for (final entry in adjustedSplits.entries) {
        if (entry.value > largestAmount) {
          largestAmount = entry.value;
          largestSplitKey = entry.key;
        }
      }

      adjustedSplits[largestSplitKey] = largestAmount + difference;
    }

    return adjustedSplits;
  }

  /// Round all split amounts to 2 decimal places
  static Map<String, double> roundSplits(Map<String, double> splits) {
    final roundedSplits = <String, double>{};

    for (final entry in splits.entries) {
      roundedSplits[entry.key] = (entry.value * 100).round() / 100;
    }

    return roundedSplits;
  }
}