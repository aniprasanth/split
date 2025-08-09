import 'package:hive_flutter/hive_flutter.dart';
import 'package:splitzy/models/group_model.dart';
import 'package:splitzy/models/expense_model.dart';
import 'package:splitzy/models/user_model.dart';
import 'package:splitzy/models/settlement_model.dart';
import 'package:logger/logger.dart';

class LocalStorageService {
  static const String _settingsBox = 'settings';
  static const String _groupsBox = 'groups';
  static const String _expensesBox = 'expenses';
  static const String _usersBox = 'users';
  static const String _settlementsBox = 'settlements';
  static const String _cacheBox = 'cache';

  static final Logger _logger = Logger();

  // Box instances
  static Box? _settingsBoxInstance;
  static Box? _groupsBoxInstance;
  static Box? _expensesBoxInstance;
  static Box? _usersBoxInstance;
  static Box? _settlementsBoxInstance;
  static Box? _cacheBoxInstance;

  /// Initialize Hive and open all boxes
  static Future<void> initialize() async {
    try {
      // Initialize Hive
      await Hive.initFlutter();
      
      // Register adapters if you have custom objects
      // Hive.registerAdapter(GroupModelAdapter());
      // Hive.registerAdapter(ExpenseModelAdapter());
      // Hive.registerAdapter(UserModelAdapter());
      // Hive.registerAdapter(SettlementModelAdapter());
      
      // Open boxes
      _settingsBoxInstance = await Hive.openBox(_settingsBox);
      _groupsBoxInstance = await Hive.openBox(_groupsBox);
      _expensesBoxInstance = await Hive.openBox(_expensesBox);
      _usersBoxInstance = await Hive.openBox(_usersBox);
      _settlementsBoxInstance = await Hive.openBox(_settlementsBox);
      _cacheBoxInstance = await Hive.openBox(_cacheBox);
      
      _logger.i('Local storage initialized successfully');
    } catch (e) {
      _logger.e('Error initializing local storage: $e');
      rethrow;
    }
  }

  /// Close all boxes
  static Future<void> close() async {
    try {
      await _settingsBoxInstance?.close();
      await _groupsBoxInstance?.close();
      await _expensesBoxInstance?.close();
      await _usersBoxInstance?.close();
      await _settlementsBoxInstance?.close();
      await _cacheBoxInstance?.close();
      
      _logger.i('Local storage closed successfully');
    } catch (e) {
      _logger.e('Error closing local storage: $e');
    }
  }

  /// Clear all data
  static Future<void> clearAll() async {
    try {
      await _settingsBoxInstance?.clear();
      await _groupsBoxInstance?.clear();
      await _expensesBoxInstance?.clear();
      await _usersBoxInstance?.clear();
      await _settlementsBoxInstance?.clear();
      await _cacheBoxInstance?.clear();
      
      _logger.i('All local storage cleared');
    } catch (e) {
      _logger.e('Error clearing local storage: $e');
    }
  }

  // ========== THEME SETTINGS ==========
  
  /// Save theme preference
  static Future<void> saveTheme(bool isDark) async {
    try {
      await _settingsBoxInstance?.put('darkMode', isDark);
      _logger.d('Theme saved: isDark = $isDark');
    } catch (e) {
      _logger.e('Error saving theme: $e');
    }
  }

  /// Load theme preference
  static Future<bool> loadTheme() async {
    try {
      final isDark = _settingsBoxInstance?.get('darkMode', defaultValue: false) ?? false;
      _logger.d('Theme loaded: isDark = $isDark');
      return isDark;
    } catch (e) {
      _logger.e('Error loading theme: $e');
      return false;
    }
  }

  // ========== USER PREFERENCES ==========
  
