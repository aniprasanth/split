// Top-level functions for compute() to run on background isolates.
// These must use only simple/serializable data structures.

Map<String, double> balancesFromExpenseMaps(List<Map<String, dynamic>> expenseMaps) {
  final Map<String, double> balances = {};

  for (final e in expenseMaps) {
    final String payer = e['payer'] as String;
    final double amount = (e['amount'] as num).toDouble();
    final Map<String, dynamic> split = Map<String, dynamic>.from(e['split'] as Map);

    // Add amount paid by payer
    balances[payer] = (balances[payer] ?? 0) + amount;

    // Subtract splits for each member
    split.forEach((userId, value) {
      final double share = (value as num).toDouble();
      balances[userId] = (balances[userId] ?? 0) - share;
    });
  }

  return balances;
}

List<Map<String, dynamic>> settlementsFromBalances(Map<String, double> balances) {
  final List<Map<String, dynamic>> settlements = [];
  final creditors = <String, double>{};
  final debtors = <String, double>{};

  balances.forEach((userId, balance) {
    if (balance > 0.01) {
      creditors[userId] = balance;
    } else if (balance < -0.01) {
      debtors[userId] = -balance;
    }
  });

  final creditorList = creditors.entries.toList();
  final debtorList = debtors.entries.toList();

  int i = 0, j = 0;
  while (i < creditorList.length && j < debtorList.length) {
    final creditor = creditorList[i];
    final debtor = debtorList[j];

    final amount = creditor.value < debtor.value ? creditor.value : debtor.value;

    settlements.add({
      'from': debtor.key,
      'to': creditor.key,
      'amount': amount,
    });

    creditorList[i] = MapEntry(creditor.key, creditor.value - amount);
    debtorList[j] = MapEntry(debtor.key, debtor.value - amount);

    if (creditorList[i].value <= 0.01) i++;
    if (debtorList[j].value <= 0.01) j++;
  }

  return settlements;
}
