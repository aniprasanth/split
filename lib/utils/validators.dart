class Validators {
  // RegEx patterns
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _phoneRegExp = RegExp(
    r'^[+]?[0-9]{10,15}$',
  );

  static final RegExp _indianPhoneRegExp = RegExp(
    r'^[+]?[91]?[6-9]\d{9}$',
  );

  static final RegExp _alphaNumericRegExp = RegExp(
    r'^[a-zA-Z0-9\s]+$',
  );

  static final RegExp _alphaOnlyRegExp = RegExp(
    r'^[a-zA-Z\s]+$',
  );

  static final RegExp _numericOnlyRegExp = RegExp(
    r'^[0-9]+$',
  );

  /// Validate amount/money input
  static String? validateAmount(String? value, {
    double? minAmount,
    double? maxAmount,
    bool allowZero = false,
    String? fieldName,
  }) {
    final field = fieldName ?? 'Amount';

    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }

    // Remove currency symbols and commas
    final cleanValue = value.replaceAll(RegExp(r'[^\d.-]'), '');
    final amount = double.tryParse(cleanValue);

    if (amount == null) {
      return 'Enter a valid $field';
    }

    if (!allowZero && amount <= 0) {
      return '$field must be greater than 0';
    }

    if (allowZero && amount < 0) {
      return '$field cannot be negative';
    }

    if (minAmount != null && amount < minAmount) {
      return '$field must be at least ₹${minAmount.toStringAsFixed(2)}';
    }

    if (maxAmount != null && amount > maxAmount) {
      return '$field cannot exceed ₹${maxAmount.toStringAsFixed(2)}';
    }

    // Check decimal places (max 2)
    if (cleanValue.contains('.')) {
      final parts = cleanValue.split('.');
      if (parts.length > 1 && parts[1].length > 2) {
        return '$field can have maximum 2 decimal places';
      }
    }

    return null;
  }

  /// Validate name input
  static String? validateName(String? value, {
    int? minLength,
    int? maxLength,
    bool allowNumbers = false,
    bool allowSpecialChars = false,
    String? fieldName,
  }) {
    final field = fieldName ?? 'Name';

    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }

    final trimmedValue = value.trim();

    if (minLength != null && trimmedValue.length < minLength) {
      return '$field must be at least $minLength characters';
    }

    if (maxLength != null && trimmedValue.length > maxLength) {
      return '$field cannot exceed $maxLength characters';
    }

    if (!allowNumbers && !allowSpecialChars) {
      if (!_alphaOnlyRegExp.hasMatch(trimmedValue)) {
        return '$field can only contain letters and spaces';
      }
    } else if (!allowSpecialChars) {
      if (!_alphaNumericRegExp.hasMatch(trimmedValue)) {
        return '$field can only contain letters, numbers, and spaces';
      }
    }

    // Check for consecutive spaces
    if (trimmedValue.contains('  ')) {
      return '$field cannot have consecutive spaces';
    }

    // Check if starts or ends with space (after trim, this shouldn't happen)
    if (value.startsWith(' ') || value.endsWith(' ')) {
      return '$field cannot start or end with spaces';
    }

    return null;
  }

  /// Validate email address
  static String? validateEmail(String? value, {
    bool required = true,
    String? fieldName,
  }) {
    final field = fieldName ?? 'Email';

    if (value == null || value.trim().isEmpty) {
      return required ? '$field is required' : null;
    }

    final trimmedValue = value.trim().toLowerCase();

    if (!_emailRegExp.hasMatch(trimmedValue)) {
      return 'Enter a valid $field address';
    }

    // Additional checks
    if (trimmedValue.length > 254) {
      return '$field address is too long';
    }

    final domain = trimmedValue.split('@').last;

    if (domain.contains('..') || domain.startsWith('.') || domain.endsWith('.')) {
      return 'Enter a valid $field address';
    }

    return null;
  }

  /// Validate password
  static String? validatePassword(String? value, {
    int minLength = 8,
    int maxLength = 128,
    bool requireUppercase = true,
    bool requireLowercase = true,
    bool requireNumbers = true,
    bool requireSpecialChars = true,
    String? fieldName,
  }) {
    final field = fieldName ?? 'Password';

    if (value == null || value.isEmpty) {
      return '$field is required';
    }

    if (value.length < minLength) {
      return '$field must be at least $minLength characters';
    }

    if (value.length > maxLength) {
      return '$field cannot exceed $maxLength characters';
    }

    if (requireUppercase && !value.contains(RegExp(r'[A-Z]'))) {
      return '$field must contain at least one uppercase letter';
    }

    if (requireLowercase && !value.contains(RegExp(r'[a-z]'))) {
      return '$field must contain at least one lowercase letter';
    }

    if (requireNumbers && !value.contains(RegExp(r'[0-9]'))) {
      return '$field must contain at least one number';
    }

    if (requireSpecialChars && !value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return '$field must contain at least one special character';
    }

    // Check for common weak passwords
    final weakPasswords = [
      'password', 'password123', '12345678', 'qwerty123',
      'abc123456', 'password1', '123456789', 'welcome123'
    ];

    if (weakPasswords.contains(value.toLowerCase())) {
      return '$field is too common. Choose a stronger password';
    }

    return null;
  }

  /// Validate password confirmation
  static String? validatePasswordConfirmation(
      String? value,
      String? originalPassword, {
        String? fieldName,
      }) {
    final field = fieldName ?? 'Confirm Password';

    if (value == null || value.isEmpty) {
      return '$field is required';
    }

    if (value != originalPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Validate phone number
  static String? validatePhoneNumber(String? value, {
    bool required = true,
    bool indianOnly = true,
    String? fieldName,
  }) {
    final field = fieldName ?? 'Phone number';

    if (value == null || value.trim().isEmpty) {
      return required ? '$field is required' : null;
    }

    // Remove spaces, dashes, and brackets
    final cleanValue = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (indianOnly) {
      if (!_indianPhoneRegExp.hasMatch(cleanValue)) {
        return 'Enter a valid Indian $field (10 digits)';
      }
    } else {
      if (!_phoneRegExp.hasMatch(cleanValue)) {
        return 'Enter a valid $field';
      }
    }

    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, {String? fieldName}) {
    final field = fieldName ?? 'Field';

    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }

    return null;
  }

  /// Validate minimum length
  static String? validateMinLength(String? value, int minLength, {String? fieldName}) {
    final field = fieldName ?? 'Field';

    if (value == null) {
      return '$field is required';
    }

    if (value.length < minLength) {
      return '$field must be at least $minLength characters';
    }

    return null;
  }

  /// Validate maximum length
  static String? validateMaxLength(String? value, int maxLength, {String? fieldName}) {
    final field = fieldName ?? 'Field';

    if (value != null && value.length > maxLength) {
      return '$field cannot exceed $maxLength characters';
    }

    return null;
  }

  /// Validate numeric input
  static String? validateNumeric(String? value, {
    bool required = true,
    int? minValue,
    int? maxValue,
    String? fieldName,
  }) {
    final field = fieldName ?? 'Number';

    if (value == null || value.trim().isEmpty) {
      return required ? '$field is required' : null;
    }

    final number = int.tryParse(value.trim());

    if (number == null) {
      return 'Enter a valid $field';
    }

    if (minValue != null && number < minValue) {
      return '$field must be at least $minValue';
    }

    if (maxValue != null && number > maxValue) {
      return '$field cannot exceed $maxValue';
    }

    return null;
  }

  /// Validate URL
  static String? validateUrl(String? value, {
    bool required = true,
    String? fieldName,
  }) {
    final field = fieldName ?? 'URL';

    if (value == null || value.trim().isEmpty) {
      return required ? '$field is required' : null;
    }

    try {
      final uri = Uri.parse(value.trim());
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        return 'Enter a valid $field (must start with http:// or https://)';
      }
      return null;
    } catch (e) {
      return 'Enter a valid $field';
    }
  }

  /// Validate date
  static String? validateDate(String? value, {
    bool required = true,
    DateTime? minDate,
    DateTime? maxDate,
    String? fieldName,
  }) {
    final field = fieldName ?? 'Date';

    if (value == null || value.trim().isEmpty) {
      return required ? '$field is required' : null;
    }

    try {
      final date = DateTime.parse(value.trim());

      if (minDate != null && date.isBefore(minDate)) {
        return '$field cannot be before ${minDate.toString().split(' ')[0]}';
      }

      if (maxDate != null && date.isAfter(maxDate)) {
        return '$field cannot be after ${maxDate.toString().split(' ')[0]}';
      }

      return null;
    } catch (e) {
      return 'Enter a valid $field';
    }
  }

  /// Validate age
  static String? validateAge(String? value, {
    int minAge = 0,
    int maxAge = 150,
    String? fieldName,
  }) {
    final field = fieldName ?? 'Age';

    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }

    final age = int.tryParse(value.trim());

    if (age == null) {
      return 'Enter a valid $field';
    }

    if (age < minAge) {
      return '$field must be at least $minAge';
    }

    if (age > maxAge) {
      return '$field cannot exceed $maxAge';
    }

    return null;
  }

  /// Validate percentage
  static String? validatePercentage(String? value, {
    bool required = true,
    double minValue = 0.0,
    double maxValue = 100.0,
    String? fieldName,
  }) {
    final field = fieldName ?? 'Percentage';

    if (value == null || value.trim().isEmpty) {
      return required ? '$field is required' : null;
    }

    final cleanValue = value.replaceAll('%', '').trim();
    final percentage = double.tryParse(cleanValue);

    if (percentage == null) {
      return 'Enter a valid $field';
    }

    if (percentage < minValue) {
      return '$field must be at least $minValue%';
    }

    if (percentage > maxValue) {
      return '$field cannot exceed $maxValue%';
    }

    return null;
  }

  /// Validate expense description (optional)
  static String? validateExpenseDescription(String? value) {
    // Allow empty descriptions
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    
    return validateName(
      value,
      minLength: 1,
      maxLength: 100,
      allowNumbers: true,
      allowSpecialChars: true,
      fieldName: 'Description',
    );
  }

  /// Validate selection (list not empty)
  static String? validateSelection(
      List<dynamic>? selection, {
        String? fieldName,
      }) {
    final field = fieldName ?? 'selection';

    if (selection == null || selection.isEmpty) {
      return 'Please select at least one $field';
    }

    return null;
  }

  /// Validate group name
  static String? validateGroupName(String? value) {
    return validateName(
      value,
      minLength: 2,
      maxLength: 50,
      allowNumbers: true,
      allowSpecialChars: true,
      fieldName: 'Group name',
    );
  }

  /// Validate expense category
  static String? validateCategory(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select a category';
    }
    return null;
  }

  /// Validate split amounts (for custom splits)
  static String? validateSplitAmounts(Map<String, double> splits, double totalAmount) {
    if (splits.isEmpty) {
      return 'At least one person must be selected';
    }

    final splitSum = splits.values.fold<double>(0.0, (sum, amount) => sum + amount);

    if ((splitSum - totalAmount).abs() > 0.01) {
      return 'Split amounts must equal the total amount (₹${totalAmount.toStringAsFixed(2)})';
    }

    for (final entry in splits.entries) {
      if (entry.value < 0) {
        return 'Split amounts cannot be negative';
      }
      if (entry.value > totalAmount) {
        return 'Individual split cannot exceed total amount';
      }
    }

    return null;
  }

  /// Custom validator that combines multiple validators
  static String? combineValidators(String? value, List<String? Function(String?)> validators) {
    for (final validator in validators) {
      final result = validator(value);
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  /// Validate input against a list of forbidden values
  static String? validateNotIn(String? value, List<String> forbiddenValues, {String? fieldName}) {
    final field = fieldName ?? 'Field';

    if (value != null && forbiddenValues.contains(value.trim())) {
      return '$field is not allowed';
    }

    return null;
  }

  /// Validate input against a list of allowed values
  static String? validateIn(String? value, List<String> allowedValues, {String? fieldName}) {
    final field = fieldName ?? 'Field';

    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }

    if (!allowedValues.contains(value.trim())) {
      return 'Invalid $field selected';
    }

    return null;
  }

  /// Validate credit card number (basic Luhn algorithm)
  static String? validateCreditCard(String? value, {String? fieldName}) {
    final field = fieldName ?? 'Card number';

    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }

    final cleanValue = value.replaceAll(RegExp(r'[\s-]'), '');

    if (!_numericOnlyRegExp.hasMatch(cleanValue)) {
      return 'Enter a valid $field';
    }

    if (cleanValue.length < 13 || cleanValue.length > 19) {
      return '$field must be between 13-19 digits';
    }

    // Luhn algorithm check
    int sum = 0;
    bool alternate = false;

    for (int i = cleanValue.length - 1; i >= 0; i--) {
      int digit = int.parse(cleanValue[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    if (sum % 10 != 0) {
      return 'Enter a valid $field';
    }

    return null;
  }

  /// Get password strength (0-100)
  static int getPasswordStrength(String password) {
    if (password.isEmpty) return 0;

    int strength = 0;

    // Length scoring
    if (password.length >= 8) strength += 25;
    if (password.length >= 12) strength += 15;
    if (password.length >= 16) strength += 10;

    // Character variety scoring
    if (password.contains(RegExp(r'[a-z]'))) strength += 10;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 10;
    if (password.contains(RegExp(r'[0-9]'))) strength += 10;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 15;

    // Pattern variety
    if (!RegExp(r'(.)\1{2,}').hasMatch(password)) strength += 5; // No repeated chars
    if (!RegExp(r'(012|123|234|345|456|567|678|789|890)').hasMatch(password)) strength += 5;
    if (!RegExp(r'(abc|bcd|cde|def|efg|fgh|ghi|hij|ijk|jkl|klm|lmn|mno|nop|opq|pqr|qrs|rst|stu|tuv|uvw|vwx|wxy|xyz)').hasMatch(password.toLowerCase())) strength += 5;

    return strength.clamp(0, 100);
  }

  /// Get password strength text
  static String getPasswordStrengthText(int strength) {
    if (strength < 30) return 'Weak';
    if (strength < 60) return 'Fair';
    if (strength < 80) return 'Good';
    return 'Strong';
  }

  /// Get password strength color
  static int getPasswordStrengthColor(int strength) {
    if (strength < 30) return 0xFFE53E3E; // Red
    if (strength < 60) return 0xFFFF8C00; // Orange
    if (strength < 80) return 0xFFFFC107; // Amber
    return 0xFF4CAF50; // Green
  }

  /// Validate expense split equal distribution
  static String? validateEqualSplit(int memberCount, double totalAmount) {
    if (memberCount <= 0) {
      return 'At least one member must be selected';
    }

    if (totalAmount <= 0) {
      return 'Total amount must be greater than 0';
    }

    final splitAmount = totalAmount / memberCount;
    if (splitAmount < 0.01) {
      return 'Split amount is too small (less than ₹0.01)';
    }

    return null;
  }

  /// Validate expense split percentages
  static String? validatePercentageSplit(Map<String, double> percentages) {
    if (percentages.isEmpty) {
      return 'At least one person must be selected';
    }

    final totalPercentage = percentages.values.fold<double>(0.0, (sum, pct) => sum + pct);

    if ((totalPercentage - 100.0).abs() > 0.01) {
      return 'Percentages must total 100%';
    }

    for (final entry in percentages.entries) {
      if (entry.value < 0) {
        return 'Percentages cannot be negative';
      }
      if (entry.value > 100) {
        return 'Individual percentage cannot exceed 100%';
      }
    }

    return null;
  }

  /// Validate expense shares (for share-based splits)
  static String? validateShareSplit(Map<String, int> shares) {
    if (shares.isEmpty) {
      return 'At least one person must be selected';
    }

    for (final entry in shares.entries) {
      if (entry.value <= 0) {
        return 'Shares must be positive numbers';
      }
      if (entry.value > 1000) {
        return 'Individual shares cannot exceed 1000';
      }
    }

    final totalShares = shares.values.fold<int>(0, (sum, shares) => sum + shares);
    if (totalShares <= 0) {
      return 'Total shares must be greater than 0';
    }

    return null;
  }

  /// Validate settlement amount
  static String? validateSettlementAmount(String? value, double maxOwed) {
    final amountError = validateAmount(value, fieldName: 'Settlement amount');
    if (amountError != null) return amountError;

    final amount = double.tryParse(value?.replaceAll(RegExp(r'[^\d.-]'), '') ?? '0') ?? 0;

    if (amount > maxOwed + 0.01) {
      return 'Settlement amount cannot exceed owed amount (₹${maxOwed.toStringAsFixed(2)})';
    }

    return null;
  }

  /// Validate group member limit
  static String? validateGroupMemberLimit(List<String> members, {int maxMembers = 50}) {
    if (members.isEmpty) {
      return 'Group must have at least one member';
    }

    if (members.length > maxMembers) {
      return 'Group cannot have more than $maxMembers members';
    }

    return null;
  }

  /// Validate date range
  static String? validateDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null) {
      return 'Start date is required';
    }

    if (endDate == null) {
      return 'End date is required';
    }

    if (endDate.isBefore(startDate)) {
      return 'End date must be after start date';
    }

    final difference = endDate.difference(startDate);
    if (difference.inDays > 365) {
      return 'Date range cannot exceed 1 year';
    }

    return null;
  }

  /// Validate expense date (cannot be too far in future)
  static String? validateExpenseDate(DateTime? date) {
    if (date == null) {
      return 'Date is required';
    }

    final now = DateTime.now();
    final maxFutureDate = now.add(const Duration(days: 30));
    final minPastDate = now.subtract(const Duration(days: 365 * 2)); // 2 years ago

    if (date.isAfter(maxFutureDate)) {
      return 'Expense date cannot be more than 30 days in the future';
    }

    if (date.isBefore(minPastDate)) {
      return 'Expense date cannot be more than 2 years ago';
    }

    return null;
  }

  /// Validate currency code
  static String? validateCurrencyCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Currency is required';
    }

    final validCurrencies = ['INR', 'USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'SGD', 'CNY'];

    if (!validCurrencies.contains(value.trim().toUpperCase())) {
      return 'Invalid currency selected';
    }

    return null;
  }

  /// Validate receipt image file
  static String? validateReceiptFile(String? filePath, int? fileSizeBytes) {
    if (filePath == null || filePath.isEmpty) {
      return null; // Optional field
    }

    final validExtensions = ['.jpg', '.jpeg', '.png', '.pdf'];
    final hasValidExtension = validExtensions.any((ext) =>
        filePath.toLowerCase().endsWith(ext));

    if (!hasValidExtension) {
      return 'Invalid file format. Only JPG, PNG, and PDF files are allowed';
    }

    if (fileSizeBytes != null) {
      const maxSizeBytes = 10 * 1024 * 1024; // 10MB
      if (fileSizeBytes > maxSizeBytes) {
        return 'File size cannot exceed 10MB';
      }
    }

    return null;
  }

  /// Validate UPI ID
  static String? validateUpiId(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'UPI ID is required' : null;
    }

    final upiRegex = RegExp(r'^[a-zA-Z0-9.\-_]{2,49}@[a-zA-Z]{2,49}$');

    if (!upiRegex.hasMatch(value.trim())) {
      return 'Enter a valid UPI ID (e.g., user@paytm)';
    }

    return null;
  }

  /// Validate bank account number
  static String? validateAccountNumber(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Account number is required' : null;
    }

    final cleanValue = value.replaceAll(RegExp(r'[\s-]'), '');

    if (!_numericOnlyRegExp.hasMatch(cleanValue)) {
      return 'Account number can only contain digits';
    }

    if (cleanValue.length < 9 || cleanValue.length > 18) {
      return 'Account number must be between 9-18 digits';
    }

    return null;
  }

  /// Validate IFSC code
  static String? validateIfscCode(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'IFSC code is required' : null;
    }

    final ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');

    if (!ifscRegex.hasMatch(value.trim().toUpperCase())) {
      return 'Enter a valid IFSC code (e.g., HDFC0001234)';
    }

    return null;
  }

  /// Validate expense tags
  static String? validateExpenseTags(List<String> tags) {
    if (tags.length > 10) {
      return 'Cannot add more than 10 tags';
    }

    for (final tag in tags) {
      if (tag.trim().isEmpty) {
        return 'Tags cannot be empty';
      }
      if (tag.length > 20) {
        return 'Each tag must be 20 characters or less';
      }
      if (!RegExp(r'^[a-zA-Z0-9\s]+$').hasMatch(tag)) {
        return 'Tags can only contain letters, numbers, and spaces';
      }
    }

    // Check for duplicate tags
    final uniqueTags = tags.map((tag) => tag.toLowerCase().trim()).toSet();
    if (uniqueTags.length != tags.length) {
      return 'Duplicate tags are not allowed';
    }

    return null;
  }

  /// Validate group description
  static String? validateGroupDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }

    if (value.trim().length > 200) {
      return 'Description cannot exceed 200 characters';
    }

    return null;
  }

  /// Validate expense notes
  static String? validateExpenseNotes(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }

    if (value.trim().length > 500) {
      return 'Notes cannot exceed 500 characters';
    }

    return null;
  }

  /// Validate search query
  static String? validateSearchQuery(String? value, {int minLength = 2}) {
    if (value == null || value.trim().isEmpty) {
      return 'Search query is required';
    }

    if (value.trim().length < minLength) {
      return 'Search query must be at least $minLength characters';
    }

    if (value.trim().length > 100) {
      return 'Search query cannot exceed 100 characters';
    }

    return null;
  }

  /// Validate multiple selection with limits
  static String? validateMultipleSelection(
      List<dynamic> selectedItems, {
        int? minSelection,
        int? maxSelection,
        String? fieldName,
      }) {
    final field = fieldName ?? 'items';

    if (minSelection != null && selectedItems.length < minSelection) {
      return 'Please select at least $minSelection $field';
    }

    if (maxSelection != null && selectedItems.length > maxSelection) {
      return 'Cannot select more than $maxSelection $field';
    }

    return null;
  }

  /// Validate form completeness (for multi-step forms)
  static String? validateFormStep(Map<String, dynamic> formData, List<String> requiredFields) {
    for (final field in requiredFields) {
      final value = formData[field];
      if (value == null ||
          (value is String && value.trim().isEmpty) ||
          (value is List && value.isEmpty)) {
        return 'Please complete all required fields';
      }
    }
    return null;
  }
}