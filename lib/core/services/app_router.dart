import 'package:flutter/material.dart';

enum SlideDirection { leftToRight, rightToLeft, topToBottom, bottomToTop }

class AppRoutes {
  static GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
  static BuildContext get context => navKey.currentContext!;
  // Basic back navigation with optional data return
  static void back<T>([T? result]) {
    if (navKey.currentState != null && navKey.currentState!.canPop()) {
      navKey.currentState!.pop(result);
    }
  }

  // Push with custom transition
  static Future<T?> push<T>(
    Widget page, {
    SlideDirection slideDirection = SlideDirection.rightToLeft,
    Duration duration = const Duration(milliseconds: 300),
    bool fade = false,
    bool scale = false,
  }) async {
    return await Navigator.push<T>(
      context,
      _buildPageRoute(
        page,
        slideDirection: slideDirection,
        duration: duration,
        fade: fade,
        scale: scale,
      ) as Route<T>,
    );
  }

  // Push replacement with custom transition
  static Future<T?> pushReplacement<T, TO>(
    Widget page, {
    SlideDirection slideDirection = SlideDirection.rightToLeft,
    Duration duration = const Duration(milliseconds: 300),
    bool fade = false,
    bool scale = false,
    TO? result,
  }) async {
    return await Navigator.pushReplacement<T, TO>(
      context,
      _buildPageRoute(
        page,
        slideDirection: slideDirection,
        duration: duration,
        fade: fade,
        scale: scale,
      ) as Route<T>,
      result: result,
    );
  }

  // Push and remove until with custom transition
  static Future<T?> pushAndRemoveUntil<T>(
    Widget page,
    bool Function(Route<dynamic>) predicate, {
    SlideDirection slideDirection = SlideDirection.rightToLeft,
    Duration duration = const Duration(milliseconds: 300),
    bool fade = false,
    bool scale = false,
  }) async {
    return await Navigator.pushAndRemoveUntil<T>(
      context,
      _buildPageRoute(
        page,
        slideDirection: slideDirection,
        duration: duration,
        fade: fade,
        scale: scale,
      ) as Route<T>,
      predicate,
    );
  }

  // Pop until a specific route
  static void popUntil(bool Function(Route<dynamic>) predicate) {
    Navigator.popUntil(context, predicate);
  }

  // Build custom page route with animations
  static PageRouteBuilder _buildPageRoute(
    Widget page, {
    SlideDirection slideDirection = SlideDirection.rightToLeft,
    Duration duration = const Duration(milliseconds: 300),
    bool fade = false,
    bool scale = false,
  }) {
    return PageRouteBuilder(
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = _getBeginOffset(slideDirection);
        var end = Offset.zero;
        var curve = Curves.easeInOutCubic;
        var slideAnimation = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        var fadeAnimation = Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );
        var scaleAnimation = Tween(begin: 0.8, end: 1.0).chain(
          CurveTween(curve: curve),
        );
        Widget result = child;
        if (scale) {
          result = ScaleTransition(
            scale: animation.drive(scaleAnimation),
            child: result,
          );
        }
        if (fade) {
          result = FadeTransition(
            opacity: animation.drive(fadeAnimation),
            child: result,
          );
        }
        result = SlideTransition(
          position: animation.drive(slideAnimation),
          child: result,
        );
        return result;
      },
    );
  }

  // Helper method to get begin offset based on slide direction
  static Offset _getBeginOffset(SlideDirection direction) {
    switch (direction) {
      case SlideDirection.leftToRight:
        return const Offset(-1.0, 0.0);
      case SlideDirection.rightToLeft:
        return const Offset(1.0, 0.0);
      case SlideDirection.topToBottom:
        return const Offset(0.0, -1.0);
      case SlideDirection.bottomToTop:
        return const Offset(0.0, 1.0);
    }
  }
}
