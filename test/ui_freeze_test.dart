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

// Mock services for testing
class MockAuthService extends ChangeNotifier implements AuthService {
  bool _isLoading = false;
  bool _isSigningIn = false;
  String? _errorMessage;
  dynamic _currentUser = {'uid': 'test_user', 'displayName': 'Test User'};

  @override
  bool get isLoading => _isLoading;
  @override
  bool get isSigningIn => _isSigningIn;
  @override
  String? get errorMessage => _errorMessage;
  @override
  dynamic get currentUser => _currentUser;

  @override
  Future<UserCredential?> signInWithGoogle() async {
    _isSigningIn = true;
    _isLoading = true;
    notifyListeners();
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
    
    _isSigningIn = false;
    _isLoading = false;
    notifyListeners();
    return null; // Simulate success
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
  List<GroupModel> _groups = [];

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
  Future<bool> addExpense(ExpenseModel expense) async {
    _isLoading = true;
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 100));
    
    _isLoading = false;
    notifyListeners();
    return true;
  }

  @override
  Stream<List<GroupModel>> getUserGroups(String userId) {
    return Stream.value(_groups);
  }
}

void main() {
  group('UI Freeze Prevention Tests', () {
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

    testWidgets('Google Sign In button shows loading state and prevents re-entrant calls', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const LoginScreen()));

      // Find the Google Sign In button
      final button = find.text('Continue with Google');
      expect(button, findsOneWidget);

      // Tap the button
      await tester.tap(button);
      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Button should be disabled during loading
      expect(tester.widget<ElevatedButton>(button).enabled, false);

      // Wait for operation to complete
      await tester.pumpAndSettle();

      // Button should be re-enabled
      expect(tester.widget<ElevatedButton>(button).enabled, true);
    });

    testWidgets('Create Group button shows loading state and prevents re-entrant calls', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const GroupsScreen()));

      // Find the FAB
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      // Tap to show dialog
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Find the create button in dialog
      final createButton = find.text('Create');
      expect(createButton, findsOneWidget);

      // Enter group name
      await tester.enterText(find.byType(TextField), 'Test Group');
      await tester.pump();

      // Tap create button
      await tester.tap(createButton);
      await tester.pump();

      // Should show loading state (button disabled)
      expect(tester.widget<ElevatedButton>(createButton).enabled, false);

      // Wait for operation to complete
      await tester.pumpAndSettle();

      // Dialog should close and show success
      expect(find.text('Create'), findsNothing);
    });

    testWidgets('Add Expense button shows loading state and prevents re-entrant calls', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const AddExpenseScreen()));

      // Enter required fields
      await tester.enterText(find.byKey(const Key('description')), 'Test Expense');
      await tester.enterText(find.byKey(const Key('amount')), '100.00');
      await tester.pump();

      // Find the Add Expense button
      final addButton = find.text('Add Expense');
      expect(addButton, findsOneWidget);

      // Tap the button
      await tester.tap(addButton);
      await tester.pump();

      // Should show loading state
      expect(find.text('Adding...'), findsOneWidget);
      expect(tester.widget<ElevatedButton>(addButton).enabled, false);

      // Wait for operation to complete
      await tester.pumpAndSettle();

      // Should show success and navigate back
      expect(find.text('Add Expense'), findsNothing);
    });

    testWidgets('Group detail dialog buttons show loading states', (WidgetTester tester) async {
      final testGroup = GroupModel.create(
        name: 'Test Group',
        members: ['user1', 'user2'],
        memberNames: {'user1': 'User 1', 'user2': 'User 2'},
        createdBy: 'user1',
      );

      await tester.pumpWidget(createTestApp(GroupDetailScreen(group: testGroup)));

      // Find the popup menu button
      final popupButton = find.byType(PopupMenuButton);
      expect(popupButton, findsOneWidget);

      // Open menu
      await tester.tap(popupButton);
      await tester.pumpAndSettle();

      // Test Edit Group
      await tester.tap(find.text('Edit Group'));
      await tester.pumpAndSettle();

      // Enter new name
      await tester.enterText(find.byType(TextField), 'Updated Group');
      await tester.pump();

      // Tap Update
      final updateButton = find.text('Update');
      await tester.tap(updateButton);
      await tester.pump();

      // Should show loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<ElevatedButton>(updateButton).enabled, false);

      // Wait for completion
      await tester.pumpAndSettle();

      // Test Delete Group
      await tester.tap(popupButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Group'));
      await tester.pumpAndSettle();

      final deleteButton = find.text('Delete');
      await tester.tap(deleteButton);
      await tester.pump();

      // Should show loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<ElevatedButton>(deleteButton).enabled, false);

      // Wait for completion
      await tester.pumpAndSettle();
    });

    testWidgets('Multiple rapid button taps do not cause freezes', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const LoginScreen()));

      final button = find.text('Continue with Google');
      
      // Rapidly tap the button multiple times
      for (int i = 0; i < 5; i++) {
        await tester.tap(button);
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Should only execute once and show loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<ElevatedButton>(button).enabled, false);

      // Wait for completion
      await tester.pumpAndSettle();
    });
  });
}
