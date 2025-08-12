import 'package:flutter/foundation.dart';
import 'dart:async';

class SplitCalculationService {
  /// Calculate splits using isolate for better performance
  static Future<Map<String, double>> calculateSplitAsync({
    required double amount,
    required List<String> members,
    required SplitType splitType,
    Map<String, double>? customRatios,
  }) async {
    return await compute(_calculateSplit, {
      'amount': amount,
      'members': members,
      'splitType': splitType.index,
      'customRatios': customRatios,
    });
  }
  
  /// Handle split calculations with proper rounding
  static Map<String, double> _calculateSplit(Map<String, dynamic> params) {
    final amount = params['amount'] as double;
    final members = params['members'] as List<String>;
    final splitType = SplitType.values[params['splitType'] as int];
    final customRatios = params['customRatios'] as Map<String, double>?;
    
    switch (splitType) {
      case SplitType.equal:
        return _calculateEqualSplit(amount, members);
      case SplitType.percentage:
        return _calculatePercentageSplit(amount, customRatios!);
      case SplitType.shares:
        return _calculateSharesSplit(amount, customRatios!);
      case SplitType.exact:
        return _validateAndAdjustExactSplit(amount, customRatios!);
      case SplitType.adjustment:
        return customRatios ?? {};
    }
  }
  
  static Map<String, double> _calculateEqualSplit(double amount, List<String> members) {
    if (members.isEmpty) return {};
    
    final perPerson = (amount / members.length).roundToNDecimalPlaces(2);
    final splits = <String, double>{};
    
    // Handle rounding errors by adjusting the last split
    double remaining = amount;
    for (int i = 0; i < members.length; i++) {
      if (i == members.length - 1) {
        splits[members[i]] = remaining;
      } else {
        splits[members[i]] = perPerson;
        remaining -= perPerson;
      }
    }
    
    return splits;
  }

  static Map<String, double> _calculatePercentageSplit(
    double amount, 
    Map<String, double> percentages
  ) {
    final splits = <String, double>{};
    double remaining = amount;
    
    final sortedEntries = percentages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      if (i == sortedEntries.length - 1) {
        splits[entry.key] = remaining;
      } else {
        final split = (amount * entry.value / 100).roundToNDecimalPlaces(2);
        splits[entry.key] = split;
        remaining -= split;
      }
    }
    
    return splits;
  }
  
  static Map<String, double> _calculateSharesSplit(
    double amount, 
    Map<String, double> shares
  ) {
    final totalShares = shares.values.fold(0.0, (sum, share) => sum + share);
    final splits = <String, double>{};
    double remaining = amount;
    
    final sortedEntries = shares.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      if (i == sortedEntries.length - 1) {
        splits[entry.key] = remaining;
      } else {
        final split = (amount * entry.value / totalShares).roundToNDecimalPlaces(2);
        splits[entry.key] = split;
        remaining -= split;
      }
    }
    
    return splits;
  }
  
  static Map<String, double> _validateAndAdjustExactSplit(
    double amount, 
    Map<String, double> exactAmounts
  ) {
    final total = exactAmounts.values.fold(0.0, (sum, value) => sum + value);
    if ((total - amount).abs() > 0.01) {
      throw ExpenseSplitException(
        'Sum of exact amounts must equal total amount',
        'INVALID_SPLIT'
      );
    }
    return exactAmounts;
  }
}

extension DoubleExtension on double {
  double roundToNDecimalPlaces(int n) {
    final mod = pow(10.0, n);
    return (this * mod).round() / mod;
  }
}

enum SplitType {
  equal,
  percentage,
  shares,
  exact,
  adjustment
}

class ExpenseSplitException implements Exception {
  final String message;
  final String code;
  
  ExpenseSplitException(this.message, this.code);
  
  @override
  String toString() => 'ExpenseSplitException: $message (Code: $code)';
}