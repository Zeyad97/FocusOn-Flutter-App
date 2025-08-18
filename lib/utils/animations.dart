import 'package:flutter/material.dart';

/// Custom animations and transition utilities for enhanced UX
class AppAnimations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);

  /// Slide transition from bottom
  static Widget slideFromBottom({
    required Widget child,
    required AnimationController controller,
    Duration delay = Duration.zero,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Interval(
          delay.inMilliseconds / controller.duration!.inMilliseconds,
          1.0,
          curve: Curves.easeOutCubic,
        ),
      )),
      child: child,
    );
  }

  /// Fade and scale transition
  static Widget fadeScale({
    required Widget child,
    required AnimationController controller,
    Duration delay = Duration.zero,
  }) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0,
        end: 1,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Interval(
          delay.inMilliseconds / controller.duration!.inMilliseconds,
          1.0,
          curve: Curves.easeOut,
        ),
      )),
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 0.8,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Interval(
            delay.inMilliseconds / controller.duration!.inMilliseconds,
            1.0,
            curve: Curves.elasticOut,
          ),
        )),
        child: child,
      ),
    );
  }

  /// Staggered list animation
  static Widget staggeredItem({
    required Widget child,
    required AnimationController controller,
    required int index,
    int itemCount = 1,
  }) {
    final delay = Duration(milliseconds: (index * 100).clamp(0, 800));
    
    return slideFromBottom(
      controller: controller,
      delay: delay,
      child: fadeScale(
        controller: controller,
        delay: delay,
        child: child,
      ),
    );
  }

  /// Hero-style page transition
  static PageRouteBuilder<T> createRoute<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end);
        var curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        return SlideTransition(
          position: tween.animate(curvedAnimation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  /// Bounce effect for buttons
  static Widget bounceButton({
    required Widget child,
    required VoidCallback onTap,
    double scaleFactor = 0.95,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 100),
      tween: Tween(begin: 1.0, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) {
          // Trigger scale down animation
        },
        onTapUp: (_) {
          onTap();
        },
        onTapCancel: () {
          // Reset scale
        },
        child: child,
      ),
    );
  }

  /// Shimmer loading effect
  static Widget shimmer({
    required Widget child,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1500),
      tween: Tween(begin: -1.0, end: 2.0),
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (value - 1).clamp(0.0, 1.0),
                value.clamp(0.0, 1.0),
                (value + 1).clamp(0.0, 1.0),
              ],
              colors: [
                baseColor ?? Colors.grey.shade300,
                highlightColor ?? Colors.grey.shade100,
                baseColor ?? Colors.grey.shade300,
              ],
            ),
          ),
          child: child,
        );
      },
      child: child,
    );
  }

  /// Ripple effect for custom widgets
  static Widget ripple({
    required Widget child,
    required VoidCallback onTap,
    Color? rippleColor,
    BorderRadius? borderRadius,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: rippleColor?.withOpacity(0.2),
        highlightColor: rippleColor?.withOpacity(0.1),
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }

  /// Success checkmark animation
  static Widget successCheckmark({
    required bool show,
    Color color = Colors.green,
    double size = 24.0,
  }) {
    return AnimatedScale(
      scale: show ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      child: AnimatedRotation(
        turns: show ? 0.0 : 0.5,
        duration: const Duration(milliseconds: 300),
        child: Icon(
          Icons.check_circle,
          color: color,
          size: size,
        ),
      ),
    );
  }

  /// Loading pulse animation
  static Widget loadingPulse({
    required Widget child,
    bool isLoading = false,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isLoading
          ? TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              tween: Tween(begin: 0.5, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: child,
                );
              },
              child: child,
            )
          : child,
    );
  }
}

/// Smooth scroll behavior for better UX
class SmoothScrollBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}

/// Custom curve animations
class CustomCurves {
  static const Curve gentleSpring = Curves.easeOutBack;
  static const Curve smoothEntry = Curves.easeOutCubic;
  static const Curve quickFade = Curves.easeInOut;
  static const Curve elasticEntry = Curves.elasticOut;
}
