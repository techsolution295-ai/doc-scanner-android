import 'dart:async';

import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../app/constants/app_colors.dart';

/// Professional loading UI used across the app.
///
/// Prefer [AppLoader.run] for blocking work (save / print / share / import).
/// Use [AppLoadingView] for full-screen placeholders.
/// Use [AppLoaderOverlay] to dim content while a screen-level task runs.
class AppLoader {
  AppLoader._();

  static bool _isShowing = false;
  static Completer<void>? _dialogReady;
  static BuildContext? _dialogContext;

  /// Shows a non-dismissible loading dialog. Safe to call once at a time.
  static void show(BuildContext context, {String message = 'Please wait…'}) {
    if (_isShowing) return;
    _isShowing = true;
    final ready = Completer<void>();
    _dialogReady = ready;
    _dialogContext = null;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      useRootNavigator: true,
      builder: (dialogContext) {
        _dialogContext = dialogContext;
        if (!ready.isCompleted) {
          scheduleMicrotask(() {
            if (!ready.isCompleted) ready.complete();
          });
        }
        return PopScope(
          canPop: false,
          child: Center(child: AppLoaderCard(message: message)),
        );
      },
    ).whenComplete(() {
      _isShowing = false;
      _dialogContext = null;
      if (!ready.isCompleted) ready.complete();
    });
  }

  /// Hides the loader dialog if one is open.
  ///
  /// Completes only after the dialog route itself is popped, so the next
  /// screen is not pushed on top of a loader that never closes.
  static Future<void> hide(BuildContext context) async {
    if (!_isShowing) return;
    final ready = _dialogReady?.future;
    if (ready != null) {
      try {
        await ready.timeout(const Duration(seconds: 2));
      } catch (_) {}
    }
    if (!_isShowing) return;
    final dialogContext = _dialogContext;
    _isShowing = false;
    _dialogContext = null;
    if (dialogContext != null && dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
      return;
    }
    if (!context.mounted) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) navigator.pop();
  }

  /// Runs [task] behind a professional loading dialog.
  static Future<T?> run<T>(
    BuildContext context, {
    required Future<T> Function() task,
    String message = 'Please wait…',
    String? errorMessage,
  }) async {
    if (!context.mounted) return null;
    show(context, message: message);
    try {
      final result = await task();
      if (context.mounted) hide(context);
      return result;
    } catch (_) {
      if (context.mounted) {
        hide(context);
        if (errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      }
      return null;
    }
  }
}

/// Compact card with spinner + message — used inside dialogs and overlays.
class AppLoaderCard extends StatelessWidget {
  const AppLoaderCard({
    super.key,
    this.message = 'Please wait…',
    this.compact = false,
  });

  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: compact ? 160 : 220,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 20 : 28,
          vertical: compact ? 22 : 28,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: compact ? 42 : 52,
              height: compact ? 28 : 32,
              child: AppSpinner(size: compact ? 28 : 34),
            ),
            SizedBox(height: compact ? 14 : 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 13 : 14.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small branded loader used on buttons and waiting states.
class AppSpinner extends StatelessWidget {
  const AppSpinner({
    super.key,
    this.size = 32,
    this.color = const Color(0xFF3B66FF),
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LoadingAnimationWidget.staggeredDotsWave(color: color, size: size);
  }
}

/// Full-screen / area placeholder loader.
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.message = 'Loading…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(child: AppLoaderCard(message: message));
  }
}

/// Dimmed overlay that sits on top of screen content.
class AppLoaderOverlay extends StatelessWidget {
  const AppLoaderOverlay({
    super.key,
    required this.visible,
    required this.child,
    this.message = 'Please wait…',
  });

  final bool visible;
  final Widget child;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (visible)
          Positioned.fill(
            child: AbsorbPointer(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.35),
                child: Center(child: AppLoaderCard(message: message)),
              ),
            ),
          ),
      ],
    );
  }
}
