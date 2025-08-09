import 'package:intl/intl.dart';

class Formatters {
  // Currency formats for different locales
  static const Map<String, Map<String, String>> _currencyFormats = {
    'INR': {'locale': 'en_IN', 'symbol': '₹'},
    'USD': {'locale': 'en_US', 'symbol': '\$'},
    'EUR': {'locale': 'de_DE', 'symbol': '€'},
    'GBP': {'locale': 'en_GB', 'symbol': '£'},
    'JPY': {'locale': 'ja_JP', 'symbol': '¥'},
    'CAD': {'locale': 'en_CA', 'symbol': 'C\$'},
    'AUD': {'locale': 'en_AU', 'symbol': 'A\$'},
    'SGD': {'locale': 'en_SG', 'symbol': 'S\$'},
    'CNY': {'locale': 'zh_CN', 'symbol': '¥'},
  };

  static String _defaultCurrency = 'INR';

  /// Set default currency for the app
  static void setDefaultCurrency(String currencyCode) {
    if (_currencyFormats.containsKey(currencyCode)) {
      _defaultCurrency = currencyCode;
    }
  }

  /// Get default currency
  static String get defaultCurrency => _defaultCurrency;

  /// Format date in various styles
  static String formatDate(DateTime date, {DateStyle style = DateStyle.medium}) {
    switch (style) {
      case DateStyle.short:
        return DateFormat('dd/MM/yy').format(date);
      case DateStyle.medium:
        return DateFormat('dd MMM yyyy').format(date);
      case DateStyle.long:
        return DateFormat('dd MMMM yyyy').format(date);
      case DateStyle.full:
        return DateFormat('EEEE, dd MMMM yyyy').format(date);
      case DateStyle.compact:
        return DateFormat('dd-MM-yyyy').format(date);
    }
  }

  /// Format date with time
  static String formatDateTime(DateTime dateTime, {DateTimeStyle style = DateTimeStyle.medium}) {
    switch (style) {
      case DateTimeStyle.short:
        return DateFormat('dd/MM/yy, HH:mm').format(dateTime);
      case DateTimeStyle.medium:
        return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
      case DateTimeStyle.long:
        return DateFormat('dd MMMM yyyy, HH:mm:ss').format(dateTime);
      case DateTimeStyle.full:
        return DateFormat('EEEE, dd MMMM yyyy, HH:mm:ss').format(dateTime);
    }
  }

  /// Format time in different formats
  static String formatTime(DateTime time, {TimeStyle style = TimeStyle.standard}) {
    switch (style) {
      case TimeStyle.standard:
        return DateFormat.jm().format(time);
      case TimeStyle.military:
        return DateFormat('HH:mm').format(time);
      case TimeStyle.withSeconds:
        return DateFormat('HH:mm:ss').format(time);
      case TimeStyle.withSecondsAmPm:
        return DateFormat('h:mm:ss a').format(time);
    }
  }

  /// Format currency with default currency
  static String formatCurrency(double amount, {String? currencyCode, bool showSymbol = true}) {
    final currency = currencyCode ?? _defaultCurrency;
    final currencyInfo = _currencyFormats[currency];
    
    if (currencyInfo == null) {
      // Fallback to default currency
      return formatCurrency(amount, currencyCode: _defaultCurrency, showSymbol: showSymbol);
    }

    final format = NumberFormat.currency(
      locale: currencyInfo['locale']!,
      symbol: showSymbol ? currencyInfo['symbol']! : '',
      decimalDigits: _getDecimalDigits(currency),
    );
    
    return format.format(amount);
  }

  /// Format currency without symbol
  static String formatCurrencyWithoutSymbol(double amount, {String? currencyCode}) {
    return formatCurrency(amount, currencyCode: currencyCode, showSymbol: false);
  }

