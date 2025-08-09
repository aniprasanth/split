# Splitzy Documentation

This directory contains documentation for the Splitzy expense splitting app.

## 📁 Documentation Files

### 📋 [TEST_CHECKLIST.md](./TEST_CHECKLIST.md)
Comprehensive test checklist and functionality verification guide:
- **Purpose**: Verify all app functionality works correctly
- **Content**: 
  - List of all fixed issues
  - Manual testing scenarios
  - Step-by-step testing instructions
  - Developer notes and best practices
- **Usage**: Use this before releasing updates or when onboarding new developers

## 📱 App Overview

Splitzy is a minimal expense splitting app built with Flutter, similar to Splitwise. It allows users to:
- Create groups and add members
- Split expenses among group members or between two people
- Track payments and settlements
- View expense history and summaries

## 🛠 Development Notes

### Key Technologies
- **Frontend**: Flutter/Dart
- **Backend**: Firebase (Firestore, Auth)
- **State Management**: Provider
- **Local Storage**: Hive
- **Authentication**: Google Sign-In

### Project Structure
```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
├── screens/                  # UI screens
├── services/                 # Business logic and API calls
├── utils/                    # Utilities and helpers
└── widgets/                  # Reusable UI components
```

### Recent Major Fixes (Latest Update)
1. **Google Sign-In**: Fixed stuck loading screen issue
2. **Group Creation**: Fixed create group button and contacts search
3. **Expense Management**: Fixed add expense functionality and member selection
4. **UI/UX**: Removed plus button from settings, added separate expense screens
5. **Code Quality**: Improved error handling and state management

## 🧪 Testing

Refer to [TEST_CHECKLIST.md](./TEST_CHECKLIST.md) for comprehensive testing instructions.

## 📝 Contributing

When making changes to the app:
1. Update relevant documentation
2. Run through the test checklist
3. Ensure all Provider.of calls use `listen: false` where appropriate
4. Add proper mounted checks for async operations
5. Handle all error states gracefully
