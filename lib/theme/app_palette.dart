import 'package:flutter/material.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color bg;
  final Color card;
  final Color inputBg;
  final Color gold;
  final Color textPrimary;
  final Color textMuted;
  final Color divider;

  const AppPalette({
    required this.bg,
    required this.card,
    required this.inputBg,
    required this.gold,
    required this.textPrimary,
    required this.textMuted,
    required this.divider,
  });

  // ── DARK (original values, unchanged) ──
  static const dark = AppPalette(
    bg: Color(0xFF0C1A2E),          // navyDeep
    card: Color(0xFF17263F),        // navyCard
    inputBg: Color(0xFF1D2E4A),     // navyCardAlt
    gold: Color(0xFFCBA35C),
    textPrimary: Colors.white,
    textMuted: Color(0xFF8C9AB5),
    divider: Color(0xFF29394F),
  );

  // ── LIGHT (same gold/textMuted/divider, navyDeep flipped to text role) ──
  static const light = AppPalette(
    bg: Color(0xFFFFFFFF),
    card: Color(0xFFF7F5F1),
    inputBg: Color(0xFFEFECE4),
    gold: Color(0xFFCBA35C),
    textPrimary: Color(0xFF0C1A2E), // was navyDeep bg, now text
    textMuted: Color(0xFF8C9AB5),
    divider: Color(0xFF29394F),
  );

  @override
  AppPalette copyWith({
    Color? bg, Color? card, Color? inputBg, Color? gold,
    Color? textPrimary, Color? textMuted, Color? divider,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      card: card ?? this.card,
      inputBg: inputBg ?? this.inputBg,
      gold: gold ?? this.gold,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      divider: divider ?? this.divider,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      card: Color.lerp(card, other.card, t)!,
      inputBg: Color.lerp(inputBg, other.inputBg, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}

class AppTheme {
  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppPalette.light.bg,
        colorScheme: ColorScheme.light(primary: AppPalette.light.gold),
        extensions: const [AppPalette.light],
      );

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppPalette.dark.bg,
        colorScheme: ColorScheme.dark(primary: AppPalette.dark.gold),
        extensions: const [AppPalette.dark],
      );
}

// Shortcut so screens can write `context.palette.gold` instead of
// `Theme.of(context).extension<AppPalette>()!.gold`
extension PaletteX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}