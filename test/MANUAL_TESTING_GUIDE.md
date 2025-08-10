# Manual Testing Guide - Comprehensive Functionality Verification

## Overview
This guide provides step-by-step instructions for manually testing all the implemented functionality in the Splitzy app, including button interactions, data persistence, real-time updates, and new features.

## Prerequisites
- Flutter development environment set up
- Firebase project configured
- Test device or emulator ready
- Test user accounts available

## Test Categories

### 1. Button Interactions with Loading States

#### **1.1 Google Sign-In Button**
**Objective**: Verify loading states and prevent UI freezes

**Steps**:
1. Launch the app
2. Navigate to Login Screen
3. Tap "Sign in with Google" button
4. **Expected**: Button shows spinner and becomes disabled
5. **Expected**: No UI freeze during sign-in process
6. **Expected**: Success/error message displayed appropriately

**Test Cases**:
- ✅ Normal sign-in flow
- ✅ Network timeout scenarios
- ✅ Permission denied scenarios
- ✅ Multiple rapid taps (should be prevented)

#### **1.2 Create Group Button**
**Objective**: Verify loading states during group creation

**Steps**:
1. Sign in to the app
2. Navigate to Groups Screen
3. Tap "+" button to create new group
4. Enter group name
5. Tap "Create" button
6. **Expected**: Button shows spinner and becomes disabled
7. **Expected**: No UI freeze during creation
8. **Expected**: Group appears in list after creation

**Test Cases**:
- ✅ Normal group creation
- ✅ Network error scenarios
- ✅ Invalid group names
- ✅ Multiple rapid taps (should be prevented)

#### **1.3 Add Expense Button**
**Objective**: Verify loading states during expense creation

**Steps**:
1. Navigate to Add Expense Screen
2. Fill in expense details (description, amount)
3. Add members (for non-group expense)
4. Tap "Add Expense" button
5. **Expected**: Button shows "Adding..." with spinner
6. **Expected**: Button becomes disabled
7. **Expected**: No UI freeze during save
8. **Expected**: Success message and navigation back

**Test Cases**:
- ✅ Group expense creation
- ✅ Non-group expense creation
- ✅ Network error scenarios
- ✅ Validation error scenarios

#### **1.4 Group Management Buttons**
**Objective**: Verify loading states for edit/delete operations

**Steps**:
1. Navigate to Group Detail Screen
2. Tap kebab menu (⋮)
3. Select "Edit" or "Delete"
4. **Expected**: Buttons show loading states
5. **Expected**: No UI freeze during operations
6. **Expected**: Proper success/error feedback

**Test Cases**:
- ✅ Edit group name
- ✅ Delete group
- ✅ Manage members
- ✅ Network error scenarios

### 2. Data Persistence and Deletion Behaviors

#### **2.1 Expense Creation Persistence**
**Objective**: Verify expenses are saved correctly

**Steps**:
1. Create a new expense (group or non-group)
2. Fill in all required fields
3. Save the expense
4. Navigate away and back
5. **Expected**: Expense appears in appropriate list
6. **Expected**: All data is preserved correctly
7. **Expected**: Split calculations are accurate

**Test Cases**:
- ✅ Group expense with multiple members
- ✅ Non-group expense with added members
- ✅ Large amounts (test rounding)
- ✅ Special characters in description
- ✅ Offline scenarios (if implemented)

#### **2.2 Group Creation Persistence**
**Objective**: Verify groups are saved correctly

**Steps**:
1. Create a new group
2. Add group name
3. Save the group
4. Navigate away and back
5. **Expected**: Group appears in groups list
6. **Expected**: Group data is preserved
7. **Expected**: Group is accessible for expenses

**Test Cases**:
- ✅ Normal group creation
- ✅ Groups with special characters
- ✅ Large number of groups
- ✅ Duplicate group names (if allowed)

#### **2.3 Expense Deletion**
**Objective**: Verify expenses are deleted correctly

**Steps**:
1. Navigate to expense list (group or non-group)
2. Find an expense to delete
3. Use swipe-to-delete or popup menu
4. Confirm deletion
5. **Expected**: Expense disappears from list
6. **Expected**: Confirmation dialog appears
7. **Expected**: Success message shown
8. **Expected**: Data is removed from database

