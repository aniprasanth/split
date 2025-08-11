import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitzy/models/expense_model.dart';
import 'package:splitzy/models/group_model.dart';
import 'package:splitzy/models/settlement_model.dart';
import 'package:splitzy/services/cache_service.dart';
import 'package:splitzy/services/calculation_isolates.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';

/// Optimized data service for improved sync performance
class OptimizedDataService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CacheService _cacheService;
  final Logger _logger = Logger();

  bool _isLoading = false;
  String? _errorMessage;

  // Stream controllers for optimized data flow
  final BehaviorSubject<List<ExpenseModel>> _expensesSubject = BehaviorSubject<List<ExpenseModel>>();
  final BehaviorSubject<List<GroupModel>> _groupsSubject = BehaviorSubject<List<GroupModel>>();
  final BehaviorSubject<List<SettlementModel>> _settlementsSubject = BehaviorSubject<List<SettlementModel>>();
  final BehaviorSubject<Map<String, dynamic>> _calculationsSubject = BehaviorSubject<Map<String, dynamic>>();

  // Streams
  Stream<List<ExpenseModel>> get expensesStream => _expensesSubject.stream;
  Stream<List<GroupModel>> get groupsStream => _groupsSubject.stream;
  Stream<List<SettlementModel>> get settlementsStream => _settlementsSubject.stream;
  Stream<Map<String, dynamic>> get calculationsStream => _calculationsSubject.stream;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ExpenseModel> get currentExpenses => _expensesSubject.valueOrNull ?? [];
  List<GroupModel> get currentGroups => _groupsSubject.valueOrNull ?? [];
  List<SettlementModel> get currentSettlements => _settlementsSubject.valueOrNull ?? [];

  OptimizedDataService(this._cacheService) {
    _initializeData();
  }

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

  /// Initialize data streams with caching
  Future<void> _initializeData() async {
    try {
      _setLoading(true);
      
      // Load cached data first for immediate UI response
      final cachedExpenses = _cacheService.getCachedExpenses('all_expenses');
      if (cachedExpenses != null) {
        _expensesSubject.add(cachedExpenses);
      }

      final cachedGroups = _cacheService.getCachedGroups('all_groups');
      if (cachedGroups != null) {
        _groupsSubject.add(cachedGroups);
      }

      // Start listening to real-time updates
      _listenToExpenses();
      _listenToGroups();
      
    } catch (e) {
      _logger.e('Error initializing data: $e');
      _setError('Failed to initialize data');
    } finally {
      _setLoading(false);
    }
  }

  /// Listen to expenses with caching
  void _listenToExpenses() {
    _db
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        try {
          final expenses = snapshot.docs
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

          // Cache the data
          _cacheService.cacheExpenses('all_expenses', expenses);
          
          // Update stream
          _expensesSubject.add(expenses);
          
          _logger.d('Expenses updated: ${expenses.length} items');
        } catch (e) {
          _logger.e('Error processing expenses: $e');
        }
      },
      onError: (e) {
        _logger.e('Error listening to expenses: $e');
        _setError('Failed to load expenses');
      },
    );
  }

  /// Listen to groups with caching
  void _listenToGroups() {
    _db
        .collection('groups')
        .where('isActive', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        try {
          final groups = snapshot.docs
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

          // Cache the data
          _cacheService.cacheGroups('all_groups', groups);
          
          // Update stream
          _groupsSubject.add(groups);
          
          _logger.d('Groups updated: ${groups.length} items');
        } catch (e) {
          _logger.e('Error processing groups: $e');
        }
      },
      onError: (e) {
        _logger.e('Error listening to groups: $e');
        _setError('Failed to load groups');
      },
    );
  }

  /// Get user groups with caching
  Stream<List<GroupModel>> getUserGroups(String userId) {
    final cacheKey = 'user_groups_$userId';
    
    // Check cache first
    final cachedGroups = _cacheService.getCachedGroups(cacheKey);
    if (cachedGroups != null) {
      return Stream.value(cachedGroups);
    }

    // If not cached, filter from main stream and cache
    return _groupsSubject.stream.map((allGroups) {
      final userGroups = allGroups.where((group) => group.members.contains(userId)).toList();
      _cacheService.cacheGroups(cacheKey, userGroups);
      return userGroups;
    });
  }

  /// Get user settlements with caching
  Stream<List<SettlementModel>> getUserSettlements(String userId) {
    final cacheKey = 'user_settlements_$userId';
    
    // Check cache first
    final cachedSettlements = _cacheService.getCachedSettlements(cacheKey);
    if (cachedSettlements != null) {
      return Stream.value(cachedSettlements);
    }

    // If not cached, fetch and cache
    return _db
        .collection('settlements')
        .where('fromUser', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .asyncMap((fromUserSnapshot) async {
          final toUserSnapshot = await _db
              .collection('settlements')
              .where('toUser', isEqualTo: userId)
              .orderBy('date', descending: true)
              .get();

          final allDocs = [...fromUserSnapshot.docs, ...toUserSnapshot.docs];
          
          final settlements = allDocs
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

          _cacheService.cacheSettlements(cacheKey, settlements);
          return settlements;
        });
  }

  /// Optimized settlement calculation with caching
  Future<Map<String, dynamic>> calculateSettlementsOptimized(
    String userId,
    List<ExpenseModel> expenses,
    List<SettlementModel> settlements,
    Map<String, GroupModel> groups,
  ) async {
    final cacheKey = 'settlement_calc_${userId}_${expenses.length}_${settlements.length}';
    
    // Check cache first
    final cachedResult = _cacheService.getCachedCalculation(cacheKey);
    if (cachedResult != null) {
      return cachedResult;
    }

    // Calculate if not cached
    final result = await _calculateSettlementsWithHistoryAsync(
      expenses,
      settlements,
      userId,
      groups,
    );

    // Cache the result
    _cacheService.cacheCalculation(cacheKey, result);
    
    return result;
  }

  /// Add expense with optimistic update
  Future<bool> addExpenseOptimized(ExpenseModel expense) async {
    try {
      // Optimistic update
      final currentExpenses = List<ExpenseModel>.from(_expensesSubject.valueOrNull ?? []);
      currentExpenses.insert(0, expense);
      _expensesSubject.add(currentExpenses);

      // Invalidate related caches
      _cacheService.invalidateRelatedCaches(
        'expense_added',
        groupId: expense.groupId,
        userId: expense.payer,
      );

      // Actual database write
      await _db.collection('expenses').doc(expense.id).set(expense.toMap());

      _logger.i('Expense added successfully with optimistic update');
      return true;
    } catch (e) {
      // Revert optimistic update on error
      final currentExpenses = List<ExpenseModel>.from(_expensesSubject.valueOrNull ?? []);
      currentExpenses.removeWhere((e) => e.id == expense.id);
      _expensesSubject.add(currentExpenses);

      _logger.e('Error adding expense: $e');
      _setError('Failed to add expense');
      return false;
    }
  }

  /// Add settlement with optimistic update
  Future<bool> addSettlementOptimized(SettlementModel settlement) async {
    try {
      // Optimistic update
      final currentSettlements = List<SettlementModel>.from(_settlementsSubject.valueOrNull ?? []);
      currentSettlements.insert(0, settlement);
      _settlementsSubject.add(currentSettlements);

      // Invalidate related caches
      _cacheService.invalidateRelatedCaches(
        'settlement_added',
        groupId: settlement.groupId,
        userId: settlement.fromUser,
      );

      // Actual database write
      await _db
          .collection('groups')
          .doc(settlement.groupId)
          .collection('settlements')
          .doc(settlement.id)
          .set(settlement.toMap());
      
      await _db.collection('settlements').doc(settlement.id).set(settlement.toMap());

      _logger.i('Settlement added successfully with optimistic update');
      return true;
    } catch (e) {
      // Revert optimistic update on error
      final currentSettlements = List<SettlementModel>.from(_settlementsSubject.valueOrNull ?? []);
      currentSettlements.removeWhere((s) => s.id == settlement.id);
      _settlementsSubject.add(currentSettlements);

      _logger.e('Error adding settlement: $e');
      _setError('Failed to add settlement');
      return false;
    }
  }

  /// Get paginated expenses for better performance
  Stream<List<ExpenseModel>> getPaginatedExpenses({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) {
    Query query = _db
        .collection('expenses')
        .orderBy('date', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots().map((snapshot) {
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
  }

  /// Clear all data and caches
  void clearAllData() {
    _expensesSubject.add([]);
    _groupsSubject.add([]);
    _settlementsSubject.add([]);
    _calculationsSubject.add({});
    _cacheService.invalidateAllCaches();
  }

  @override
  void dispose() {
    _expensesSubject.close();
    _groupsSubject.close();
    _settlementsSubject.close();
    _calculationsSubject.close();
    super.dispose();
  }
}
