import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// Shared spacing / radius tuned for iOS-style surfaces.
abstract final class AppGlassTokens {
  static const double radius = 18;
  static const double radiusSmall = 12;
  static const double blurSigma = 18;
  static const EdgeInsets cardPadding = EdgeInsets.all(14);
}

/// Native Liquid Glass needs Xcode with the iOS 26 SDK.
/// Disabled on current toolchain (Xcode 16 / iOS 18 SDK).
bool get supportsLiquidGlass => false;

/// iOS-like surface colors that stay readable in dark mode.
abstract final class AppSurfaces {
  static Color scaffold(Brightness brightness) => brightness == Brightness.dark
      ? const Color(0xFF000000)
      : const Color(0xFFF2F2F7);

  static Color bar(Brightness brightness) => brightness == Brightness.dark
      ? const Color(0xF21C1C1E)
      : const Color(0xF2F9F9F9);

  static Color card(Brightness brightness) => brightness == Brightness.dark
      ? const Color(0xFF1C1C1E)
      : const Color(0xFFFFFFFF);

  static Color cardElevated(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFF2C2C2E)
          : const Color(0xFFFFFFFF);

  static Color separator(Brightness brightness) => brightness == Brightness.dark
      ? const Color(0x403C3C43)
      : const Color(0x4A3C3C43);

  static Color secondaryLabel(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0x99EBEBF5)
          : const Color(0x993C3C43);
}

void applySystemUiOverlay(Brightness brightness) {
  final bool isDark = brightness == Brightness.dark;
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor:
          isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    ),
  );
}

CupertinoThemeData buildAppCupertinoTheme(Brightness brightness) {
  if (supportsLiquidGlass) {
    return _liquidGlassTheme(brightness);
  }
  return _classicTheme(brightness);
}

/// No bottom hairline on Liquid Glass; classic Cupertino hairline otherwise.
Border? appNavigationBarBorderOf(BuildContext context) {
  if (supportsLiquidGlass) {
    return null;
  }
  final Brightness brightness = CupertinoTheme.of(context).brightness ??
      MediaQuery.platformBrightnessOf(context);
  return Border(
    bottom: BorderSide(
      color: AppSurfaces.separator(brightness),
      width: 0.5,
    ),
  );
}

/// Prefer [appNavigationBarBorderOf].
@Deprecated('Use appNavigationBarBorderOf(context)')
Border? get appNavigationBarBorder {
  final Brightness brightness =
      WidgetsBinding.instance.platformDispatcher.platformBrightness;
  return appNavigationBarBorderFor(brightness);
}

Border? appNavigationBarBorderFor(Brightness brightness) {
  if (supportsLiquidGlass) {
    return null;
  }
  return Border(
    bottom: BorderSide(
      color: AppSurfaces.separator(brightness),
      width: 0.5,
    ),
  );
}

CupertinoThemeData _classicTheme(Brightness brightness) {
  final bool isDark = brightness == Brightness.dark;
  final Color label = isDark ? CupertinoColors.white : CupertinoColors.black;
  final Color secondary =
      isDark ? const Color(0x99EBEBF5) : const Color(0x993C3C43);
  return CupertinoThemeData(
    brightness: brightness,
    primaryColor: CupertinoColors.activeBlue,
    scaffoldBackgroundColor: AppSurfaces.scaffold(brightness),
    barBackgroundColor: AppSurfaces.bar(brightness),
    textTheme: CupertinoTextThemeData(
      primaryColor: isDark ? CupertinoColors.white : CupertinoColors.label,
      textStyle: _appTextStyle(color: label, fontSize: 17),
      actionTextStyle: _appTextStyle(
        color: CupertinoColors.activeBlue,
        fontSize: 17,
      ),
      navActionTextStyle: _appTextStyle(
        color: CupertinoColors.activeBlue,
        fontSize: 17,
      ),
      navTitleTextStyle: _appTextStyle(
        color: label,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      navLargeTitleTextStyle: _appTextStyle(
        color: label,
        fontSize: 34,
        fontWeight: FontWeight.w700,
      ),
      tabLabelTextStyle: _appTextStyle(color: secondary, fontSize: 10),
      pickerTextStyle: _appTextStyle(color: label, fontSize: 21),
      dateTimePickerTextStyle: _appTextStyle(color: label, fontSize: 21),
    ),
  );
}

CupertinoThemeData _liquidGlassTheme(Brightness brightness) {
  // Same text styles as classic; glass only affects surfaces/chrome.
  return _classicTheme(brightness);
}

/// Explicit [inherit]: false so theme switches never hit TextStyle.lerp asserts.
TextStyle _appTextStyle({
  required Color color,
  required double fontSize,
  FontWeight fontWeight = FontWeight.w400,
}) {
  return TextStyle(
    inherit: false,
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontFamily: '.SF Pro Text',
    letterSpacing: -0.41,
    decoration: TextDecoration.none,
  );
}

/// Card surface: Liquid Glass styling on iOS 26+, classic Cupertino otherwise.
///
/// Prefer [enableBlur]: false inside long scrolling lists.
class AppGlassCard extends StatelessWidget {
  const AppGlassCard({
    required this.child,
    this.padding = AppGlassTokens.cardPadding,
    this.margin,
    this.borderRadius = AppGlassTokens.radius,
    this.enableBlur = false,
    this.tint,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool enableBlur;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    if (!supportsLiquidGlass) {
      return _classicCard(context);
    }
    return _glassCard(context);
  }

  Brightness _brightness(BuildContext context) {
    return CupertinoTheme.of(context).brightness ??
        MediaQuery.platformBrightnessOf(context);
  }

  Widget _classicCard(BuildContext context) {
    final Brightness brightness = _brightness(context);
    final Widget content = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: tint ?? AppSurfaces.card(brightness),
        borderRadius: BorderRadius.circular(
          borderRadius > 14 ? 12 : borderRadius,
        ),
        border: Border.all(
          color: brightness == Brightness.dark
              ? const Color(0x14FFFFFF)
              : const Color(0x08000000),
        ),
      ),
      child: child,
    );
    if (margin == null) {
      return content;
    }
    return Padding(padding: margin!, child: content);
  }

  Widget _glassCard(BuildContext context) {
    final Brightness brightness = _brightness(context);
    final bool isDark = brightness == Brightness.dark;

    final Color fill = tint ??
        (isDark ? const Color(0xE61C1C1E) : const Color(0xE6FFFFFF));
    final Color borderColor =
        isDark ? const Color(0x22FFFFFF) : const Color(0x33FFFFFF);
    final List<Color> sheen = isDark
        ? <Color>[
            const Color(0x18FFFFFF),
            const Color(0x00FFFFFF),
          ]
        : <Color>[
            const Color(0x66FFFFFF),
            const Color(0x14FFFFFF),
          ];

    final Widget content = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 0.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.alphaBlend(sheen[0], fill),
            Color.alphaBlend(sheen[1], fill),
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: isDark
                ? const Color(0x66000000)
                : const Color(0x14000000),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    final Widget clipped = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: enableBlur
          ? BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: AppGlassTokens.blurSigma,
                sigmaY: AppGlassTokens.blurSigma,
              ),
              child: content,
            )
          : content,
    );

    if (margin == null) {
      return clipped;
    }
    return Padding(padding: margin!, child: clipped);
  }
}
