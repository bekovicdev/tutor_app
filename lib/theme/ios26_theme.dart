import 'dart:ui';

import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

/// Shared spacing / radius tuned for iOS 26–style surfaces.
abstract final class AppGlassTokens {
  static const double radius = 18;
  static const double radiusSmall = 12;
  static const double blurSigma = 18;
  static const EdgeInsets cardPadding = EdgeInsets.all(14);
}

/// True only on iOS/macOS 26+ where native Liquid Glass is available.
bool get supportsLiquidGlass {
  if (kIsWeb) {
    return false;
  }
  try {
    return PlatformVersion.shouldUseNativeGlass;
  } catch (_) {
    return false;
  }
}

CupertinoThemeData buildAppCupertinoTheme(Brightness brightness) {
  if (supportsLiquidGlass) {
    return _liquidGlassTheme(brightness);
  }
  return _classicTheme(brightness);
}

/// No bottom hairline on Liquid Glass; classic Cupertino hairline otherwise.
Border? get appNavigationBarBorder {
  if (supportsLiquidGlass) {
    return null;
  }
  return const Border(
    bottom: BorderSide(
      color: Color(0x4D000000),
      width: 0.0,
    ),
  );
}

CupertinoThemeData _classicTheme(Brightness brightness) {
  return CupertinoThemeData(
    brightness: brightness,
    primaryColor: CupertinoColors.activeBlue,
  );
}

CupertinoThemeData _liquidGlassTheme(Brightness brightness) {
  final bool isDark = brightness == Brightness.dark;
  return CupertinoThemeData(
    brightness: brightness,
    primaryColor: CupertinoColors.activeBlue,
    scaffoldBackgroundColor: isDark
        ? const Color(0xFF000000)
        : const Color(0xFFF2F2F7),
    barBackgroundColor: (isDark
            ? const Color(0xCC1C1C1E)
            : const Color(0xCCF9F9F9))
        .withValues(alpha: 0.72),
    textTheme: CupertinoTextThemeData(
      primaryColor: isDark ? CupertinoColors.white : CupertinoColors.label,
    ),
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

  Widget _classicCard(BuildContext context) {
    final Widget content = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: tint ??
            CupertinoColors.secondarySystemGroupedBackground
                .resolveFrom(context),
        borderRadius: BorderRadius.circular(
          borderRadius > 14 ? 12 : borderRadius,
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
    final Brightness brightness = CupertinoTheme.of(context).brightness ??
        MediaQuery.platformBrightnessOf(context);
    final bool isDark = brightness == Brightness.dark;

    final Color fill = tint ??
        (isDark
            ? const Color(0xCC2C2C2E)
            : const Color(0xCCFFFFFF));
    final Color borderColor = isDark
        ? const Color(0x33FFFFFF)
        : const Color(0x40FFFFFF);
    final List<Color> sheen = isDark
        ? <Color>[
            const Color(0x22FFFFFF),
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
