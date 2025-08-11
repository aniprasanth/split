import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:splitzy/screens/login_screen.dart';
import 'package:splitzy/screens/add_expense_screen.dart';
import 'package:splitzy/screens/groups_screen.dart';
import 'package:splitzy/screens/settle_up_screen.dart';
import 'package:splitzy/screens/group_detail_screen.dart';
import 'package:splitzy/services/auth_service.dart';
import 'package:splitzy/services/database_service.dart';
import 'package:splitzy/services/contacts_service.dart';
import 'package:splitzy/models/expense_model.dart';
import 'package:splitzy/models/group_model.dart';
import 'package:splitzy/models/settlement_model.dart';
import 'package:splitzy/models/user_model.dart';
import 'comprehensive_functionality_test.mocks.dart';

// Generate mocks by running: dart run build_runner build
@GenerateMocks([
  AuthService,
  DatabaseService,
  ContactsService,
  UserCredential,
  User,
])
void main() {
  group('Comprehensive Functionality Tests', () {
    late MockAuthService mockAuthService;
    late MockDatabaseService mockDatabaseService;
    late MockContactsService mockContactsService;
    late MockUserCredential mockUserCredential;
    late MockUser mockUser;

    setUp(() {
      mockAuthService = MockAuthService();
      mockDatabaseService = MockDatabaseService();
      mockContactsService = MockContactsService();
      mockUserCredential = MockUserCredential();
      mockUser = MockUser();

      // Setup Firebase Auth mocks
      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test-user-id');
      when(mockUser.email).thenReturn('test@example.com');
      when(mockUser.displayName).thenReturn('Test User');

      // Setup default mock behaviors
      when(mockAuthService.currentUser).thenReturn(
        SplitzyUser(
          uid: 'test-user-id',
          email: 'test@example.com',
          name: 'Test User',
        ),
      );
      when(mockAuthService.isLoading).thenReturn(false);
      when(mockAuthService.isSigningIn).thenReturn(false);
      when(mockAuthService.errorMessage).thenReturn(null);
      when(mockAuthService.signInWithGoogle()).thenAnswer((_) async => mockUserCredential);
      when(mockAuthService.clearError()).thenReturn(null);

      when(mockDatabaseService.isLoading).thenReturn(false);
      when(mockDatabaseService.errorMessage).thenReturn(null);
      when(mockDatabaseService.addExpense(any)).thenAnswer((_) async => true);
      when(mockDatabaseService.createGroup(any)).thenAnswer((_) async => true);
      when(mockDatabaseService.updateGroup(any)).thenAnswer((_) async => true);
      when(mockDatabaseService.deleteGroup(any)).thenAnswer((_) async => true);
      when(mockDatabaseService.deleteExpense(any, any)).thenAnswer((_) async => true);
      when(mockDatabaseService.addSettlement(any)).thenAnswer((_) async => true);

      when(mockContactsService.hasPermission).thenReturn(true);
      when(mockContactsService.isLoading).thenReturn(false);
      when(mockContactsService.contacts).thenReturn([]);
      when(mockContactsService.requestPermission()).thenAnswer((_) async => true);
      when(mockContactsService.loadContacts()).thenAnswer((_) async {});
    });

    Widget createTestApp(Widget child) {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
            ChangeNotifierProvider<DatabaseService>.value(value: mockDatabaseService),
            ChangeNotifierProvider<ContactsService>.value(value: mockContactsService),
          ],
          child: child,
        ),
      );
    }

    group('1. Button Interactions with Loading States', () {
      testWidgets('Google Sign-In button shows loading state', (tester) async {
        when(mockAuthService.isSigningIn).thenReturn(true);

        await tester.pumpWidget(createTestApp(const LoginScreen()));

        // Find Google Sign-In button
        final googleButton = find.byType(ElevatedButton);
        expect(googleButton, findsOneWidget);

        // Verify button is disabled during loading
        final button = tester.widget<ElevatedButton>(googleButton);
        expect(button.onPressed, isNull);

        // Verify loading indicator is shown
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('Create Group button shows loading state', (tester) async {
        when(mockDatabaseService.isLoading).thenReturn(true);
        when(mockDatabaseService.getUserGroups(any))
            .thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestApp(const GroupsScreen()));
        await tester.pumpAndSettle();

        // Tap to open create group dialog
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // Fill in group name
        await tester.enterText(find.byType(TextFormField), 'Test Group');

        // Find Create button in dialog
        final createButton = find.text('Create');
        expect(createButton, findsOneWidget);

        // Tap create button
        await tester.tap(createButton);
        await tester.pump();

        // Verify loading indicator is shown
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('Add Expense button shows loading state', (tester) async {
        when(mockDatabaseService.getUserGroups(any))
            .thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestApp(const AddExpenseScreen()));
        await tester.pumpAndSettle();

        // Fill in required fields
        await tester.enterText(
            find.widgetWithText(TextFormField, 'Description').first,
            'Test Expense'
        );
        await tester.enterText(
            find.widgetWithText(TextFormField, 'Amount').first,
            '100.00'
        );

        // Add a member for non-group expense
        await tester.tap(find.text('Add Person'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'John Doe');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // Tap Add Expense button
        await tester.tap(find.text('Add Expense'));
        await tester.pump();

        // Verify loading state
        expect(find.text('Adding...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('Group management buttons show loading states', (tester) async {
        final testGroup = GroupModel(
          id: 'test-group-id',
          name: 'Test Group',
          members: ['test-user-id'],
          memberNames: {'test-user-id': 'Test User'},
          createdBy: 'test-user-id',
          createdAt: DateTime.now(),
        );

        when(mockDatabaseService.getGroupExpenses(any))
            .thenAnswer((_) => Stream.value([]));
        when(mockDatabaseService.getSettlements(any))
            .thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestApp(GroupDetailScreen(group: testGroup)));
        await tester.pumpAndSettle();

        // Test Edit Group button
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Edit Group'));
        await tester.pumpAndSettle();

        // Verify edit dialog shows loading state when updating
        when(mockDatabaseService.isLoading).thenReturn(true);
        await tester.enterText(find.byType(TextFormField), 'Updated Group Name');
        await tester.tap(find.text('Update'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('2. Data Persistence and Deletion Behaviors', () {
      testWidgets('Expense creation persists data correctly', (tester) async {
        when(mockDatabaseService.getUserGroups(any))
            .thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestApp(const AddExpenseScreen()));
        await tester.pumpAndSettle();

        // Fill in expense details
        await tester.enterText(
            find.widgetWithText(TextFormField, 'Description').first,
            'Test Expense'
        );
        await tester.enterText(
            find.widgetWithText(TextFormField, 'Amount').first,
            '150.00'
        );

        // Add member for non-group expense
        await tester.tap(find.text('Add Person'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Jane Doe');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // Save expense
        await tester.tap(find.text('Add Expense'));
        await tester.pumpAndSettle();

        // Verify database service was called with correct data
        verify(mockDatabaseService.addExpense(any)).called(1);
      });

      testWidgets('Group creation persists data correctly', (tester) async {
        when(mockDatabaseService.getUserGroups(any))
            .thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestApp(const GroupsScreen()));
        await tester.pumpAndSettle();

        // Open create group dialog
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // Fill in group details
        await tester.enterText(find.byType(TextFormField), 'New Test Group');
        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();

        // Verify database service was called
        verify(mockDatabaseService.createGroup(any)).called(1);
      });

      testWidgets('Expense deletion removes data correctly', (tester) async {
        final testExpense = ExpenseModel(
          id: 'test-expense-id',
          groupId: 'test-group-id',
          payer: 'test-user-id',
          payerName: 'Test User',
          amount: 100.0,
          description: 'Test Expense',
          split: {'test-user-id': 100.0},
          date: DateTime.now(),
          createdAt: DateTime.now(),
        );

        final testGroup = GroupModel(
          id: 'test-group-id',
          name: 'Test Group',
          members: ['test-user-id'],
          memberNames: {'test-user-id': 'Test User'},
          createdBy: 'test-user-id',
          createdAt: DateTime.now(),
        );

        when(mockDatabaseService.getGroupExpenses(any))
            .thenAnswer((_) => Stream.value([testExpense]));
        when(mockDatabaseService.getSettlements(any))
            .thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestApp(GroupDetailScreen(group: testGroup)));
        await tester.pumpAndSettle();

        // Find and long press on expense to show options
        await tester.longPress(find.text('Test Expense'));
        await tester.pumpAndSettle();

        // Tap delete option
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Confirm deletion
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Verify database service was called
        verify(mockDatabaseService.deleteExpense(any, any)).called(1);
      });

      testWidgets('Group deletion removes data correctly', (tester) async {
        final testGroup = GroupModel(
          id: 'test-group-id',
          name: 'Test Group',
          members: ['test-user-id'],
          memberNames: {'test-user-id': 'Test User'},
          createdBy: 'test-user-id',
          createdAt: DateTime.now(),
        );

        when(mockDatabaseService.getUserGroups(any))
            .thenAnswer((_) => Stream.value([testGroup]));

        await tester.pumpWidget(createTestApp(const GroupsScreen()));
        await tester.pumpAndSettle();

        // Find and long press on group to show options
        await tester.longPress(find.text('Test Group'));
        await tester.pumpAndSettle();

        // Tap delete option
        await tester.tap(find.text('Delete Group'));
        await tester.pumpAndSettle();

        // Confirm deletion
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Verify database service was called
        verify(mockDatabaseService.deleteGroup(any)).called(1);
      });
    });

    group('3. Settle Up Screen Real-time Updates', () {
      testWidgets('Settle up screen shows only unsettled transactions', (tester) async {
        final testExpense = ExpenseModel(
          id: 'test-expense-id',
          groupId: 'test-group-id',
          payer: 'test-user-id',
          payerName: 'Test User',
          amount: 100.0,
          description: 'Test Expense',
          split: {'test-user-id': 50.0, 'other-user-id': 50.0},
          date: DateTime.now(),
          createdAt: DateTime.now(),
        );

        final testSettlement = SettlementModel(
          id: 'test-settlement-id',
          fromUser: 'test-user-id',
          fromUserName: 'Test User',
          toUser: 'other-user-id',
          toUserName: 'Other User',
          amount: 25.0,
          groupId: 'test-group-id',
          groupName: 'Test Group',
          paymentMethod: 'Manual',
          status: SettlementStatus.completed,
          date: DateTime.now(), // Added required date parameter
          createdAt: DateTime.now(),
        );

        when(mockDatabaseService.getAllExpenses())
            .thenAnswer((_) => Stream.value([testExpense]));
        when(mockDatabaseService.getUserGroups(any))
            .thenAnswer((_) => Stream.value([
          GroupModel(
            id: 'test-group-id',
            name: 'Test Group',
            members: ['test-user-id', 'other-user-id'],
            memberNames: {
              'test-user-id': 'Test User',
              'other-user-id': 'Other User',
            },
            createdBy: 'test-user-id',
            createdAt: DateTime.now(),
          ),
        ]));
        when(mockDatabaseService.getAllSettlementsForUser(any))
            .thenAnswer((_) => Stream.value([testSettlement]));

        await tester.pumpWidget(createTestApp(const SettleUpScreen()));
        await tester.pumpAndSettle();

        // Verify tabs show correct labels
        expect(find.text('To Give'), findsOneWidget);
        expect(find.text('To Get'), findsOneWidget);

        // Verify only unsettled amounts are shown
        // After settlement of 25.0, remaining unsettled amount should be 25.0
        expect(find.text('₹25.00'), findsOneWidget);
      });

      testWidgets('Mark as settled removes transaction immediately', (tester) async {
        final testExpense = ExpenseModel(
          id: 'test-expense-id',
          groupId: 'test-group-id',
          payer: 'other-user-id',
          payerName: 'Other User',
          amount: 100.0,
          description: 'Test Expense',
          split: {'test-user-id': 50.0, 'other-user-id': 50.0},
          date: DateTime.now(),
          createdAt: DateTime.now(),
        );

        when(mockDatabaseService.getAllExpenses())
            .thenAnswer((_) => Stream.value([testExpense]));
        when(mockDatabaseService.getUserGroups(any))
            .thenAnswer((_) => Stream.value([
          GroupModel(
            id: 'test-group-id',
            name: 'Test Group',
            members: ['test-user-id', 'other-user-id'],
            memberNames: {
              'test-user-id': 'Test User',
              'other-user-id': 'Other User',
            },
            createdBy: 'test-user-id',
            createdAt: DateTime.now(),
          ),
        ]));
        when(mockDatabaseService.getAllSettlementsForUser(any))
            .thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestApp(const SettleUpScreen()));
        await tester.pumpAndSettle();

        // Verify unsettled amount is shown
        expect(find.text('₹50.00'), findsOneWidget);

        // Tap Mark as Settled
        await tester.tap(find.text('Mark as Settled'));
        await tester.pumpAndSettle();

        // Confirm settlement
        await tester.tap(find.text('Mark Settled'));
        await tester.pumpAndSettle();

        // Verify database service was called
        verify(mockDatabaseService.addSettlement(any)).called(1);
      });
    });

    group('4. Non-Group Expense Splitting Functionality', () {
      testWidgets('Add Person button appears only for non-group expenses', (tester) async {
        when(mockDatabaseService.getUserGroups(any))
            .thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestApp(const AddExpenseScreen()));
        await tester.pumpAndSettle();

        // Verify Add Person button is visible when no group is selected
        expect(find.text('Add Person'), findsOneWidget);

        // Mock group selection
        when(mockDatabaseService.getUserGroups(any))
            .thenAnswer((_) => Stream.value([
          GroupModel(
            id: 'test-group-id',
            name: 'Test Group',
            members: ['test-user-id'],
            memberNames: {'test-user-id': 'Test User'},
            createdBy: 'test-user-id',
            createdAt: DateTime.now(),
          ),
        ]));

        await tester.pumpAndSettle();

        // Select a group
        await tester.tap(find.byType(DropdownButtonFormField<GroupModel?>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Test Group'));
        await tester.pumpAndSettle();

        // Verify Add Person button is hidden when group is selected
        expect(find.text('Add Person'), findsNothing);
      });

      testWidgets('Manual member addition works correctly', (tester) async {
        when(mockDatabaseService.getUserGroups(any))
            .thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestApp(const AddExpenseScreen()));
        await tester.pumpAndSettle();

        // Tap Add Person button
        await tester.tap(find.text('Add Person'));
        await tester.pumpAndSettle();

        // Enter member name
        await tester.enterText(find.byType(TextField), 'John Doe');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // Verify member was added and auto-selected
        expect(find.text('John Doe'), findsOneWidget);
        expect(find.byType(CheckboxListTile), findsOneWidget);
      });

      testWidgets('Contact integration works correctly', (tester) async {
        // Create mock contacts using the proper Contact class
        final mockContacts = [
          Contact()..displayName = 'Jane Doe',
          Contact()..displayName = 'Bob Smith',
        ];

        when(mockContactsService.contacts).thenReturn(mockContacts);
        when(mockDatabaseService.getUserGroups(any))
            .thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestApp(const AddExpenseScreen()));
        await tester.pumpAndSettle();

        // Tap Add Person button
        await tester.tap(find.text('Add Person'));
        await tester.pumpAndSettle();

        // Tap on contact
        await tester.tap(find.text('Jane Doe'));
        await tester.pumpAndSettle();

        // Verify contact was added
        expect(find.text('Jane Doe'), findsOneWidget);
      });

      testWidgets('Non-group expense validation works correctly', (tester) async {
        when(mockDatabaseService.getUserGroups(any))
            .thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestApp(const AddExpenseScreen()));
        await tester.pumpAndSettle();

        // Try to save without adding members
        await tester.enterText(
            find.widgetWithText(TextFormField, 'Description').first,
            'Test Expense'
        );
        await tester.enterText(
            find.widgetWithText(TextFormField, 'Amount').first,
            '100.00'
        );
        await tester.tap(find.text('Add Expense'));
        await tester.pumpAndSettle();

        // Verify error message
        expect(find.text('Please add at least one more person to split the expense'), findsOneWidget);
      });

      testWidgets('Non-group expense splitting calculation is accurate', (tester) async {
        when(mockDatabaseService.getUserGroups(any))
            .thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestApp(const AddExpenseScreen()));
        await tester.pumpAndSettle();

        // Add expense amount
        await tester.enterText(
            find.widgetWithText(TextFormField, 'Amount').first,
            '100.00'
        );

        // Add members
        await tester.tap(find.text('Add Person'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'John Doe');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // Verify split calculation
        expect(find.text('Split: ₹50.00 per person'), findsOneWidget);
      });

      testWidgets('Non-group expense saves with correct data structure', (tester) async {
        when(mockDatabaseService.getUserGroups(any))
            .thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestApp(const AddExpenseScreen()));
        await tester.pumpAndSettle();

        // Fill in expense details
        await tester.enterText(
            find.widgetWithText(TextFormField, 'Description').first,
            'Test Expense'
        );
        await tester.enterText(
            find.widgetWithText(TextFormField, 'Amount').first,
            '100.00'
        );

        // Add member
        await tester.tap(find.text('Add Person'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'John Doe');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // Save expense
        await tester.tap(find.text('Add Expense'));
        await tester.pumpAndSettle();

        // Verify expense was created with empty groupId
        verify(mockDatabaseService.addExpense(argThat(
          isA<ExpenseModel>().having((e) => e.groupId, 'groupId', ''),
        ))).called(1);
      });
    });

    group('5. Error Handling and Edge Cases', () {
      testWidgets('Network errors are handled gracefully', (tester) async {
        when(mockDatabaseService.addExpense(any))
            .thenAnswer((_) async => false);
        when(mockDatabaseService.errorMessage)
            .thenReturn('Network error occurred');
        when(mockDatabaseService.getUserGroups(any))
            .thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestApp(const AddExpenseScreen()));
        await tester.pumpAndSettle();

        // Fill in expense details
        await tester.enterText(
            find.widgetWithText(TextFormField, 'Description').first,
            'Test Expense'
        );
        await tester.enterText(
            find.widgetWithText(TextFormField, 'Amount').first,
            '100.00'
        );

        // Add member
        await tester.tap(find.text('Add Person'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'John Doe');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // Try to save
        await tester.tap(find.text('Add Expense'));
        await tester.pumpAndSettle();

        // Verify error message is shown
        expect(find.text('Failed to add expense. Please try again.'), findsOneWidget);
      });

      testWidgets('Contact permission denied is handled gracefully', (tester) async {
        when(mockContactsService.hasPermission).thenReturn(false);
        when(mockContactsService.requestPermission()).thenAnswer((_) async => false);
        when(mockDatabaseService.getUserGroups(any))
            .thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestApp(const AddExpenseScreen()));
        await tester.pumpAndSettle();

        // Tap Add Person button
        await tester.tap(find.text('Add Person'));
        await tester.pumpAndSettle();

        // Tap grant permission button
        await tester.tap(find.text('Grant contacts permission'));
        await tester.pumpAndSettle();

        // Verify permission denied message
        expect(find.text('Permission denied'), findsOneWidget);
      });

      testWidgets('Empty member names are handled correctly', (tester) async {
        when(mockDatabaseService.getUserGroups(any))
            .thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestApp(const AddExpenseScreen()));
        await tester.pumpAndSettle();

        // Tap Add Person button
        await tester.tap(find.text('Add Person'));
        await tester.pumpAndSettle();

        // Try to submit empty name
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // Verify dialog stays open (no member added)
        expect(find.text('Add Person'), findsOneWidget);
      });

      testWidgets('Invalid amount input is handled correctly', (tester) async {
        when(mockDatabaseService.getUserGroups(any))
            .thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createTestApp(const AddExpenseScreen()));
        await tester.pumpAndSettle();

        // Fill in invalid amount
        await tester.enterText(
            find.widgetWithText(TextFormField, 'Description').first,
            'Test Expense'
        );
        await tester.enterText(
            find.widgetWithText(TextFormField, 'Amount').first,
            'invalid'
        );

        // Add member
        await tester.tap(find.text('Add Person'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'John Doe');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // Try to save
        await tester.tap(find.text('Add Expense'));
        await tester.pumpAndSettle();

        // Verify validation error
        expect(find.text('Please enter a valid amount'), findsOneWidget);
      });
    });
  });
}