import 'dart:math';

/// Utilities for computing expense splits with correct rounding.
///
/// These helpers ensure that the sum of per-person amounts equals the original
/// total to 2 decimal places by distributing any leftover cents fairly.
class SplitUtils {
  /// Compute an equal split across [memberIds] for the given [totalAmount].
  ///
  /// - Rounds to 2 decimal places.
  /// - Distributes any remaining cents (due to rounding) to the first K members
  ///   to ensure the sum equals [totalAmount].
  static Map<String, double> computeEqualSplit(
    double totalAmount,
    List<String> memberIds,
  ) {
    if (memberIds.isEmpty || totalAmount <= 0) {
      return {for (final id in memberIds) id: 0.0};
    }

    // Work in cents to avoid floating point issues.
    final int totalCents = _toCents(totalAmount);
    final int numMembers = memberIds.length;

    final int baseCents = totalCents ~/ numMembers; // floor division
    final int remainder = totalCents % numMembers;   // cents left to distribute

    final Map<String, double> result = {};

    for (int i = 0; i < numMembers; i++) {
      // Give one extra cent to the first [remainder] members
      final int cents = baseCents + (i < remainder ? 1 : 0);
      result[memberIds[i]] = _toAmount(cents);
    }

    return result;
  }

  /// Adjust a map of custom splits so that the sum matches [totalAmount]
  /// after rounding to 2 decimals.
  ///
  /// Input [rawSplits] is a map of memberId -> desired amount (may have
  /// floating inaccuracy). We:
  /// - Convert to cents
  /// - Compute the delta between the sum of rounded cents and target cents
  /// - Distribute the delta by adjusting the largest fractional parts first
  static Map<String, double> adjustCustomSplits(
    double totalAmount,
    Map<String, double> rawSplits,
  ) {
    if (rawSplits.isEmpty) return {};

    final int targetCents = _toCents(totalAmount);

    // Capture fractional parts to decide distribution priority
    final entries = rawSplits.entries.map((e) {
      final exactCents = (e.value * 100).toDouble();
      final floored = exactCents.floor();
      final fraction = exactCents - floored;
      return _SplitEntry(e.key, exactCents, floored, fraction);
    }).toList();

    // Initial rounded cents using floor
    int currentSum = entries.fold(0, (sum, e) => sum + e.floored);
    int delta = targetCents - currentSum;

    // Sort by largest fractional part descending for adding cents
    // or by smallest fractional part ascending for removing cents
    if (delta > 0) {
      entries.sort((a, b) => b.fraction.compareTo(a.fraction));
    } else if (delta < 0) {
      entries.sort((a, b) => a.fraction.compareTo(b.fraction));
    }

    // Distribute the remaining delta (+/-) one cent at a time
    int i = 0;
    while (delta != 0 && entries.isNotEmpty) {
      final idx = i % entries.length;
      final e = entries[idx];
      // Apply a 1-cent adjustment in the appropriate direction
      if (delta > 0) {
        entries[idx] = e.copyWithFloored(e.floored + 1);
        delta -= 1;
      } else {
        // Avoid going below zero for any entry
        if (e.floored > 0) {
          entries[idx] = e.copyWithFloored(e.floored - 1);
          delta += 1;
        }
      }
      i += 1;
    }

    // Build result
    final Map<String, double> result = {
      for (final e in entries) e.memberId: _toAmount(e.floored)
    };

    return result;
  }

  static int _toCents(double amount) {
    return (amount * 100).round();
    // Note: using round to honor typical currency inputs already rounded to 2 dp.
  }

  static double _toAmount(int cents) {
    return cents / 100.0;
  }
}

class _SplitEntry {
  final String memberId;
  final double exactCents;
  final int floored;
  final double fraction;

  _SplitEntry(this.memberId, this.exactCents, this.floored, this.fraction);

  _SplitEntry copyWithFloored(int newFloored) =>
      _SplitEntry(memberId, exactCents, newFloored, fraction);
}
