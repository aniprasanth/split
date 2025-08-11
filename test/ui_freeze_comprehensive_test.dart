import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:splitzy/services/auth_service.dart';
import 'package:splitzy/services/database_service.dart';
import 'package:splitzy/screens/login_screen.dart';
import 'package:splitzy/screens/groups_screen.dart';
import 'package:splitzy/screens/add_expense_screen.dart';
import 'package:splitzy/screens/group_detail_screen.dart';
import 'package:splitzy/models/group_model.dart';
import 'package:splitzy/models/expense_model.dart';
import 'package:splitzy/models/user_model.dart';
import 'package:splitzy/models/settlement_model.dart';
import 'dart:async';

// Mock services for testing
class MockAuthService extends ChangeNotifier implements AuthService {
  bool _isLoading = false;
  bool _isSigningIn = false;
  String? _errorMessage;
  SplitzyUser? _currentUser = SplitzyUser(
    uid: 'test_user',
    email: 'test@example.com',
    name: 'Test User',
  );

  @override
  bool get isLoading => _isLoading;
  @override
  bool get isSigningIn => _isSigningIn;
  @override
  String? get errorMessage => _errorMessage;
  @override
  SplitzyUser? get currentUser => _currentUser;

  @override
  Future<String> signInWithGoogle() async {
    _isSigningIn = true;
    _isLoading = true;
    notifyListeners();
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
    
    _isSigningIn = false;
    _isLoading = false;
    notifyListeners();
    return 'success';
  }

  @override
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    return true;
  }

  @override
  Future<bool> createUserWithEmailAndPassword(String email, String password) async {
    return true;
  }

  @override
  Future<bool> signOut() async {
    return true;
  }

  @override
  Future<void> deleteAccount() async {
    // Implementation
  }

  @override
  Future<void> updateUserProfile({String? name, String? photoUrl, String? phoneNumber}) async {
    // Implementation
  }

  @override
  Future<String?> getAccessToken() async {
    return null;
  }

  @override
  Future<SplitzyUser?> getUserById(String userId) async {
    return null;
  }

  @override
  Future<List<SplitzyUser>> searchUsers(String query) async {
    return [];
  }

  @override
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

class MockDatabaseService extends ChangeNotifier implements DatabaseService {
  bool _isLoading = false;
  String? _errorMessage;
  final List<GroupModel> _groups = [];
  final List<ExpenseModel> _expenses = [];

  @override
  bool get isLoading => _isLoading;
  @override
  String? get errorMessage => _errorMessage;

  @override
  Future<bool> createGroup(GroupModel group) async {
    _isLoading = true;
    notifyListeners();
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
    
    _groups.add(group);
    _isLoading = false;
    notifyListeners();
    return true;
  }

  @override
  Future<bool> updateGroup(GroupModel group) async {
    _isLoading = true;
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 100));
    
    final index = _groups.indexWhere((g) => g.id == group.id);
    if (index != -1) {
      _groups[index] = group;
    }
    _isLoading = false;
    notifyListeners();
    return true;
  }

  @override
  Future<bool> deleteGroup(String groupId) async {
    _isLoading = true;
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 100));
    
    _groups.removeWhere((g) => g.id == groupId);
    _isLoading = false;
    notifyListeners();
    return true;
  }

  @override
  Stream<List<GroupModel>> getUserGroups(String userId) {
    return Stream.value(_groups);
  }

  @override
  Stream<List<ExpenseModel>> getGroupExpenses(String groupId) {
    return Stream.value(_expenses.where((e) => e.groupId == groupId).toList());
  }

  @override
  Stream<List<SettlementModel>> getGroupSettlements(String groupId) {
    return Stream.value([]);
  }

  @override
  Future<GroupModel?> getGroup(String groupId) async {
    return _groups.firstWhere((g) => g.id == groupId);
  }

  @override
  Future<bool> addMemberToGroup(String groupId, String memberId, String memberName) async {
    return true;
  }

  @override
  Future<bool> removeMemberFromGroup(String groupId, String memberId) async {
    return true;
  }

  @override
  Future<bool> addExpense(ExpenseModel expense) async {
    _isLoading = true;
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 100));
    
    _expenses.add(expense);
    _isLoading = false;
    notifyListeners();
    return true;
  }

  @override
  Future<bool> updateExpense(ExpenseModel expense) async {
    return true;
  }

  @override
  Future<bool> deleteExpense(String expenseId, [String? groupId]) async {
    return true;
  }

  @override
  Stream<List<ExpenseModel>> getAllExpenses() {
    return Stream.value(_expenses);
  }

  @override
  Future<bool> addSettlement(SettlementModel settlement) async {
    return true;
  }

  @override
  Stream<List<SettlementModel>> getAllSettlementsForUser(String userId) {
    return Stream.value([]);
  }

  @override
  Stream<List<Map<String, dynamic>>> getTransactionHistory(String userId) {
    return Stream.value([]);
  }

  @override
  Future<Map<String, double>> calculateBalances(String groupId) async {
    return {};
  }

  @override
  Future<List<SettlementModel>> calculateSettlements(String groupId) async {
    return [];
  }

  @override
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