  /// Format large numbers with K, M, B suffixes
  static String formatCompactCurrency(double amount, {String? currencyCode}) {
    final currency = currencyCode ?? _defaultCurrency;
    final currencyInfo = _currencyFormats[currency];
    final symbol = currencyInfo?['symbol'] ?? '₹';
    
    if (amount >= 1000000000) {
      return '$symbol${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return '$symbol${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return formatCurrency(amount, currencyCode: currencyCode);
    }
  }

  /// Format number with commas
  static String formatNumber(double number, {int decimalPlaces = 2}) {
    final formatter = NumberFormat('#,##0.00');
    return formatter.format(number);
  }

  /// Format percentage
  static String formatPercentage(double value, {int decimalPlaces = 1}) {
    final formatter = NumberFormat.percentPattern();
    formatter.minimumFractionDigits = decimalPlaces;
    formatter.maximumFractionDigits = decimalPlaces;
    return formatter.format(value / 100);
  }

  /// Format relative time (e.g., "2 hours ago", "yesterday")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /// Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Format duration
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h ${duration.inMinutes % 60}m';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Format phone number
  static String formatPhoneNumber(String phoneNumber) {
    // Remove all non-numeric characters
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanNumber.length == 10) {
      // Indian format: +91 XXXXX XXXXX
      return '+91 ${cleanNumber.substring(0, 5)} ${cleanNumber.substring(5)}';
    } else if (cleanNumber.length == 12 && cleanNumber.startsWith('91')) {
      // Already has country code
      return '+${cleanNumber.substring(0, 2)} ${cleanNumber.substring(2, 7)} ${cleanNumber.substring(7)}';
    } else if (cleanNumber.length == 13 && cleanNumber.startsWith('091')) {
      // With leading zero
      return '+91 ${cleanNumber.substring(3, 8)} ${cleanNumber.substring(8)}';
    }
    
    return phoneNumber; // Return as-is if format not recognized
  }

  /// Format name with proper capitalization
  static String formatName(String name) {
    return name
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  /// Format initials from name
  static String getInitials(String name, {int maxInitials = 2}) {
    final words = name.trim().split(' ').where((word) => word.isNotEmpty).toList();
    
    if (words.isEmpty) return '';
    
    final initials = words.take(maxInitials).map((word) => word[0].toUpperCase()).join();
    return initials;
  }

  /// Format decimal places
  static String formatDecimal(double value, {int decimalPlaces = 2}) {
    return value.toStringAsFixed(decimalPlaces);
  }

  /// Get decimal digits for currency
  static int _getDecimalDigits(String currencyCode) {
    switch (currencyCode) {
      case 'JPY':
      case 'KRW':
        return 0; // These currencies don't use decimal places
      default:
        return 2;
    }
  }

  /// Parse currency string to double
  static double? parseCurrency(String currencyString) {
    try {
      // Remove currency symbols and commas
      final cleanString = currencyString.replaceAll(RegExp(r'[^\d.-]'), '');
      return double.parse(cleanString);
    } catch (e) {
      return null;
    }
  }

  /// Format balance with color indication
  static Map<String, dynamic> formatBalance(double balance, {String? currencyCode}) {
    return {
      'formatted': formatCurrency(balance.abs(), currencyCode: currencyCode),
      'isPositive': balance >= 0,
      'isZero': balance.abs() < 0.01,
    };
  }

  /// Format split amount for display
  static String formatSplitAmount(double totalAmount, int splitCount, {String? currencyCode}) {
    if (splitCount <= 0) return formatCurrency(0, currencyCode: currencyCode);
    
    final splitAmount = totalAmount / splitCount;
    return formatCurrency(splitAmount, currencyCode: currencyCode);
  }

  /// Get available currencies
  static List<String> getAvailableCurrencies() {
    return _currencyFormats.keys.toList();
  }

  /// Get currency symbol
  static String getCurrencySymbol(String currencyCode) {
    return _currencyFormats[currencyCode]?['symbol'] ?? '₹';
  }

  /// Get currency name
  static String getCurrencyName(String currencyCode) {
    const currencyNames = {
      'INR': 'Indian Rupee',
      'USD': 'US Dollar',
      'EUR': 'Euro',
      'GBP': 'British Pound',
      'JPY': 'Japanese Yen',
      'CAD': 'Canadian Dollar',
      'AUD': 'Australian Dollar',
      'SGD': 'Singapore Dollar',
      'CNY': 'Chinese Yuan',
    };
    
    return currencyNames[currencyCode] ?? currencyCode;
  }
}

/// Date formatting styles
enum DateStyle {
  short,    // 01/01/24
  medium,   // 01 Jan 2024
  long,     // 01 January 2024
  full,     // Monday, 01 January 2024
  compact,  // 01-01-2024
}

/// DateTime formatting styles
enum DateTimeStyle {
  short,    // 01/01/24, 14:30
  medium,   // 01 Jan 2024, 14:30
  long,     // 01 January 2024, 14:30:00
  full,     // Monday, 01 January 2024, 14:30:00
}

/// Time formatting styles
enum TimeStyle {
  standard,         // 2:30 PM
  military,         // 14:30
  withSeconds,      // 14:30:00
  withSecondsAmPm,  // 2:30:00 PM
}