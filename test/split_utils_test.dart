import 'package:flutter_test/flutter_test.dart';
import 'package:splitzy/utils/split_utils.dart';

void main() {
  group('SplitUtils.computeEqualSplit', () {
    test('splits equally with exact cents and sums to total', () {
      final result = SplitUtils.computeEqualSplit(100.00, ['a', 'b', 'c', 'd']);
      expect(result.length, 4);
      expect(result.values.fold(0.0, (s, v) => s + v), 100.00);
      for (final v in result.values) {
        expect(v, 25.00);
      }
    });

    test('splits and distributes remainders fairly', () {
      final result = SplitUtils.computeEqualSplit(10.00, ['a', 'b', 'c']);
      // 1000 cents / 3 = 333 each, remainder 1 -> first gets extra cent
      expect(result['a'], 3.34);
      expect(result['b'], 3.33);
      expect(result['c'], 3.33);
      final sum = double.parse(result.values.fold(0.0, (s, v) => (s + v)).toStringAsFixed(2));
      expect(sum, 10.00);
    });

    test('handles zero or empty member list', () {
      final result = SplitUtils.computeEqualSplit(50.00, []);
      expect(result, isEmpty);
    });
  });

  group('SplitUtils.adjustCustomSplits', () {
    test('adjusts to match total with rounding down then distributing', () {
      final result = SplitUtils.adjustCustomSplits(100.0, {
        'a': 33.3333,
        'b': 33.3333,
        'c': 33.3333,
      });
      final sum = double.parse(result.values.fold(0.0, (s, v) => (s + v)).toStringAsFixed(2));
      expect(sum, 100.00);
      // Check that rounding is within 1 cent around 33.33 each
      for (final v in result.values) {
        expect(v >= 33.33 && v <= 33.34, isTrue);
      }
    });

    test('does not produce negatives when reducing', () {
      final result = SplitUtils.adjustCustomSplits(1.00, {
        'a': 1.00,
        'b': 0.50,
        'c': 0.50,
      });
      final sum = double.parse(result.values.fold(0.0, (s, v) => (s + v)).toStringAsFixed(2));
      expect(sum, 1.00);
      for (final v in result.values) {
        expect(v >= 0.0, isTrue);
      }
    });
  });
}