**Test Cases**:
- ✅ Swipe-to-delete gesture
- ✅ Popup menu delete option
- ✅ Cancel deletion
- ✅ Delete from different screens
- ✅ Network error during deletion

#### **2.4 Group Deletion**
**Objective**: Verify groups are deleted correctly

**Steps**:
1. Navigate to Groups Screen
2. Find a group to delete
3. Use kebab menu to delete
4. Confirm deletion
5. **Expected**: Group disappears from list
6. **Expected**: Related expenses are handled properly
7. **Expected**: Success message shown

**Test Cases**:
- ✅ Empty group deletion
- ✅ Group with expenses
- ✅ Group with settlements
- ✅ Cancel deletion
- ✅ Network error scenarios

### 3. Settle Up Screen Real-time Updates

#### **3.1 Dynamic Settlement Display**
**Objective**: Verify only unsettled transactions are shown

**Steps**:
1. Navigate to Settle Up Screen
2. **Expected**: Only unsettled amounts are displayed
3. **Expected**: "To Give" and "To Get" tabs are present
4. **Expected**: No settled transactions in the list

**Test Cases**:
- ✅ Empty settle up screen (all settled)
- ✅ Mixed settled/unsettled transactions
- ✅ Large amounts with rounding
- ✅ Multiple groups with settlements

#### **3.2 Mark as Settled Functionality**
**Objective**: Verify immediate removal of settled transactions

**Steps**:
1. Navigate to Settle Up Screen
2. Find an unsettled transaction
3. Tap "Mark as Settled"
4. Confirm the settlement
5. **Expected**: Transaction disappears immediately
6. **Expected**: Success message shown
7. **Expected**: Settlement is recorded in database

**Test Cases**:
- ✅ Mark single transaction as settled
- ✅ Mark multiple transactions
- ✅ Cancel settlement marking
- ✅ Network error during settlement
- ✅ Settlement with group selection

#### **3.3 Real-time Updates**
**Objective**: Verify UI updates without manual refresh

**Steps**:
1. Open Settle Up Screen
2. Mark a transaction as settled
3. **Expected**: UI updates immediately
4. **Expected**: No manual refresh needed
5. **Expected**: Stream-based updates work correctly

**Test Cases**:
- ✅ Immediate UI updates
- ✅ Multiple rapid settlements
- ✅ Concurrent user scenarios
- ✅ Network interruption handling

### 4. Non-Group Expense Splitting Functionality

#### **4.1 Add Person Button Visibility**
**Objective**: Verify Add Person button appears only for non-group expenses

**Steps**:
1. Navigate to Add Expense Screen
2. **Expected**: "Add Person" button is visible (no group selected)
3. Select a group from dropdown
4. **Expected**: "Add Person" button disappears
5. Select "None" again
6. **Expected**: "Add Person" button reappears

**Test Cases**:
- ✅ Button visibility logic
- ✅ Group selection changes
- ✅ Multiple group switches

#### **4.2 Manual Member Addition**
**Objective**: Verify manual member addition works correctly

**Steps**:
1. Navigate to Add Expense Screen
2. Tap "Add Person" button
3. Enter a name in the text field
4. Press Enter or tap outside
5. **Expected**: Member is added to the list
6. **Expected**: Member is auto-selected for splitting
7. **Expected**: Split calculation updates

**Test Cases**:
- ✅ Single member addition
- ✅ Multiple member additions
- ✅ Duplicate member names
- ✅ Empty name validation
- ✅ Special characters in names

#### **4.3 Contact Integration**
**Objective**: Verify contact import functionality

**Steps**:
1. Navigate to Add Expense Screen
2. Tap "Add Person" button
3. **Expected**: Contact list appears (if permission granted)
4. Tap on a contact
5. **Expected**: Contact is added to expense members
6. **Expected**: Contact name is used

**Test Cases**:
- ✅ Contact permission granted
- ✅ Contact permission denied
- ✅ No contacts available
- ✅ Large contact list
- ✅ Contact with special characters

#### **4.4 Non-Group Expense Validation**
**Objective**: Verify proper validation for non-group expenses

**Steps**:
1. Navigate to Add Expense Screen
2. Fill in description and amount
3. Try to save without adding members
4. **Expected**: Error message about needing members
5. Add only current user
6. **Expected**: Error message about needing more people
7. Add at least one more person
8. **Expected**: Expense can be saved

