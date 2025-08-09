import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitzy/services/local_storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  String _currentColorScheme = 'default';
  bool _useSystemAccentColor = false;
  double _textScaleFactor = 1.0;

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

  Color get primaryColor => _colorSchemes[_currentColorScheme] ?? _colorSchemes['default']!;
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
      if (kDebugMode) {
        debugPrint('Error loading theme preferences: $e');
      }
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
      if (kDebugMode) {
        debugPrint('Error saving theme preferences: $e');
      }
    }
  }

  /// Toggle between light and dark mode
  void toggleTheme([bool? isDark]) {
    if (isDark != null) {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    } else {
      _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    }

    _saveThemePreferences();
    notifyListeners();
  }

  /// Set specific theme mode
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveThemePreferences();
    notifyListeners();
  }

  /// Change color scheme
  void setColorScheme(String schemeName) {
    if (_colorSchemes.containsKey(schemeName)) {
      _currentColorScheme = schemeName;
      _saveThemePreferences();
      notifyListeners();
    }
  }

  /// Toggle system accent color usage
  void toggleSystemAccentColor(bool useSystem) {
    _useSystemAccentColor = useSystem;
    _saveThemePreferences();
    notifyListeners();
  }

  /// Set text scale factor
  void setTextScaleFactor(double scale) {
    _textScaleFactor = scale.clamp(0.8, 1.4);
    _saveThemePreferences();
    notifyListeners();
  }

  /// Get light theme
  ThemeData get lightTheme {
    final primaryColor = this.primaryColor;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: _getTextTheme(colorScheme),
      appBarTheme: _getAppBarTheme(colorScheme, Brightness.light),
      cardTheme: _getCardTheme(colorScheme, Brightness.light),
      elevatedButtonTheme: _getElevatedButtonTheme(colorScheme),
      outlinedButtonTheme: _getOutlinedButtonTheme(colorScheme),
      textButtonTheme: _getTextButtonTheme(colorScheme),
      floatingActionButtonTheme: _getFABTheme(colorScheme),
      inputDecorationTheme: _getInputDecorationTheme(colorScheme, Brightness.light),
      bottomNavigationBarTheme: _getBottomNavTheme(colorScheme, Brightness.light),
      navigationRailTheme: _getNavigationRailTheme(colorScheme, Brightness.light),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withValues(alpha: 0.2),
        thickness: 1,
      ),
      snackBarTheme: _getSnackBarTheme(colorScheme, Brightness.light),
      dialogTheme: _getDialogTheme(colorScheme, Brightness.light),
      bottomSheetTheme: _getBottomSheetTheme(colorScheme, Brightness.light),
      chipTheme: _getChipTheme(colorScheme, Brightness.light),
      switchTheme: _getSwitchTheme(colorScheme),
      checkboxTheme: _getCheckboxTheme(colorScheme),
      radioTheme: _getRadioTheme(colorScheme),
      sliderTheme: _getSliderTheme(colorScheme),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
      ),
    );
  }

  /// Get dark theme
  ThemeData get darkTheme {
    final primaryColor = this.primaryColor;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: _getTextTheme(colorScheme),
      appBarTheme: _getAppBarTheme(colorScheme, Brightness.dark),
      cardTheme: _getCardTheme(colorScheme, Brightness.dark),
      elevatedButtonTheme: _getElevatedButtonTheme(colorScheme),
      outlinedButtonTheme: _getOutlinedButtonTheme(colorScheme),
      textButtonTheme: _getTextButtonTheme(colorScheme),
      floatingActionButtonTheme: _getFABTheme(colorScheme),
      inputDecorationTheme: _getInputDecorationTheme(colorScheme, Brightness.dark),
      bottomNavigationBarTheme: _getBottomNavTheme(colorScheme, Brightness.dark),
      navigationRailTheme: _getNavigationRailTheme(colorScheme, Brightness.dark),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withValues(alpha: 0.2),
        thickness: 1,
      ),
      snackBarTheme: _getSnackBarTheme(colorScheme, Brightness.dark),
      dialogTheme: _getDialogTheme(colorScheme, Brightness.dark),
      bottomSheetTheme: _getBottomSheetTheme(colorScheme, Brightness.dark),
      chipTheme: _getChipTheme(colorScheme, Brightness.dark),
      switchTheme: _getSwitchTheme(colorScheme),
      checkboxTheme: _getCheckboxTheme(colorScheme),
      radioTheme: _getRadioTheme(colorScheme),
      sliderTheme: _getSliderTheme(colorScheme),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
      ),
    );
  }

  /// Get text theme with custom font
  TextTheme _getTextTheme(ColorScheme colorScheme) {
    final baseTextTheme = GoogleFonts.poppinsTextTheme();

    return baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        color: colorScheme.onSurface,
        fontSize: (baseTextTheme.displayLarge?.fontSize ?? 57) * _textScaleFactor,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        color: colorScheme.onSurface,
        fontSize: (baseTextTheme.displayMedium?.fontSize ?? 45) * _textScaleFactor,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        color: colorScheme.onSurface,
        fontSize: (baseTextTheme.displaySmall?.fontSize ?? 36) * _textScaleFactor,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        color: colorScheme.onSurface,
        fontSize: (baseTextTheme.headlineLarge?.fontSize ?? 32) * _textScaleFactor,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        color: colorScheme.onSurface,
        fontSize: (baseTextTheme.headlineMedium?.fontSize ?? 28) * _textScaleFactor,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        color: colorScheme.onSurface,
        fontSize: (baseTextTheme.headlineSmall?.fontSize ?? 24) * _textScaleFactor,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
        fontSize: (baseTextTheme.titleLarge?.fontSize ?? 22) * _textScaleFactor,
        fontWeight: FontWeight.w500,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        color: colorScheme.onSurface,
        fontSize: (baseTextTheme.titleMedium?.fontSize ?? 16) * _textScaleFactor,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        color: colorScheme.onSurface,
        fontSize: (baseTextTheme.titleSmall?.fontSize ?? 14) * _textScaleFactor,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface,
        fontSize: (baseTextTheme.bodyLarge?.fontSize ?? 16) * _textScaleFactor,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface,
        fontSize: (baseTextTheme.bodyMedium?.fontSize ?? 14) * _textScaleFactor,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontSize: (baseTextTheme.bodySmall?.fontSize ?? 12) * _textScaleFactor,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        color: colorScheme.onSurface,
        fontSize: (baseTextTheme.labelLarge?.fontSize ?? 14) * _textScaleFactor,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        color: colorScheme.onSurface,
        fontSize: (baseTextTheme.labelMedium?.fontSize ?? 12) * _textScaleFactor,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontSize: (baseTextTheme.labelSmall?.fontSize ?? 11) * _textScaleFactor,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// Get app bar theme
  AppBarTheme _getAppBarTheme(ColorScheme colorScheme, Brightness brightness) {
    return AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20 * _textScaleFactor,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        letterSpacing: 0.5,
      ),
      systemOverlayStyle: brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
    );
  }

  /// Get card theme
  CardThemeData _getCardTheme(ColorScheme colorScheme, Brightness brightness) {
    return CardThemeData(
      color: colorScheme.surface.withValues(alpha: 0.7), // glassy
      shadowColor: colorScheme.primary.withValues(alpha: 0.18),
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.08),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      surfaceTintColor: colorScheme.surfaceTint,
    );
  }

  /// Get elevated button theme
  ElevatedButtonThemeData _getElevatedButtonTheme(ColorScheme colorScheme) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary.withValues(alpha: 0.85),
        foregroundColor: colorScheme.onPrimary,
        elevation: 10,
        shadowColor: colorScheme.primary.withValues(alpha: 0.25),
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16 * _textScaleFactor,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.7,
        ),
      ),
    );
  }

  /// Get outlined button theme
  OutlinedButtonThemeData _getOutlinedButtonTheme(ColorScheme colorScheme) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide(color: colorScheme.outline),
        textStyle: GoogleFonts.inter(
          fontSize: 14 * _textScaleFactor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Get text button theme
  TextButtonThemeData _getTextButtonTheme(ColorScheme colorScheme) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14 * _textScaleFactor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Get floating action button theme
  FloatingActionButtonThemeData _getFABTheme(ColorScheme colorScheme) {
    return FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 8,
      focusElevation: 12,
      hoverElevation: 10,
      highlightElevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
    );
  }

  /// Get input decoration theme
  InputDecorationTheme _getInputDecorationTheme(ColorScheme colorScheme, Brightness brightness) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      labelStyle: GoogleFonts.inter(
        fontSize: 14 * _textScaleFactor,
        color: colorScheme.onSurfaceVariant,
      ),
      hintStyle: GoogleFonts.inter(
        fontSize: 14 * _textScaleFactor,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  /// Get bottom navigation theme
  BottomNavigationBarThemeData _getBottomNavTheme(ColorScheme colorScheme, Brightness brightness) {
    return BottomNavigationBarThemeData(
      backgroundColor: colorScheme.surface.withValues(alpha: 0.8),
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 13 * _textScaleFactor,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 12 * _textScaleFactor,
        fontWeight: FontWeight.w400,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 16,
    );
  }

  /// Get navigation rail theme
  NavigationRailThemeData _getNavigationRailTheme(ColorScheme colorScheme, Brightness brightness) {
    return NavigationRailThemeData(
      backgroundColor: colorScheme.surface,
      selectedIconTheme: IconThemeData(
        color: colorScheme.onSecondaryContainer,
        size: 24,
      ),
      unselectedIconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: 24,
      ),
      selectedLabelTextStyle: GoogleFonts.inter(
        fontSize: 12 * _textScaleFactor,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      unselectedLabelTextStyle: GoogleFonts.inter(
        fontSize: 12 * _textScaleFactor,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurfaceVariant,
      ),
      indicatorColor: colorScheme.secondaryContainer,
    );
  }

  /// Get snack bar theme
  SnackBarThemeData _getSnackBarTheme(ColorScheme colorScheme, Brightness brightness) {
    return SnackBarThemeData(
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: GoogleFonts.inter(
        fontSize: 14 * _textScaleFactor,
        color: colorScheme.onInverseSurface,
      ),
      actionTextColor: colorScheme.inversePrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 6,
    );
  }

  /// Get dialog theme
  DialogThemeData _getDialogTheme(ColorScheme colorScheme, Brightness brightness) {
    return DialogThemeData(
      backgroundColor: colorScheme.surface.withValues(alpha: 0.7),
      surfaceTintColor: colorScheme.surfaceTint,
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 22 * _textScaleFactor,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      contentTextStyle: GoogleFonts.inter(
        fontSize: 16 * _textScaleFactor,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Get bottom sheet theme
  BottomSheetThemeData _getBottomSheetTheme(ColorScheme colorScheme, Brightness brightness) {
    return BottomSheetThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  /// Get chip theme
  ChipThemeData _getChipTheme(ColorScheme colorScheme, Brightness brightness) {
    return ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerHighest,
      selectedColor: colorScheme.secondaryContainer,
      disabledColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      labelStyle: GoogleFonts.inter(
        fontSize: 14 * _textScaleFactor,
        color: colorScheme.onSurfaceVariant,
      ),
      secondaryLabelStyle: GoogleFonts.inter(
        fontSize: 14 * _textScaleFactor,
        color: colorScheme.onSecondaryContainer,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  /// Get switch theme
  SwitchThemeData _getSwitchTheme(ColorScheme colorScheme) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.onPrimary;
        }
        return colorScheme.outline;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        return colorScheme.surfaceContainerHighest;
      }),
    );
  }

  /// Get checkbox theme
  CheckboxThemeData _getCheckboxTheme(ColorScheme colorScheme) {
    return CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(colorScheme.onPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  /// Get radio theme
  RadioThemeData _getRadioTheme(ColorScheme colorScheme) {
    return RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        return colorScheme.outline;
      }),
    );
  }

  /// Get slider theme
  SliderThemeData _getSliderTheme(ColorScheme colorScheme) {
    return SliderThemeData(
      activeTrackColor: colorScheme.primary,
      inactiveTrackColor: colorScheme.surfaceContainerHighest,
      thumbColor: colorScheme.primary,
      overlayColor: colorScheme.primary.withValues(alpha: 0.12),
      valueIndicatorColor: colorScheme.primary,
      valueIndicatorTextStyle: GoogleFonts.inter(
        fontSize: 12 * _textScaleFactor,
        color: colorScheme.onPrimary,
      ),
    );
  }

  /// Get available text scale factors
  static const List<double> textScaleFactors = [0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4];

  /// Get text scale factor names
  static final Map<double, String> textScaleFactorNames = {
    0.8: 'Small',
    0.9: 'Small+',
    1.0: 'Default',
    1.1: 'Large',
    1.2: 'Large+',
    1.3: 'Extra Large',
    1.4: 'Huge',
  };

  /// Reset to default theme
  void resetToDefaults() {
    _themeMode = ThemeMode.system;
    _currentColorScheme = 'default';
    _useSystemAccentColor = false;
    _textScaleFactor = 1.0;
    _saveThemePreferences();
    notifyListeners();
  }

  /// Get theme summary for settings display
  Map<String, dynamic> getThemeSummary() {
    return {
      'themeMode': _themeMode.name,
      'colorScheme': _currentColorScheme,
      'primaryColor': primaryColor.toARGB32().toRadixString(16),
      'useSystemAccentColor': _useSystemAccentColor,
      'textScaleFactor': _textScaleFactor,
      'textScaleName': textScaleFactorNames[_textScaleFactor] ?? 'Custom',
    };
  }
}