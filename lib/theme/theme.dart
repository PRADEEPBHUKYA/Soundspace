import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SS {
  // Backgrounds
  static const bg      = Color(0xFF080810);
  static const card    = Color(0xFF10101E);
  static const raised  = Color(0xFF17172A);
  static const border  = Color(0xFF252538);

  // Accents
  static const cyan    = Color(0xFF00C8FF);
  static const pink    = Color(0xFFFF2D6B);
  static const green   = Color(0xFF00E5A0);
  static const amber   = Color(0xFFFFBE00);
  static const violet  = Color(0xFF9B6DFF);

  // Text
  static const t1 = Color(0xFFFFFFFF);
  static const t2 = Color(0xFFAAAAAD);
  static const t3 = Color(0xFF45455A);

  // Source colors
  static const bassC   = Color(0xFFFF2D6B);
  static const vocalC  = Color(0xFF00E5A0);
  static const trebleC = Color(0xFF00C8FF);
  static const leadC   = Color(0xFFFFBE00);

  static ThemeData theme() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: cyan, secondary: pink,
      surface: card, background: bg,
      onPrimary: Colors.black, onSurface: t1,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: 'SF Pro Display', color: t1, fontWeight: FontWeight.w700),
      titleLarge:   TextStyle(fontFamily: 'SF Pro Display', color: t1, fontWeight: FontWeight.w600, fontSize: 20),
      titleMedium:  TextStyle(color: t1, fontWeight: FontWeight.w500, fontSize: 16),
      bodyMedium:   TextStyle(color: t2, fontSize: 14),
      bodySmall:    TextStyle(color: t3, fontSize: 12),
      labelSmall:   TextStyle(color: t3, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.4),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: cyan, thumbColor: cyan,
      overlayColor: Color(0x2200C8FF),
      inactiveTrackColor: border, trackHeight: 3,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 9),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((s) =>
          s.contains(MaterialState.selected) ? cyan : Colors.grey.shade600),
      trackColor: MaterialStateProperty.resolveWith((s) =>
          s.contains(MaterialState.selected) ? const Color(0x3300C8FF) : const Color(0xFF252538)),
      trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
    }),
  );
}

void setSystemUI() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF080810),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
}
