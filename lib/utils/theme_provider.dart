import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:logger/logger.dart';
import 'package:splitzy/services/local_storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  String _currentColorScheme = 'default';
  bool _useSystemAccentColor = false;
  double _textScaleFactor = 1.0;

  // Initialize logger
  final Logger _logger = Logger(
    printer: PrettyPrinter(),
    level: kReleaseMode ? Level.warning : Level.debug,
  );

  // Available color schemes - Updated with futuristic colors
  static const Map<String, Color> _colorSchemes = {
    'default': Color(0xFF6366F1), // Modern Indigo
    'neon_blue': Color(0xFF00D9FF), // Neon Blue
    'cyber_purple': Color(0xFF8B5CF6), // Cyber Purple
    'electric_green': Color(0xFF10B981), // Electric Green
    'neon_pink': Color(0xFFEC4899), // Neon Pink
    'cyber_orange': Color(0xFFFF6B35), // Cyber Orange
    'matrix_green': Color(0xFF00FF41), // Matrix Green
    'hologram_blue': Color(0xFF3B82F6), // Hologram Blue
  };

  // Getters
  ThemeMode get themeMode => _themeMode;
  String get currentColorScheme => _currentColorScheme;
  bool get useSystemAccentColor => _useSystemAccentColor;
  double get textScaleFactor => _textScaleFactor;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  Color get primaryColor =>
      _colorSchemes[_currentColorScheme] ?? _colorSchemes['default']!;
  List<String> get availableColorSchemes => _colorSchemes.keys.toList();

  ThemeProvider() {
    _loadThemePreferences();
  }

  /// Load saved theme preferences
  Future<void> _loadThemePreferences() async {
    try {
      final prefs = await LocalStorageService.loadUserPreferences();

      // Load theme mode
      final themeMode = prefs['themeMode'] as String?;
      switch (themeMode) {
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        default:
          _themeMode = ThemeMode.system;
      }

      // Load color scheme
      _currentColorScheme = prefs['colorScheme'] as String? ?? 'default';
      if (!_colorSchemes.containsKey(_currentColorScheme)) {
        _currentColorScheme = 'default';
      }

      // Load other preferences
      _useSystemAccentColor = prefs['useSystemAccentColor'] as bool? ?? false;
      _textScaleFactor = (prefs['textScaleFactor'] as double?) ?? 1.0;

      notifyListeners();
    } catch (e) {
      _logger.e('Error loading theme preferences: $e');
    }
  }

  /// Save theme preferences
  Future<void> _saveThemePreferences() async {
    try {
      final prefs = await LocalStorageService.loadUserPreferences();

      prefs['themeMode'] = _themeMode == ThemeMode.dark
          ? 'dark'
          : _themeMode == ThemeMode.light
          ? 'light'
          : 'system';
      prefs['colorScheme'] = _currentColorScheme;
      prefs['useSystemAccentColor'] = _useSystemAccentColor;
      prefs['textScaleFactor'] = _textScaleFactor;

      await LocalStorageService.saveUserPreferences(prefs);

      // Also save theme for backward compatibility
      await LocalStorageService.saveTheme(isDarkMode);
    } catch (e) {
      _logger.e('Error saving theme preferences: $e');
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await _saveThemePreferences();
      notifyListeners();
    }
  }

  /// Set color scheme
  Future<void> setColorScheme(String scheme) async {
    if (_colorSchemes.containsKey(scheme) && _currentColorScheme != scheme) {
      _currentColorScheme = scheme;
      await _saveThemePreferences();
      notifyListeners();
    }
  }

  /// Set system accent color usage
  Future<void> setUseSystemAccentColor(bool use) async {
    if (_useSystemAccentColor != use) {
      _useSystemAccentColor = use;
      await _saveThemePreferences();
      notifyListeners();
    }
  }

  /// Set text scale factor
  Future<void> setTextScaleFactor(double factor) async {
    if (_textScaleFactor != factor) {
      _textScaleFactor = factor;
      await _saveThemePreferences();
      notifyListeners();
    }
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final newMode =
    _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }

  /// Get light theme
  ThemeData get lightTheme {
    return _buildThemeData(Brightness.light);
  }

  /// Get dark theme
  ThemeData get darkTheme {
    return _buildThemeData(Brightness.dark);
  }

  /// Build theme data
  ThemeData _buildThemeData(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primaryColor = this.primaryColor;

    // Color scheme
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
      primary: primaryColor,
      secondary: primaryColor.withValues(alpha: 0.8),
      tertiary: primaryColor.withValues(alpha: 0.6),
      surface: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA),
      error: isDark ? const Color(0xFFCF6679) : const Color(0xFFB00020),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: isDark ? 2 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF404040) : const Color(0xFFE0E0E0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.grey[500] : Colors.grey[500],
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: primaryColor,
        unselectedItemColor: isDark ? Colors.grey[600] : Colors.grey[500],
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? const Color(0xFF404040) : const Color(0xFFE0E0E0),
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
        selectedColor: primaryColor.withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return isDark ? Colors.grey[400] : Colors.grey[300];
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return isDark ? Colors.grey[600] : Colors.grey[400];
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return isDark ? Colors.grey[600] : Colors.grey[400];
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: isDark ? Colors.grey[600] : Colors.grey[300],
        thumbColor: primaryColor,
        overlayColor: primaryColor.withValues(alpha: 0.2),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: isDark ? Colors.grey[600] : Colors.grey[300],
        circularTrackColor: isDark ? Colors.grey[600] : Colors.grey[300],
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF323232) : const Color(0xFF323232),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        contentTextStyle: TextStyle(
          fontSize: 16,
          color: colorScheme.onSurface,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 14,
          color: colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        leadingAndTrailingTextStyle: TextStyle(
          fontSize: 14,
          color: colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: isDark ? Colors.grey[600] : Colors.grey[500],
        indicatorColor: primaryColor,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        dataTextStyle: TextStyle(
          fontSize: 14,
          color: colorScheme.onSurface,
        ),
        dividerThickness: 1,
        columnSpacing: 16,
        horizontalMargin: 16,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF424242) : const Color(0xFF424242),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 16,
        ),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        textColor: primaryColor,
        iconColor: primaryColor,
        collapsedTextColor: colorScheme.onSurface,
        collapsedIconColor: colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      dividerColor: isDark ? const Color(0xFF404040) : const Color(0xFFE0E0E0),
      focusColor: primaryColor.withValues(alpha: 0.2),
      hoverColor: primaryColor.withValues(alpha: 0.1),
      splashColor: primaryColor.withValues(alpha: 0.2),
      highlightColor: primaryColor.withValues(alpha: 0.1),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: primaryColor.withValues(alpha: 0.3),
        selectionHandleColor: primaryColor,
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: 24,
      ),
      primaryIconTheme: IconThemeData(
        color: primaryColor,
        size: 24,
      ),
      textTheme: _buildTextTheme(colorScheme, isDark),
    );
  }

  /// Build text theme
  TextTheme _buildTextTheme(ColorScheme colorScheme, bool isDark) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 32 * _textScaleFactor,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28 * _textScaleFactor,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
        letterSpacing: -0.25,
      ),
      displaySmall: TextStyle(
        fontSize: 24 * _textScaleFactor,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      headlineLarge: TextStyle(
        fontSize: 22 * _textScaleFactor,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 20 * _textScaleFactor,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 18 * _textScaleFactor,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 16 * _textScaleFactor,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 14 * _textScaleFactor,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 12 * _textScaleFactor,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: 16 * _textScaleFactor,
        fontWeight: FontWeight.normal,
        color: colorScheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14 * _textScaleFactor,
        fontWeight: FontWeight.normal,
        color: colorScheme.onSurface,
      ),
      bodySmall: TextStyle(
        fontSize: 12 * _textScaleFactor,
        fontWeight: FontWeight.normal,
        color: colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      labelLarge: TextStyle(
        fontSize: 14 * _textScaleFactor,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: 12 * _textScaleFactor,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      labelSmall: TextStyle(
        fontSize: 10 * _textScaleFactor,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }

  /// Get color scheme display name
  String getColorSchemeDisplayName(String scheme) {
    switch (scheme) {
      case 'default':
        return 'Default';
      case 'neon_blue':
        return 'Neon Blue';
      case 'cyber_purple':
        return 'Cyber Purple';
      case 'electric_green':
        return 'Electric Green';
      case 'neon_pink':
        return 'Neon Pink';
      case 'cyber_orange':
        return 'Cyber Orange';
      case 'matrix_green':
        return 'Matrix Green';
      case 'hologram_blue':
        return 'Hologram Blue';
      default:
        return scheme;
    }
  }

  /// Get color scheme icon
  IconData getColorSchemeIcon(String scheme) {
    switch (scheme) {
      case 'default':
        return Icons.palette;
      case 'neon_blue':
        return Icons.water_drop;
      case 'cyber_purple':
        return Icons.auto_awesome;
      case 'electric_green':
        return Icons.flash_on;
      case 'neon_pink':
        return Icons.favorite;
      case 'cyber_orange':
        return Icons.local_fire_department;
      case 'matrix_green':
        return Icons.code;
      case 'hologram_blue':
        return Icons.blur_on;
      default:
        return Icons.palette;
    }
  }
}