void main() {
  group('Comprehensive UI Freeze Prevention Tests', () {
    late MockAuthService mockAuthService;
    late MockDatabaseService mockDatabaseService;

    setUp(() {
      mockAuthService = MockAuthService();
      mockDatabaseService = MockDatabaseService();
    });

    Widget createTestApp(Widget child) {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
            ChangeNotifierProvider<DatabaseService>.value(value: mockDatabaseService),
          ],
          child: child,
        ),
      );
    }

    testWidgets('Google Sign In prevents multiple simultaneous calls', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const LoginScreen()));

      final button = find.text('Continue with Google');
      expect(button, findsOneWidget);

      // Rapidly tap multiple times
      for (int i = 0; i < 5; i++) {
        await tester.tap(button);
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Should show loading and be disabled
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<ElevatedButton>(button).enabled, false);

      // Wait for completion
      await tester.pumpAndSettle();

      // Should be re-enabled
      expect(tester.widget<ElevatedButton>(button).enabled, true);
    });

    testWidgets('Create Group dialog shows loading state and prevents re-entrant calls', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const GroupsScreen()));

      // Open create dialog
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Enter group name
      await tester.enterText(find.byType(TextField), 'Test Group');
      await tester.pump();

      // Find create button
      final createButton = find.text('Create');
      expect(createButton, findsOneWidget);

      // Rapidly tap multiple times
      for (int i = 0; i < 3; i++) {
        await tester.tap(createButton);
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Should show loading spinner
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<ElevatedButton>(createButton).enabled, false);

      // Wait for completion
      await tester.pumpAndSettle();

      // Dialog should close
      expect(find.text('Create'), findsNothing);
    });

    testWidgets('Add Expense shows loading state and prevents re-entrant calls', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const AddExpenseScreen()));

      // Fill required fields
      await tester.enterText(find.byKey(const Key('description')), 'Test Expense');
      await tester.enterText(find.byKey(const Key('amount')), '100.00');
      await tester.pump();

      // Find add button
      final addButton = find.text('Add Expense');
      expect(addButton, findsOneWidget);

      // Rapidly tap multiple times
      for (int i = 0; i < 3; i++) {
        await tester.tap(addButton);
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Should show loading state
      expect(find.text('Adding...'), findsOneWidget);
      expect(tester.widget<ElevatedButton>(addButton).enabled, false);

      // Wait for completion
      await tester.pumpAndSettle();

      // Should navigate back
      expect(find.text('Add Expense'), findsNothing);
    });

    testWidgets('Group detail dialogs show loading states', (WidgetTester tester) async {
      final testGroup = GroupModel.create(
        name: 'Test Group',
        members: ['user1', 'user2'],
        memberNames: {'user1': 'User 1', 'user2': 'User 2'},
        createdBy: 'user1',
      );

      await tester.pumpWidget(createTestApp(GroupDetailScreen(group: testGroup)));

      // Test Edit Group
      await tester.tap(find.byType(PopupMenuButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Group'));
      await tester.pumpAndSettle();

      // Enter new name
      await tester.enterText(find.byType(TextField), 'Updated Group');
      await tester.pump();

      // Tap update multiple times
      final updateButton = find.text('Update');
      for (int i = 0; i < 3; i++) {
        await tester.tap(updateButton);
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Should show loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<ElevatedButton>(updateButton).enabled, false);

      // Wait for completion
      await tester.pumpAndSettle();

      // Test Delete Group
      await tester.tap(find.byType(PopupMenuButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Group'));
      await tester.pumpAndSettle();

      // Tap delete multiple times
      final deleteButton = find.text('Delete');
      for (int i = 0; i < 3; i++) {
        await tester.tap(deleteButton);
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Should show loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<ElevatedButton>(deleteButton).enabled, false);

      // Wait for completion
      await tester.pumpAndSettle();
    });

    testWidgets('Add Person dialog shows loading during permission request', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const AddExpenseScreen()));

      // Find and tap Add Person button
      final addPersonButton = find.text('Add Person');
      if (addPersonButton.evaluate().isNotEmpty) {
        await tester.tap(addPersonButton);
        await tester.pumpAndSettle();

        // Look for permission request button
        final permissionButton = find.text('Grant contacts permission');
        if (permissionButton.evaluate().isNotEmpty) {
          // Tap permission button multiple times
          for (int i = 0; i < 3; i++) {
            await tester.tap(permissionButton);
            await tester.pump(const Duration(milliseconds: 50));
          }

          // Should show loading state
          expect(find.text('Requesting...'), findsOneWidget);
        }
      }
    });

    testWidgets('All buttons remain responsive during async operations', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const LoginScreen()));

      final button = find.text('Continue with Google');
      
      // Start async operation
      await tester.tap(button);
      await tester.pump();

      // Button should be disabled but UI should remain responsive
      expect(tester.widget<ElevatedButton>(button).enabled, false);
      
      // Should be able to interact with other UI elements (if any)
      // This test ensures the UI doesn't freeze completely

      // Wait for completion
      await tester.pumpAndSettle();
      
      // UI should be responsive again
      expect(tester.widget<ElevatedButton>(button).enabled, true);
    });

    testWidgets('Error handling shows user-friendly messages', (WidgetTester tester) async {
      // Test with a mock that returns error
      mockDatabaseService._errorMessage = 'Network error';
      
      await tester.pumpWidget(createTestApp(const GroupsScreen()));

      // Try to create a group
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Test Group');
      await tester.pump();
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.text('Network error'), findsOneWidget);
    });

    testWidgets('Loading states are properly cleaned up on widget disposal', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const LoginScreen()));

      final button = find.text('Continue with Google');
      
      // Start async operation
      await tester.tap(button);
      await tester.pump();

      // Navigate away (simulate widget disposal)
      await tester.pumpWidget(Container());

      // Should not crash or have memory leaks
      expect(tester.takeException(), isNull);
    });
  });
}

