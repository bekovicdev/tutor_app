import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:tutor_app/l10n/l10n_ext.dart';
import 'package:tutor_app/theme/ios26_theme.dart';

enum AppAlertStyle { normal, destructive, cancel, primary }

class AppAlertAction {
  const AppAlertAction({
    required this.label,
    this.style = AppAlertStyle.normal,
    this.onPressed,
  });

  final String label;
  final AppAlertStyle style;

  /// Receives the dialog [BuildContext]. Call [Navigator.pop] with an optional
  /// result. If null, the dialog dismisses with `null`.
  final FutureOr<void> Function(BuildContext dialogContext)? onPressed;
}

class AppSheetAction {
  const AppSheetAction({
    required this.label,
    this.isDestructive = false,
    this.onPressed,
  });

  final String label;
  final bool isDestructive;
  final FutureOr<void> Function(BuildContext sheetContext)? onPressed;
}

Future<T?> showAppAlert<T>({
  required BuildContext context,
  required String title,
  String? message,
  Widget? content,
  IconData? icon,
  Color? iconColor,
  required List<AppAlertAction> actions,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: context.l10n.dismiss,
    barrierColor: const Color(0x99000000),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (
      BuildContext dialogContext,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
    ) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _AppAlertBody(
              title: title,
              message: message,
              content: content,
              icon: icon,
              iconColor: iconColor,
              actions: actions,
            ),
          ),
        ),
      );
    },
    transitionBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      final Animation<double> curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

Future<T?> showAppActionSheet<T>({
  required BuildContext context,
  String? title,
  String? message,
  required List<AppSheetAction> actions,
  String? cancelLabel,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    barrierColor: const Color(0x99000000),
    builder: (BuildContext sheetContext) {
      return _AppActionSheetBody(
        title: title,
        message: message,
        actions: actions,
        cancelLabel: cancelLabel ?? context.l10n.cancel,
      );
    },
  );
}

IconData _resolveAlertIcon(List<AppAlertAction> actions, IconData? explicit) {
  if (explicit != null) {
    return explicit;
  }
  final bool hasDestructive =
      actions.any((AppAlertAction a) => a.style == AppAlertStyle.destructive);
  final bool hasPrimary =
      actions.any((AppAlertAction a) => a.style == AppAlertStyle.primary);
  if (hasDestructive && hasPrimary) {
    return CupertinoIcons.exclamationmark_circle_fill;
  }
  if (hasDestructive) {
    return CupertinoIcons.trash_circle_fill;
  }
  if (actions.length == 1) {
    return CupertinoIcons.info_circle_fill;
  }
  if (hasPrimary) {
    return CupertinoIcons.checkmark_circle_fill;
  }
  return CupertinoIcons.info_circle_fill;
}

Color _resolveIconColor(
  BuildContext context,
  List<AppAlertAction> actions,
  Color? explicit,
) {
  if (explicit != null) {
    return explicit;
  }
  final bool hasDestructive =
      actions.any((AppAlertAction a) => a.style == AppAlertStyle.destructive);
  final bool hasPrimary =
      actions.any((AppAlertAction a) => a.style == AppAlertStyle.primary);
  if (hasDestructive && hasPrimary) {
    return const Color(0xFFFF9F0A);
  }
  if (hasDestructive) {
    return CupertinoColors.systemRed.resolveFrom(context);
  }
  return CupertinoColors.activeBlue;
}

class _AppAlertBody extends StatelessWidget {
  const _AppAlertBody({
    required this.title,
    required this.actions,
    this.message,
    this.content,
    this.icon,
    this.iconColor,
  });

  final String title;
  final String? message;
  final Widget? content;
  final IconData? icon;
  final Color? iconColor;
  final List<AppAlertAction> actions;

