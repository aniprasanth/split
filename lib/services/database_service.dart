import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitzy/models/group_model.dart';
import 'package:splitzy/models/expense_model.dart';
import 'package:splitzy/models/settlement_model.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';

class DatabaseService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Logger _logger = Logger();
  
  bool _isLoading = false;
  String? _errorMessage;
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _setError(null);
  }

  // ========== GROUP OPERATIONS ==========
  Future<bool> createGroup(GroupModel group) async {
    try {
      _setLoading(true);
      _setError(null);
      
      await _db.collection('groups').doc(group.id).set(group.toMap());
      
      _logger.i('Group created successfully: ${group.name}');
      return true;
    } catch (e) {
      _logger.e('Error creating group: $e');
      _setError('Failed to create group');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateGroup(GroupModel group) async {
    try {
      _setLoading(true);
      _setError(null);
      
      final updated = group.copyWith(updatedAt: DateTime.now());
      await _db.collection('groups').doc(group.id).set(updated.toMap(), SetOptions(merge: true));
      
      _logger.i('Group updated successfully: ${group.name}');
      return true;
    } catch (e) {
      _logger.e('Error updating group: $e');
      _setError('Failed to update group: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteGroup(String groupId) async {
    try {
      _setLoading(true);
      _setError(null);
      
      // Get group info before deletion for history preservation
      final groupDoc = await _db.collection('groups').doc(groupId).get();
      final groupData = groupDoc.data();
      final groupName = groupData?['name'] ?? 'Deleted Group';
      
      // Get all expenses in the group for history preservation
      final expenseQuery = await _db
          .collection('groups')
          .doc(groupId)
          .collection('expenses')
          .get();
          
      // Get all settlements in the group for history preservation
      final settlementQuery = await _db
          .collection('groups')
          .doc(groupId)
          .collection('settlements')
          .get();
      
      final batch = _db.batch();
      
      // Move expenses to permanent history instead of deleting
      for (final doc in expenseQuery.docs) {
        final expenseData = doc.data();
        // Mark as deleted but preserve for history
        expenseData['deletedAt'] = DateTime.now().toIso8601String();
        expenseData['deletedGroupId'] = groupId;
        expenseData['deletedGroupName'] = groupName;
        expenseData['isDeleted'] = true;
        
        // Add to permanent history collection
        batch.set(
          _db.collection('expense_history').doc(doc.id),
          expenseData
        );
        
        // Delete from active collections
        batch.delete(doc.reference);
        batch.delete(_db.collection('expenses').doc(doc.id));
      }
      
      // Move settlements to permanent history instead of deleting
      for (final doc in settlementQuery.docs) {
        final settlementData = doc.data();
        // Mark as deleted but preserve for history
        settlementData['deletedAt'] = DateTime.now().toIso8601String();
        settlementData['deletedGroupId'] = groupId;
        settlementData['deletedGroupName'] = groupName;
        settlementData['isDeleted'] = true;
        
        // Add to permanent history collection
        batch.set(
          _db.collection('settlement_history').doc(doc.id),
          settlementData
        );
        
        // Delete from active collections
        batch.delete(doc.reference);
        batch.delete(_db.collection('settlements').doc(doc.id));
      }
      
      // Delete the group itself
      batch.delete(_db.collection('groups').doc(groupId));
      
      await batch.commit();
      
      _logger.i('Group deleted successfully: $groupId (history preserved)');
      return true;
    } catch (e) {
      _logger.e('Error deleting group: $e');
      _setError('Failed to delete group');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> removeMemberFromGroup(String groupId, String memberId) async {
    try {
      _setLoading(true);
      _setError(null);
      
      final groupRef = _db.collection('groups').doc(groupId);
      final groupDoc = await groupRef.get();
      
      if (!groupDoc.exists) {
        _setError('Group not found');
        return false;
      }
      
      final groupData = groupDoc.data()!;
      final List<String> currentMembers = List<String>.from(groupData['members'] ?? []);
      final Map<String, String> currentMemberNames = Map<String, String>.from(groupData['memberNames'] ?? {});
      
      // Remove member from both lists
      currentMembers.remove(memberId);
      currentMemberNames.remove(memberId);
      
      // Update the group document using merge to avoid overwriting unrelated fields
      await groupRef.set({
        'members': currentMembers,
        'memberNames': currentMemberNames,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      
      _logger.i('Member removed successfully from group: $memberId');
      return true;
    } catch (e) {
      _logger.e('Error removing member from group: $e');
      _setError('Failed to remove member from group: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addMemberToGroup(String groupId, String memberId, String memberName) async {
    try {
      _setLoading(true);
      _setError(null);
      
      final groupRef = _db.collection('groups').doc(groupId);
      final groupDoc = await groupRef.get();
      
      if (!groupDoc.exists) {
        _setError('Group not found');
        return false;
      }
      
      final groupData = groupDoc.data()!;
      final List<String> currentMembers = List<String>.from(groupData['members'] ?? []);
      final Map<String, String> currentMemberNames = Map<String, String>.from(groupData['memberNames'] ?? {});
      
      // Add member if not already present
      if (!currentMembers.contains(memberId)) {
        currentMembers.add(memberId);
        currentMemberNames[memberId] = memberName;
        
        // Update the group document using merge to avoid overwriting unrelated fields
        await groupRef.set({
          'members': currentMembers,
          'memberNames': currentMemberNames,
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }
      
      _logger.i('Member added successfully to group: $memberId');
      return true;
    } catch (e) {
      _logger.e('Error adding member to group: $e');
      _setError('Failed to add member to group: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Stream<List<GroupModel>> getUserGroups(String userId) {
    try {
      return _db
          .collection('groups')
          .where('members', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) {
                  try {
                    return GroupModel.fromMap({
                      'id': doc.id,
                      ...doc.data(),
                    });
                  } catch (e) {
                    _logger.e('Error parsing group ${doc.id}: $e');
                    return null;
                  }
                })
                .where((group) => group != null)
                .cast<GroupModel>()
                .toList();
          });
    } catch (e) {
      _logger.e('Error getting user groups: $e');
      return Stream.value([]);
    }
  }

  Stream<List<ExpenseModel>> getGroupExpenses(String groupId) {
    try {
      return _db
          .collection('expenses')
          .where('groupId', isEqualTo: groupId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) {
                  try {
                    return ExpenseModel.fromMap({
                      'id': doc.id,
                      ...doc.data(),
                    });
                  } catch (e) {
                    _logger.e('Error parsing expense ${doc.id}: $e');
                    return null;
                  }
                })
                .where((expense) => expense != null)
                .cast<ExpenseModel>()
                .toList();
          });
    } catch (e) {
      _logger.e('Error getting group expenses: $e');
      return Stream.value([]);
    }
  }

  Stream<List<SettlementModel>> getGroupSettlements(String groupId) {
    try {
      return _db
          .collection('settlements')
          .where('groupId', isEqualTo: groupId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) {
                  try {
                    return SettlementModel.fromMap({
                      'id': doc.id,
                      ...doc.data(),
                    });
                  } catch (e) {
                    _logger.e('Error parsing settlement ${doc.id}: $e');
                    return null;
                  }
                })
                .where((settlement) => settlement != null)
                .cast<SettlementModel>()
                .toList();
          });
    } catch (e) {
      _logger.e('Error getting group settlements: $e');
      return Stream.value([]);
    }
  }

  Future<GroupModel?> getGroup(String groupId) async {
    try {
      final doc = await _db.collection('groups').doc(groupId).get();
      
      if (doc.exists) {
        return GroupModel.fromMap({
          'id': doc.id,
          ...doc.data()!,
        });
      }
      return null;
    } catch (e) {
      _logger.e('Error getting group: $e');
      return null;
    }
  }

  // ========== EXPENSE OPERATIONS ==========
  Future<bool> addExpense(ExpenseModel expense) async {
    try {
      _setLoading(true);
      _setError(null);
      
      // Add to main expenses collection for global queries
      await _db.collection('expenses').doc(expense.id).set(expense.toMap());
      
      // If it's a group expense, also add to group's subcollection
      if (expense.groupId.isNotEmpty) {
        await _db
            .collection('groups')
            .doc(expense.groupId)
            .collection('expenses')
            .doc(expense.id)
            .set(expense.toMap());
            
        // Update group's updatedAt timestamp
        await _db.collection('groups').doc(expense.groupId).update({
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      
      _logger.i('Expense added successfully: ${expense.description}');
      return true;
    } catch (e) {
      _logger.e('Error adding expense: $e');
      _setError('Failed to add expense');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateExpense(ExpenseModel expense) async {
    try {
      _setLoading(true);
      _setError(null);
      
      final updatedExpense = expense.copyWith(updatedAt: DateTime.now());
      
      // Update in main expenses collection
      await _db.collection('expenses').doc(expense.id).update(updatedExpense.toMap());
      
      // If it's a group expense, also update in group's subcollection
      if (expense.groupId.isNotEmpty) {
        await _db
            .collection('groups')
            .doc(expense.groupId)
            .collection('expenses')
            .doc(expense.id)
            .update(updatedExpense.toMap());
      }
          
      _logger.i('Expense updated successfully: ${expense.description}');
      return true;
    } catch (e) {
      _logger.e('Error updating expense: $e');
      _setError('Failed to update expense');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteExpense(String expenseId, [String? groupId]) async {
    try {
      _setLoading(true);
      _setError(null);
      
      // Get expense data before deletion for history preservation
      final expenseDoc = await _db.collection('expenses').doc(expenseId).get();
      final expenseData = expenseDoc.data();
      
      // Get group info if available
      String? groupName;
      if (groupId != null && groupId.isNotEmpty) {
        final groupDoc = await _db.collection('groups').doc(groupId).get();
        groupName = groupDoc.data()?['name'] ?? 'Unknown Group';
      }
      
      final batch = _db.batch();
      
      // Move expense to permanent history instead of deleting
      if (expenseData != null) {
        expenseData['deletedAt'] = DateTime.now().toIso8601String();
        expenseData['deletedGroupId'] = groupId;
        expenseData['deletedGroupName'] = groupName;
        expenseData['isDeleted'] = true;
        
        // Add to permanent history collection
        batch.set(
          _db.collection('expense_history').doc(expenseId),
          expenseData
        );
      }
      
      // Delete from main expenses collection
      batch.delete(_db.collection('expenses').doc(expenseId));
      
      // If it's a group expense, also delete from group's subcollection
      if (groupId != null && groupId.isNotEmpty) {
        batch.delete(_db
            .collection('groups')
            .doc(groupId)
            .collection('expenses')
            .doc(expenseId));
      }
      
      // Find and handle related settlements
      // Get all settlements that reference this expense
      final settlementQuery = await _db
          .collection('settlements')
          .where('relatedExpenseId', isEqualTo: expenseId)
          .get();
      
      for (final doc in settlementQuery.docs) {
        final settlementData = doc.data();
        // Mark settlement as cancelled due to expense deletion
        settlementData['status'] = 'cancelled';
        settlementData['cancelledAt'] = DateTime.now().toIso8601String();
        settlementData['cancelledReason'] = 'Expense deleted';
        settlementData['relatedExpenseId'] = expenseId;
        
        // Update settlement in both collections
        batch.update(_db.collection('settlements').doc(doc.id), settlementData);
        if (groupId != null && groupId.isNotEmpty) {
          batch.update(
            _db.collection('groups').doc(groupId).collection('settlements').doc(doc.id),
            settlementData
          );
        }
      }
      
      await batch.commit();
           
      _logger.i('Expense deleted successfully: $expenseId (history preserved)');
      return true;
    } catch (e) {
      _logger.e('Error deleting expense: $e');
      _setError('Failed to delete expense');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Stream<List<ExpenseModel>> getExpenses(String groupId) {
    try {
      return _db
          .collection('groups')
          .doc(groupId)
          .collection('expenses')
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) {
                  try {
                    return ExpenseModel.fromMap({
                      'id': doc.id,
                      ...doc.data(),
                    });
                  } catch (e) {
                    _logger.e('Error parsing expense ${doc.id}: $e');
                    return null;
                  }
                })
                .where((expense) => expense != null)
                .cast<ExpenseModel>()
                .toList();
          });
    } catch (e) {
      _logger.e('Error getting expenses: $e');
      return Stream.value([]);
    }
  }

  // Get all expenses (for home screen)
  Stream<List<ExpenseModel>> getAllExpenses() {
    try {
      return _db
          .collection('expenses')
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) {
                  try {
                    return ExpenseModel.fromMap({
                      'id': doc.id,
                      ...doc.data(),
                    });
                  } catch (e) {
                    _logger.e('Error parsing expense ${doc.id}: $e');
                    return null;
                  }
                })
                .where((expense) => expense != null)
                .cast<ExpenseModel>()
                .toList();
          });
    } catch (e) {
      _logger.e('Error getting all expenses: $e');
      return Stream.value([]);
    }
  }

  // ========== SETTLEMENT OPERATIONS ==========
  Future<bool> addSettlement(SettlementModel settlement) async {
    try {
      _setLoading(true);
      _setError(null);
      
      // Write to group subcollection
      await _db
          .collection('groups')
          .doc(settlement.groupId)
          .collection('settlements')
          .doc(settlement.id)
          .set(settlement.toMap());
      // Write to root collection for global queries/history
      await _db.collection('settlements').doc(settlement.id).set(settlement.toMap());
      // Touch group updatedAt to refresh streams ordering
      await _db.collection('groups').doc(settlement.groupId).update({
        'updatedAt': DateTime.now().toIso8601String(),
      });
          
      _logger.i('Settlement added successfully');
      return true;
    } catch (e) {
      _logger.e('Error adding settlement: $e');
      _setError('Failed to add settlement');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ========== TRANSACTION HISTORY OPERATIONS ==========
  
  /// Get all transaction history (expenses and settlements) for a user
  Stream<List<Map<String, dynamic>>> getTransactionHistory(String userId) {
    try {
      // Combine active and historical transactions
      return Rx.combineLatest3(
        _getActiveExpenses(userId),
        _getHistoricalExpenses(userId),
        _getHistoricalSettlements(userId),
        (List<ExpenseModel> activeExpenses, List<Map<String, dynamic>> historicalExpenses, List<Map<String, dynamic>> historicalSettlements) {
          final List<Map<String, dynamic>> allTransactions = [];
          
          // Add active expenses
          for (final expense in activeExpenses) {
            allTransactions.add({
              'id': expense.id,
              'type': 'expense',
              'description': expense.description,
              'amount': expense.amount,
              'date': expense.date,
              'groupId': expense.groupId,
              'payer': expense.payer,
              'payerName': expense.payerName,
              'isDeleted': false,
              'isHistorical': false,
            });
          }
          
          // Add historical expenses
          allTransactions.addAll(historicalExpenses.map((e) => {
            ...e,
            'type': 'expense',
            'isHistorical': true,
          }));
          
          // Add historical settlements
          allTransactions.addAll(historicalSettlements.map((s) => {
            ...s,
            'type': 'settlement',
            'isHistorical': true,
          }));
          
          // Sort by date (newest first)
          allTransactions.sort((a, b) {
            final dateA = a['date'] is String ? DateTime.parse(a['date']) : a['date'];
            final dateB = b['date'] is String ? DateTime.parse(b['date']) : b['date'];
            return dateB.compareTo(dateA);
          });
          
          return allTransactions;
        },
      );
    } catch (e) {
      _logger.e('Error getting transaction history: $e');
      return Stream.value([]);
    }
  }
  
  /// Get historical expenses for a user
  Stream<List<Map<String, dynamic>>> _getHistoricalExpenses(String userId) {
    try {
      return _db
          .collection('expense_history')
          .where('payer', isEqualTo: userId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => {
                  final data = doc.data();
                  data['id'] = doc.id;
                  return data;
                })
                .toList();
          });
    } catch (e) {
      _logger.e('Error getting historical expenses: $e');
      return Stream.value([]);
    }
  }
  
  /// Get historical settlements for a user
  Stream<List<Map<String, dynamic>>> _getHistoricalSettlements(String userId) {
    try {
      return _db
          .collection('settlement_history')
          .where('fromUser', isEqualTo: userId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => {
                  final data = doc.data();
                  data['id'] = doc.id;
                  return data;
                })
                .toList();
          });
    } catch (e) {
      _logger.e('Error getting historical settlements: $e');
      return Stream.value([]);
    }
  }
  
  /// Get active expenses for a user (for combining with history)
  Stream<List<ExpenseModel>> _getActiveExpenses(String userId) {
    try {
      return _db
          .collection('expenses')
          .where('payer', isEqualTo: userId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) {
                  try {
                    return ExpenseModel.fromMap({
                      'id': doc.id,
                      ...doc.data(),
                    });
                  } catch (e) {
                    _logger.e('Error parsing expense ${doc.id}: $e');
                    return null;
                  }
                })
                .where((expense) => expense != null)
                .cast<ExpenseModel>()
                .toList();
          });
    } catch (e) {
      _logger.e('Error getting active expenses: $e');
      return Stream.value([]);
    }
  }
  
  /// Get all settlements (active and historical) for a user
  Stream<List<SettlementModel>> getAllSettlementsForUser(String userId) {
    try {
      return Rx.combineLatest2(
        _getActiveSettlements(userId),
        _getHistoricalSettlementsForUser(userId),
        (List<SettlementModel> active, List<SettlementModel> historical) {
          final allSettlements = [...active, ...historical];
          allSettlements.sort((a, b) => b.date.compareTo(a.date));
          return allSettlements;
        },
      );
    } catch (e) {
      _logger.e('Error getting all settlements for user: $e');
      return Stream.value([]);
    }
  }
  
  /// Get active settlements for a user
  Stream<List<SettlementModel>> _getActiveSettlements(String userId) {
    try {
      return _db
          .collection('settlements')
          .where('fromUser', isEqualTo: userId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) {
                  try {
                    return SettlementModel.fromMap({
                      'id': doc.id,
                      ...doc.data(),
                    });
                  } catch (e) {
                    _logger.e('Error parsing settlement ${doc.id}: $e');
                    return null;
                  }
                })
                .where((settlement) => settlement != null)
                .cast<SettlementModel>()
                .toList();
          });
    } catch (e) {
      _logger.e('Error getting active settlements: $e');
      return Stream.value([]);
    }
  }
  
  /// Get historical settlements for a user
  Stream<List<SettlementModel>> _getHistoricalSettlementsForUser(String userId) {
    try {
      return _db
          .collection('settlement_history')
          .where('fromUser', isEqualTo: userId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) {
                  try {
                    return SettlementModel.fromMap({
                      'id': doc.id,
                      ...doc.data(),
                    });
                  } catch (e) {
                    _logger.e('Error parsing historical settlement ${doc.id}: $e');
                    return null;
                  }
                })
                .where((settlement) => settlement != null)
                .cast<SettlementModel>()
                .toList();
          });
    } catch (e) {
      _logger.e('Error getting historical settlements for user: $e');
      return Stream.value([]);
    }
  }

  Future<bool> updateSettlement(SettlementModel settlement) async {
    try {
      _setLoading(true);
      _setError(null);
      
      await _db
          .collection('groups')
          .doc(settlement.groupId)
          .collection('settlements')
          .doc(settlement.id)
          .update(settlement.copyWith(updatedAt: DateTime.now()).toMap());
          
      _logger.i('Settlement updated successfully');
      return true;
    } catch (e) {
      _logger.e('Error updating settlement: $e');
      _setError('Failed to update settlement');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Stream<List<SettlementModel>> getSettlements(String groupId) {
    try {
      return _db
          .collection('groups')
          .doc(groupId)
          .collection('settlements')
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) {
                  try {
                    return SettlementModel.fromMap({
infectar.artifactId: doc.id,
                      ...doc.data(),
                    });
                  } catch (e) {
                    _logger.e('Error parsing settlement ${doc.id}: $e');
                    return null;
                  }
                })
                .where((settlement) => settlement != null)
                .cast<SettlementModel>()
                .toList();
          });
    } catch (e) {
      _logger.e('Error getting settlements: $e');
      return Stream.value([]);
    }
  }

  // ========== CALCULATION METHODS ==========
  Map<String, double> calculateBalances(List<ExpenseModel> expenses) {
    final Map<String, double> balances = {};
    
    for (final expense in expenses) {
      // Add amount paid by payer
      balances[expense.payer] = (balances[expense.payer] ?? 0) + expense.amount;
      
      // Subtract splits for each member
      expense.split.forEach((userId, amount) {
        balances[userId] = (balances[userId] ?? 0) - amount;
      });
    }
    
    return balances;
  }

  List<Map<String, dynamic>> calculateSettlements(Map<String, double> balances) {
    final List<Map<String, dynamic>> settlements = [];
    final creditors = <String, double>{};
    final debtors = <String, double>{};
    
    // Separate creditors and debtors
    balances.forEach((userId, balance) {
      if (balance > 0.01) { // Creditor (someone owes them)
        creditors[userId] = balance;
      } else if (balance < -0.01) { // Debtor (they owe someone)
        debtors[userId] = -balance;
      }
    });
    
    // Calculate optimal settlements
    final creditorList = creditors.entries.toList();
    final debtorList = debtors.entries.toList();
    
    int i = 0, j = 0;
    while (i < creditorList.length && j < debtorList.length) {
      final creditor = creditorList[i];
      final debtor = debtorList[j];
      
      final amount = [creditor.value, debtor.value].reduce((a, b) => a < b ? a : b);
      
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
}