  /// Save user preferences
  static Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    try {
      await _settingsBoxInstance?.put('userPreferences', preferences);
      _logger.d('User preferences saved');
    } catch (e) {
      _logger.e('Error saving user preferences: $e');
    }
  }

  /// Load user preferences
  static Future<Map<String, dynamic>> loadUserPreferences() async {
    try {
      final prefs = _settingsBoxInstance?.get('userPreferences', defaultValue: <String, dynamic>{}) ?? <String, dynamic>{};
      _logger.d('User preferences loaded');
      return Map<String, dynamic>.from(prefs);
    } catch (e) {
      _logger.e('Error loading user preferences: $e');
      return <String, dynamic>{};
    }
  }

  /// Save notification settings
  static Future<void> saveNotificationSettings({
    bool? expenseAdded,
    bool? settlementAdded,
    bool? groupInvite,
    bool? reminderNotifications,
  }) async {
    try {
      final settings = {
        'expenseAdded': expenseAdded ?? true,
        'settlementAdded': settlementAdded ?? true,
        'groupInvite': groupInvite ?? true,
        'reminderNotifications': reminderNotifications ?? true,
      };
      await _settingsBoxInstance?.put('notificationSettings', settings);
      _logger.d('Notification settings saved');
    } catch (e) {
      _logger.e('Error saving notification settings: $e');
    }
  }

  /// Load notification settings
  static Future<Map<String, bool>> loadNotificationSettings() async {
    try {
      final settings = _settingsBoxInstance?.get('notificationSettings', defaultValue: {
        'expenseAdded': true,
        'settlementAdded': true,
        'groupInvite': true,
        'reminderNotifications': true,
      }) ?? {};
      
      return Map<String, bool>.from(settings);
    } catch (e) {
      _logger.e('Error loading notification settings: $e');
      return {
        'expenseAdded': true,
        'settlementAdded': true,
        'groupInvite': true,
        'reminderNotifications': true,
      };
    }
  }

  // ========== OFFLINE DATA CACHING ==========
  
  /// Cache groups for offline access
  static Future<void> cacheGroups(List<GroupModel> groups) async {
    try {
      final groupMaps = groups.map((group) => group.toMap()).toList();
      await _groupsBoxInstance?.put('cachedGroups', groupMaps);
      await _cacheBoxInstance?.put('groupsLastUpdated', DateTime.now().toIso8601String());
      _logger.d('${groups.length} groups cached');
    } catch (e) {
      _logger.e('Error caching groups: $e');
    }
  }

  /// Get cached groups
  static Future<List<GroupModel>> getCachedGroups() async {
    try {
      final cachedData = _groupsBoxInstance?.get('cachedGroups', defaultValue: []) ?? [];
      final groups = (cachedData as List).map((data) => GroupModel.fromMap(Map<String, dynamic>.from(data))).toList();
      _logger.d('${groups.length} cached groups retrieved');
      return groups;
    } catch (e) {
      _logger.e('Error getting cached groups: $e');
      return [];
    }
  }

  /// Cache expenses for offline access
  static Future<void> cacheExpenses(String groupId, List<ExpenseModel> expenses) async {
    try {
      final expenseMaps = expenses.map((expense) => expense.toMap()).toList();
      await _expensesBoxInstance?.put('expenses_$groupId', expenseMaps);
      await _cacheBoxInstance?.put('expenses_${groupId}_lastUpdated', DateTime.now().toIso8601String());
      _logger.d('${expenses.length} expenses cached for group $groupId');
    } catch (e) {
      _logger.e('Error caching expenses: $e');
    }
  }

  /// Get cached expenses
  static Future<List<ExpenseModel>> getCachedExpenses(String groupId) async {
    try {
      final cachedData = _expensesBoxInstance?.get('expenses_$groupId', defaultValue: []) ?? [];
      final expenses = (cachedData as List).map((data) => ExpenseModel.fromMap(Map<String, dynamic>.from(data))).toList();
      _logger.d('${expenses.length} cached expenses retrieved for group $groupId');
      return expenses;
    } catch (e) {
      _logger.e('Error getting cached expenses: $e');
      return [];
    }
  }

  /// Cache user data
  static Future<void> cacheUsers(List<SplitzyUser> users) async {
    try {
      final userMaps = <String, Map<String, dynamic>>{};
      for (final user in users) {
        userMaps[user.uid] = user.toMap();
      }
      await _usersBoxInstance?.put('cachedUsers', userMaps);
      _logger.d('${users.length} users cached');
    } catch (e) {
      _logger.e('Error caching users: $e');
    }
  }

  /// Get cached user
  static Future<SplitzyUser?> getCachedUser(String userId) async {
    try {
      final cachedUsers = _usersBoxInstance?.get('cachedUsers', defaultValue: <String, dynamic>{}) ?? <String, dynamic>{};
      final userData = cachedUsers[userId];
      if (userData != null) {
        return SplitzyUser.fromMap(Map<String, dynamic>.from(userData));
      }
      return null;
    } catch (e) {
      _logger.e('Error getting cached user: $e');
      return null;
    }
  }

  /// Cache settlements
  static Future<void> cacheSettlements(String groupId, List<SettlementModel> settlements) async {
    try {
      final settlementMaps = settlements.map((settlement) => settlement.toMap()).toList();
      await _settlementsBoxInstance?.put('settlements_$groupId', settlementMaps);
      await _cacheBoxInstance?.put('settlements_${groupId}_lastUpdated', DateTime.now().toIso8601String());
      _logger.d('${settlements.length} settlements cached for group $groupId');
    } catch (e) {
      _logger.e('Error caching settlements: $e');
    }
  }

  /// Get cached settlements
  static Future<List<SettlementModel>> getCachedSettlements(String groupId) async {
    try {
      final cachedData = _settlementsBoxInstance?.get('settlements_$groupId', defaultValue: []) ?? [];
      final settlements = (cachedData as List).map((data) => SettlementModel.fromMap(Map<String, dynamic>.from(data))).toList();
      _logger.d('${settlements.length} cached settlements retrieved for group $groupId');
      return settlements;
    } catch (e) {
      _logger.e('Error getting cached settlements: $e');
      return [];
    }
  }

  // ========== APP DATA ==========
  
  /// Save last sync timestamp
  static Future<void> saveLastSyncTime(DateTime syncTime) async {
    try {
      await _cacheBoxInstance?.put('lastSyncTime', syncTime.toIso8601String());
      _logger.d('Last sync time saved: $syncTime');
    } catch (e) {
      _logger.e('Error saving last sync time: $e');
    }
  }

  /// Get last sync timestamp
  static Future<DateTime?> getLastSyncTime() async {
    try {
      final timeString = _cacheBoxInstance?.get('lastSyncTime');
      if (timeString != null) {
        return DateTime.parse(timeString);
      }
      return null;
    } catch (e) {
      _logger.e('Error getting last sync time: $e');
      return null;
    }
  }

  /// Save app version
  static Future<void> saveAppVersion(String version) async {
    try {
      await _settingsBoxInstance?.put('appVersion', version);
      _logger.d('App version saved: $version');
    } catch (e) {
      _logger.e('Error saving app version: $e');
    }
  }

  /// Get app version
  static Future<String?> getAppVersion() async {
    try {
      return _settingsBoxInstance?.get('appVersion');
    } catch (e) {
      _logger.e('Error getting app version: $e');
      return null;
    }
  }

  /// Save onboarding completion status
  static Future<void> saveOnboardingCompleted(bool completed) async {
    try {
      await _settingsBoxInstance?.put('onboardingCompleted', completed);
      _logger.d('Onboarding completion status saved: $completed');
    } catch (e) {
      _logger.e('Error saving onboarding status: $e');
    }
  }

  /// Check if onboarding is completed
  static Future<bool> isOnboardingCompleted() async {
    try {
      return _settingsBoxInstance?.get('onboardingCompleted', defaultValue: false) ?? false;
    } catch (e) {
      _logger.e('Error checking onboarding status: $e');
      return false;
    }
  }

  // ========== BIOMETRIC SETTINGS ==========
  
  /// Save biometric authentication preference
  static Future<void> saveBiometricEnabled(bool enabled) async {
    try {
      await _settingsBoxInstance?.put('biometricEnabled', enabled);
      _logger.d('Biometric enabled status saved: $enabled');
    } catch (e) {
      _logger.e('Error saving biometric status: $e');
    }
  }

  /// Check if biometric authentication is enabled
  static Future<bool> isBiometricEnabled() async {
    try {
      return _settingsBoxInstance?.get('biometricEnabled', defaultValue: false) ?? false;
    } catch (e) {
      _logger.e('Error checking biometric status: $e');
      return false;
    }
  }

  // ========== CURRENCY SETTINGS ==========
  
  /// Save default currency
  static Future<void> saveDefaultCurrency(String currencyCode) async {
    try {
      await _settingsBoxInstance?.put('defaultCurrency', currencyCode);
      _logger.d('Default currency saved: $currencyCode');
    } catch (e) {
      _logger.e('Error saving default currency: $e');
    }
  }

  /// Get default currency
  static Future<String> getDefaultCurrency() async {
    try {
      return _settingsBoxInstance?.get('defaultCurrency', defaultValue: 'INR') ?? 'INR';
    } catch (e) {
      _logger.e('Error getting default currency: $e');
      return 'INR';
    }
  }

  // ========== RECENT DATA ==========
  
  /// Save recent expense categories
  static Future<void> saveRecentCategories(List<String> categories) async {
    try {
      await _cacheBoxInstance?.put('recentCategories', categories);
      _logger.d('Recent categories saved: ${categories.length} items');
    } catch (e) {
      _logger.e('Error saving recent categories: $e');
    }
  }

  /// Get recent expense categories
  static Future<List<String>> getRecentCategories() async {
    try {
      final categories = _cacheBoxInstance?.get('recentCategories', defaultValue: <String>[]) ?? <String>[];
      return List<String>.from(categories);
    } catch (e) {
      _logger.e('Error getting recent categories: $e');
      return [];
    }
  }

  /// Save recent payees
  static Future<void> saveRecentPayees(List<String> payees) async {
    try {
      await _cacheBoxInstance?.put('recentPayees', payees);
      _logger.d('Recent payees saved: ${payees.length} items');
    } catch (e) {
      _logger.e('Error saving recent payees: $e');
    }
  }

  /// Get recent payees
  static Future<List<String>> getRecentPayees() async {
    try {
      final payees = _cacheBoxInstance?.get('recentPayees', defaultValue: <String>[]) ?? <String>[];
      return List<String>.from(payees);
    } catch (e) {
      _logger.e('Error getting recent payees: $e');
      return [];
    }
  }

  // ========== BACKUP & RESTORE ==========
  
  /// Create a backup of all local data
  static Future<Map<String, dynamic>> createBackup() async {
    try {
      final backup = <String, dynamic>{};
      
      // Settings
      if (_settingsBoxInstance != null) {
        backup['settings'] = Map<String, dynamic>.from(_settingsBoxInstance!.toMap());
      }
      
      // Groups
      if (_groupsBoxInstance != null) {
        backup['groups'] = Map<String, dynamic>.from(_groupsBoxInstance!.toMap());
      }
      
      // Expenses
      if (_expensesBoxInstance != null) {
        backup['expenses'] = Map<String, dynamic>.from(_expensesBoxInstance!.toMap());
      }
      
      // Users
      if (_usersBoxInstance != null) {
        backup['users'] = Map<String, dynamic>.from(_usersBoxInstance!.toMap());
      }
      
      // Settlements
      if (_settlementsBoxInstance != null) {
        backup['settlements'] = Map<String, dynamic>.from(_settlementsBoxInstance!.toMap());
      }
      
      // Cache
      if (_cacheBoxInstance != null) {
        backup['cache'] = Map<String, dynamic>.from(_cacheBoxInstance!.toMap());
      }
      
      backup['backupTimestamp'] = DateTime.now().toIso8601String();
      backup['appVersion'] = await getAppVersion() ?? '1.0.0';
      
      _logger.i('Backup created successfully');
      return backup;
    } catch (e) {
      _logger.e('Error creating backup: $e');
      return {};
    }
  }

  /// Restore data from backup
  static Future<bool> restoreFromBackup(Map<String, dynamic> backup) async {
    try {
      // Clear existing data
      await clearAll();
      
      // Restore settings
      if (backup.containsKey('settings')) {
        final settings = Map<String, dynamic>.from(backup['settings']);
        for (final entry in settings.entries) {
          await _settingsBoxInstance?.put(entry.key, entry.value);
        }
      }
      
      // Restore groups
      if (backup.containsKey('groups')) {
        final groups = Map<String, dynamic>.from(backup['groups']);
        for (final entry in groups.entries) {
          await _groupsBoxInstance?.put(entry.key, entry.value);
        }
      }
      
      // Restore expenses
      if (backup.containsKey('expenses')) {
        final expenses = Map<String, dynamic>.from(backup['expenses']);
        for (final entry in expenses.entries) {
          await _expensesBoxInstance?.put(entry.key, entry.value);
        }
      }
      
      // Restore users
      if (backup.containsKey('users')) {
        final users = Map<String, dynamic>.from(backup['users']);
        for (final entry in users.entries) {
          await _usersBoxInstance?.put(entry.key, entry.value);
        }
      }
      
      // Restore settlements
      if (backup.containsKey('settlements')) {
        final settlements = Map<String, dynamic>.from(backup['settlements']);
        for (final entry in settlements.entries) {
          await _settlementsBoxInstance?.put(entry.key, entry.value);
        }
      }
      
      // Restore cache
      if (backup.containsKey('cache')) {
        final cache = Map<String, dynamic>.from(backup['cache']);
        for (final entry in cache.entries) {
          await _cacheBoxInstance?.put(entry.key, entry.value);
        }
      }
      
      _logger.i('Data restored from backup successfully');
      return true;
    } catch (e) {
      _logger.e('Error restoring from backup: $e');
      return false;
    }
  }

  // ========== UTILITY METHODS ==========
  
  /// Check if cache is expired
  static Future<bool> isCacheExpired(String key, Duration maxAge) async {
    try {
      final lastUpdatedString = _cacheBoxInstance?.get('${key}_lastUpdated');
      if (lastUpdatedString == null) return true;
      
      final lastUpdated = DateTime.parse(lastUpdatedString);
      final age = DateTime.now().difference(lastUpdated);
      
      return age > maxAge;
    } catch (e) {
      _logger.e('Error checking cache expiry: $e');
      return true;
    }
  }

  /// Get storage size
  static Future<Map<String, int>> getStorageSize() async {
    try {
      return {
        'settings': _settingsBoxInstance?.length ?? 0,
        'groups': _groupsBoxInstance?.length ?? 0,
        'expenses': _expensesBoxInstance?.length ?? 0,
        'users': _usersBoxInstance?.length ?? 0,
        'settlements': _settlementsBoxInstance?.length ?? 0,
        'cache': _cacheBoxInstance?.length ?? 0,
      };
    } catch (e) {
      _logger.e('Error getting storage size: $e');
      return {};
    }
  }
}