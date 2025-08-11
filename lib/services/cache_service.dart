import 'package:flutter/foundation.dart';
import 'package:splitzy/models/expense_model.dart';
import 'package:splitzy/models/group_model.dart';
import 'package:splitzy/models/settlement_model.dart';
import 'package:logger/logger.dart';

/// Cache service for improving data sync performance
class CacheService extends ChangeNotifier {
  final Logger _logger = Logger();
  
  // Cache storage
  final Map<String, List<ExpenseModel>> _expenseCache = {};
  final Map<String, List<GroupModel>> _groupCache = {};
  final Map<String, List<SettlementModel>> _settlementCache = {};
  final Map<String, Map<String, dynamic>> _calculationCache = {};
  
  // Cache timestamps for TTL
  final Map<String, DateTime> _cacheTimestamps = {};
  
  // Cache TTL (5 minutes)
  static const Duration _cacheTTL = Duration(minutes: 5);
  
  // Cache keys
  static const String _allExpensesKey = 'all_expenses';
  static const String _userGroupsKey = 'user_groups';
  static const String _userSettlementsKey = 'user_settlements';
  static const String _groupExpensesKey = 'group_expenses';
  static const String _groupSettlementsKey = 'group_settlements';
  
  /// Get cached expenses or null if not cached/expired
  List<ExpenseModel>? getCachedExpenses(String key) {
    return _getCachedData(_expenseCache, key);
  }
  
  /// Get cached groups or null if not cached/expired
  List<GroupModel>? getCachedGroups(String key) {
    return _getCachedData(_groupCache, key);
  }
  
  /// Get cached settlements or null if not cached/expired
  List<SettlementModel>? getCachedSettlements(String key) {
    return _getCachedData(_settlementCache, key);
  }
  
  /// Get cached calculation result or null if not cached/expired
  Map<String, dynamic>? getCachedCalculation(String key) {
    return _getCachedData(_calculationCache, key);
  }
  
  /// Cache expenses
  void cacheExpenses(String key, List<ExpenseModel> expenses) {
    _cacheData(_expenseCache, key, expenses);
  }
  
  /// Cache groups
  void cacheGroups(String key, List<GroupModel> groups) {
    _cacheData(_groupCache, key, groups);
  }
  
  /// Cache settlements
  void cacheSettlements(String key, List<SettlementModel> settlements) {
    _cacheData(_settlementCache, key, settlements);
  }
  
  /// Cache calculation result
  void cacheCalculation(String key, Map<String, dynamic> result) {
    _cacheData(_calculationCache, key, result);
  }
  
  /// Invalidate cache for a specific key
  void invalidateCache(String key) {
    _expenseCache.remove(key);
    _groupCache.remove(key);
    _settlementCache.remove(key);
    _calculationCache.remove(key);
    _cacheTimestamps.remove(key);
    _logger.d('Cache invalidated for key: $key');
  }
  
  /// Invalidate all caches
  void invalidateAllCaches() {
    _expenseCache.clear();
    _groupCache.clear();
    _settlementCache.clear();
    _calculationCache.clear();
    _cacheTimestamps.clear();
    _logger.d('All caches invalidated');
  }
  
  /// Invalidate related caches when data changes
  void invalidateRelatedCaches(String operation, {String? groupId, String? userId}) {
    switch (operation) {
      case 'expense_added':
      case 'expense_updated':
      case 'expense_deleted':
        invalidateCache(_allExpensesKey);
        if (groupId != null) {
          invalidateCache('${_groupExpensesKey}_$groupId');
        }
        if (userId != null) {
          invalidateCache('${_userGroupsKey}_$userId');
        }
        // Invalidate all calculation caches
        _calculationCache.clear();
        break;
        
      case 'settlement_added':
      case 'settlement_updated':
        invalidateCache(_allExpensesKey);
        if (groupId != null) {
          invalidateCache('${_groupSettlementsKey}_$groupId');
        }
        if (userId != null) {
          invalidateCache('${_userSettlementsKey}_$userId');
        }
        // Invalidate all calculation caches
        _calculationCache.clear();
        break;
        
      case 'group_updated':
      case 'group_deleted':
        if (userId != null) {
          invalidateCache('${_userGroupsKey}_$userId');
        }
        if (groupId != null) {
          invalidateCache('${_groupExpensesKey}_$groupId');
          invalidateCache('${_groupSettlementsKey}_$groupId');
        }
        break;
        
      case 'member_added':
      case 'member_removed':
        if (groupId != null) {
          invalidateCache('${_groupExpensesKey}_$groupId');
          invalidateCache('${_groupSettlementsKey}_$groupId');
        }
        break;
    }
  }
  
  /// Get cached data with TTL check
  T? _getCachedData<T>(Map<String, T> cache, String key) {
    final data = cache[key];
    if (data == null) return null;
    
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return null;
    
    if (DateTime.now().difference(timestamp) > _cacheTTL) {
      // Cache expired
      cache.remove(key);
      _cacheTimestamps.remove(key);
      _logger.d('Cache expired for key: $key');
      return null;
    }
    
    _logger.d('Cache hit for key: $key');
    return data;
  }
  
  /// Cache data with timestamp
  void _cacheData<T>(Map<String, T> cache, String key, T data) {
    cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
    _logger.d('Data cached for key: $key');
  }
  
  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'expense_cache_size': _expenseCache.length,
      'group_cache_size': _groupCache.length,
      'settlement_cache_size': _settlementCache.length,
      'calculation_cache_size': _calculationCache.length,
      'total_cached_items': _cacheTimestamps.length,
    };
  }
  
  /// Clear expired caches
  void clearExpiredCaches() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheTTL) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      invalidateCache(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      _logger.d('Cleared ${expiredKeys.length} expired cache entries');
    }
  }
}