  @override
  Widget build(BuildContext context) {
    final IconData resolvedIcon = _resolveAlertIcon(actions, icon);
    final Color resolvedColor = _resolveIconColor(context, actions, iconColor);

    // Primary last (CTA), cancel mid, destructive before primary when mixed.
    final List<AppAlertAction> ordered = List<AppAlertAction>.from(actions);
    ordered.sort((AppAlertAction a, AppAlertAction b) {
      return _actionRank(a.style).compareTo(_actionRank(b.style));
    });

    return Material(
      type: MaterialType.transparency,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 352),
        child: _ModernSurface(
          borderRadius: 28,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        resolvedColor.withValues(alpha: 0.22),
                        resolvedColor.withValues(alpha: 0.08),
                      ],
                    ),
                    border: Border.all(
                      color: resolvedColor.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Icon(
                    resolvedIcon,
                    size: 28,
                    color: resolvedColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                ),
                if (message != null && message!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
                if (content != null) ...<Widget>[
                  const SizedBox(height: 16),
                  content!,
                ],
                const SizedBox(height: 22),
                for (int i = 0; i < ordered.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(height: 10),
                  _AlertActionButton(action: ordered[i]),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _actionRank(AppAlertStyle style) {
    switch (style) {
      case AppAlertStyle.cancel:
        return 0;
      case AppAlertStyle.normal:
        return 1;
      case AppAlertStyle.destructive:
        return 2;
      case AppAlertStyle.primary:
        return 3;
    }
  }
}

class _AlertActionButton extends StatefulWidget {
  const _AlertActionButton({required this.action});

  final AppAlertAction action;

  @override
  State<_AlertActionButton> createState() => _AlertActionButtonState();
}

class _AlertActionButtonState extends State<_AlertActionButton> {
  bool _busy = false;
  bool _pressed = false;

  Future<void> _handleTap() async {
    final FutureOr<void> Function(BuildContext)? handler =
        widget.action.onPressed;
    if (handler == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = true;
    });
    try {
      await handler(context);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppAlertAction action = widget.action;
    final bool isPrimary = action.style == AppAlertStyle.primary;
    final bool isDestructive = action.style == AppAlertStyle.destructive;
    final bool isCancel = action.style == AppAlertStyle.cancel;

    final Color labelColor;
    final List<Color> fill;
    final List<BoxShadow>? shadows;

    switch (action.style) {
      case AppAlertStyle.primary:
        labelColor = CupertinoColors.white;
        fill = const <Color>[Color(0xFF5AC8FA), Color(0xFF007AFF)];
        shadows = <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF007AFF).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ];
      case AppAlertStyle.destructive:
        labelColor = CupertinoColors.systemRed.resolveFrom(context);
        fill = <Color>[
          CupertinoColors.systemRed.resolveFrom(context).withValues(alpha: 0.14),
          CupertinoColors.systemRed.resolveFrom(context).withValues(alpha: 0.08),
        ];
        shadows = null;
      case AppAlertStyle.cancel:
        labelColor = CupertinoColors.secondaryLabel.resolveFrom(context);
        fill = <Color>[
          CupertinoColors.systemGrey5.resolveFrom(context),
          CupertinoColors.systemGrey5.resolveFrom(context),
        ];
        shadows = null;
      case AppAlertStyle.normal:
        labelColor = CupertinoColors.activeBlue;
        fill = <Color>[
          CupertinoColors.activeBlue.withValues(alpha: 0.14),
          CupertinoColors.activeBlue.withValues(alpha: 0.08),
        ];
        shadows = null;
    }

    return GestureDetector(
      onTapDown: _busy ? null : (_) => setState(() => _pressed = true),
      onTapUp: _busy
          ? null
          : (_) {
              setState(() => _pressed = false);
              _handleTap();
            },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 90),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: _busy ? 0.65 : 1,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: isPrimary ? 15 : 13,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: fill,
              ),
              boxShadow: shadows,
              border: isCancel || isDestructive || !isPrimary
                  ? Border.all(
                      color: isDestructive
                          ? CupertinoColors.systemRed
                              .resolveFrom(context)
                              .withValues(alpha: 0.22)
                          : CupertinoColors.separator.resolveFrom(context)
                              .withValues(alpha: 0.45),
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: _busy
                ? CupertinoActivityIndicator(
                    color: isPrimary ? CupertinoColors.white : null,
                  )
                : Text(
                    action.label,
                    style: TextStyle(
                      fontSize: isPrimary ? 17 : 16,
                      fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
                      letterSpacing: -0.2,
                      color: labelColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _AppActionSheetBody extends StatelessWidget {
  const _AppActionSheetBody({
    required this.actions,
    required this.cancelLabel,
    this.title,
    this.message,
  });

  final String? title;
  final String? message;
  final List<AppSheetAction> actions;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    final double bottom = MediaQuery.paddingOf(context).bottom;
    final double maxSheetHeight = MediaQuery.sizeOf(context).height * 0.55;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, bottom > 0 ? bottom + 4 : 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _ModernSurface(
            borderRadius: 26,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxSheetHeight),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const SizedBox(height: 10),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey3.resolveFrom(context),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    if (title != null || message != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
                        child: Column(
                          children: <Widget>[
                            if (title != null)
                              Text(
                                title!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            if (message != null) ...<Widget>[
                              const SizedBox(height: 6),
                              Text(
                                message!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          for (int i = 0; i < actions.length; i++) ...<Widget>[
                            if (i > 0) const SizedBox(height: 6),
                            _SheetChip(action: actions[i]),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _ModernSurface(
            borderRadius: 22,
            child: _SheetChip(
              action: AppSheetAction(
                label: cancelLabel,
                onPressed: (BuildContext ctx) => Navigator.of(ctx).pop(),
              ),
              emphasize: true,
              flat: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetChip extends StatefulWidget {
  const _SheetChip({
    required this.action,
    this.emphasize = false,
    this.flat = false,
  });

  final AppSheetAction action;
  final bool emphasize;
  final bool flat;

  @override
  State<_SheetChip> createState() => _SheetChipState();
}

class _SheetChipState extends State<_SheetChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool destructive = widget.action.isDestructive;
    final Color accent = destructive
        ? CupertinoColors.systemRed.resolveFrom(context)
        : CupertinoColors.activeBlue;
    final Color bg = widget.flat
        ? const Color(0x00000000)
        : accent.withValues(alpha: destructive ? 0.10 : 0.08);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) async {
        setState(() => _pressed = false);
        final FutureOr<void> Function(BuildContext)? handler =
            widget.action.onPressed;
        if (handler == null) {
          Navigator.of(context).pop();
          return;
        }
        await handler(context);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 90),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: widget.flat
                ? null
                : Border.all(color: accent.withValues(alpha: 0.16)),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.action.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: widget.emphasize ? FontWeight.w700 : FontWeight.w600,
              letterSpacing: -0.2,
              color: widget.flat
                  ? CupertinoColors.label.resolveFrom(context)
                  : accent,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernSurface extends StatelessWidget {
  const _ModernSurface({
    required this.child,
    required this.borderRadius,
  });

  final Widget child;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = CupertinoTheme.of(context).brightness ??
        MediaQuery.platformBrightnessOf(context);
    final bool isDark = brightness == Brightness.dark;

    final Color fill = isDark
        ? const Color(0xCC1C1C1E)
        : const Color(0xE6FFFFFF);
    final Color sheenTop = isDark
        ? const Color(0x28FFFFFF)
        : const Color(0x99FFFFFF);
    final Color borderColor =
        isDark ? const Color(0x40FFFFFF) : const Color(0x66FFFFFF);

    final Widget surface = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.alphaBlend(sheenTop, fill),
            fill,
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: isDark
                ? const Color(0x88000000)
                : const Color(0x33000000),
            blurRadius: 40,
            spreadRadius: -4,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: isDark
                ? const Color(0x22000000)
                : const Color(0x14007AFF),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: supportsLiquidGlass ? 28 : 22,
          sigmaY: supportsLiquidGlass ? 28 : 22,
        ),
        child: surface,
      ),
    );
  }
}