**Test Cases**:
- ✅ No members added
- ✅ Only current user selected
- ✅ Valid member combination
- ✅ Large number of members

#### **4.5 Split Calculation Accuracy**
**Objective**: Verify accurate split calculations

**Steps**:
1. Create non-group expense with amount ₹100
2. Add 2 members (including current user)
3. **Expected**: Split shows ₹50.00 per person
4. Add 3rd member
5. **Expected**: Split shows ₹33.33 per person
6. Test with odd amounts (₹101 with 3 people)
7. **Expected**: Proper rounding applied

**Test Cases**:
- ✅ Even splits
- ✅ Odd amounts with rounding
- ✅ Large amounts
- ✅ Small amounts
- ✅ Many members

#### **4.6 Non-Group Expense Storage**
**Objective**: Verify non-group expenses are stored correctly

**Steps**:
1. Create a non-group expense
2. Add members and save
3. Navigate to expense lists
4. **Expected**: Expense appears in non-group expenses
5. **Expected**: Expense appears in "My Expenses"
6. **Expected**: Group ID is empty in database

**Test Cases**:
- ✅ Storage location verification
- ✅ Data structure validation
- ✅ Multiple non-group expenses
- ✅ Mixed group/non-group expenses

### 5. Error Handling and Edge Cases

#### **5.1 Network Error Handling**
**Objective**: Verify graceful handling of network errors

**Steps**:
1. Disconnect network connection
2. Try to create expense/group
3. **Expected**: Error message displayed
4. **Expected**: No app crash
5. **Expected**: Retry functionality works

**Test Cases**:
- ✅ Network disconnection
- ✅ Slow network
- ✅ Firebase timeout
- ✅ Authentication errors

#### **5.2 Permission Handling**
**Objective**: Verify contact permission handling

**Steps**:
1. Deny contact permission
2. Try to add person from contacts
3. **Expected**: Permission request dialog
4. **Expected**: Graceful fallback to manual entry
5. **Expected**: No app crash

**Test Cases**:
- ✅ Permission denied
- ✅ Permission revoked
- ✅ Permission granted
- ✅ Permission request timeout

#### **5.3 Input Validation**
**Objective**: Verify proper input validation

**Steps**:
1. Try to save with empty fields
2. **Expected**: Validation error messages
3. Try invalid amounts (negative, zero, text)
4. **Expected**: Appropriate error messages
5. Try special characters in names
6. **Expected**: Proper handling

**Test Cases**:
- ✅ Empty required fields
- ✅ Invalid amounts
- ✅ Special characters
- ✅ Very long inputs
- ✅ Unicode characters

## Test Execution Checklist

### **Pre-Test Setup**
- [ ] Flutter environment is ready
- [ ] Firebase project is configured
- [ ] Test device/emulator is available
- [ ] Test user accounts are created
- [ ] Network connection is stable

### **Test Execution**
- [ ] All button interaction tests completed
- [ ] All data persistence tests completed
- [ ] All settle up screen tests completed
- [ ] All non-group expense tests completed
- [ ] All error handling tests completed

### **Post-Test Verification**
- [ ] All expected behaviors confirmed
- [ ] No UI freezes observed
- [ ] All loading states work correctly
- [ ] Data persistence is reliable
- [ ] Real-time updates function properly
- [ ] Error handling is graceful

## Expected Results Summary

### **Button Interactions** ✅
- All buttons show proper loading states
- No UI freezes during async operations
- Proper error handling and user feedback
- Re-entrant call prevention works

### **Data Persistence** ✅
- All data is saved correctly to database
- Deletion operations work properly
- Data consistency maintained
- Offline scenarios handled gracefully

### **Settle Up Screen** ✅
- Only unsettled transactions displayed
- Real-time updates work correctly
- "To Give" and "To Get" labels are clear
- Settlement marking removes transactions immediately

### **Non-Group Expenses** ✅
- Add Person button appears only when appropriate
- Manual and contact-based member addition works
- Proper validation prevents invalid states
- Split calculations are accurate
- Storage structure is correct

### **Error Handling** ✅
- Network errors handled gracefully
- Permission issues handled properly
- Input validation works correctly
- No app crashes during error scenarios

## Notes
- All tests should be performed on both Android and iOS if possible
- Test with different screen sizes and orientations
- Verify accessibility features work correctly
- Test with different network conditions
- Document any issues found during testing
