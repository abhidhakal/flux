import 'package:flutter/material.dart';

class PageTransitions {
  // Slide transition from right to left
  static Widget slideFromRight(Widget child, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      )),
      child: child,
    );
  }

  // Slide transition from left to right
  static Widget slideFromLeft(Widget child, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      )),
      child: child,
    );
  }

  // Slide transition from bottom to top
  static Widget slideFromBottom(Widget child, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: child,
    );
  }

  // Scale transition
  static Widget scaleTransition(Widget child, Animation<double> animation) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      )),
      child: child,
    );
  }

  // Fade transition
  static Widget fadeTransition(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  // Combined slide and fade transition
  static Widget slideAndFade(Widget child, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  // Scale and fade transition
  static Widget scaleAndFade(Widget child, Animation<double> animation) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}

// Custom page route with smooth transitions
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final PageTransitionType transitionType;
  final Duration duration;

  SmoothPageRoute({
    required this.child,
    this.transitionType = PageTransitionType.slideFromRight,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            switch (transitionType) {
              case PageTransitionType.slideFromRight:
                return PageTransitions.slideFromRight(child, animation);
              case PageTransitionType.slideFromLeft:
                return PageTransitions.slideFromLeft(child, animation);
              case PageTransitionType.slideFromBottom:
                return PageTransitions.slideFromBottom(child, animation);
              case PageTransitionType.scale:
                return PageTransitions.scaleTransition(child, animation);
              case PageTransitionType.fade:
                return PageTransitions.fadeTransition(child, animation);
              case PageTransitionType.slideAndFade:
                return PageTransitions.slideAndFade(child, animation);
              case PageTransitionType.scaleAndFade:
                return PageTransitions.scaleAndFade(child, animation);
            }
          },
        );
}

enum PageTransitionType {
  slideFromRight,
  slideFromLeft,
  slideFromBottom,
  scale,
  fade,
  slideAndFade,
  scaleAndFade,
}

// Extension to make navigation easier
extension NavigatorExtensions on NavigatorState {
  Future<T?> pushSmooth<T extends Object?>(
    Widget page, {
    PageTransitionType transitionType = PageTransitionType.slideFromRight,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return push<T>(SmoothPageRoute<T>(
      child: page,
      transitionType: transitionType,
      duration: duration,
    ));
  }

  Future<T?> pushReplacementSmooth<T extends Object?, TO extends Object?>(
    Widget page, {
    PageTransitionType transitionType = PageTransitionType.slideFromRight,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return pushReplacement<T, TO>(SmoothPageRoute<T>(
      child: page,
      transitionType: transitionType,
      duration: duration,
    ));
  }

  Future<T?> pushAndRemoveUntilSmooth<T extends Object?>(
    Widget page, {
    PageTransitionType transitionType = PageTransitionType.slideFromRight,
    Duration duration = const Duration(milliseconds: 300),
    RoutePredicate? predicate,
  }) {
    return pushAndRemoveUntil<T>(
      SmoothPageRoute<T>(
        child: page,
        transitionType: transitionType,
        duration: duration,
      ),
      predicate ?? (route) => false,
    );
  }
}

// Extension for BuildContext to make navigation easier
extension ContextExtensions on BuildContext {
  Future<T?> pushSmooth<T extends Object?>(
    Widget page, {
    PageTransitionType transitionType = PageTransitionType.slideFromRight,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return Navigator.of(this).pushSmooth<T>(
      page,
      transitionType: transitionType,
      duration: duration,
    );
  }

  Future<T?> pushReplacementSmooth<T extends Object?, TO extends Object?>(
    Widget page, {
    PageTransitionType transitionType = PageTransitionType.slideFromRight,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return Navigator.of(this).pushReplacementSmooth<T, TO>(
      page,
      transitionType: transitionType,
      duration: duration,
    );
  }

  Future<T?> pushAndRemoveUntilSmooth<T extends Object?>(
    Widget page, {
    PageTransitionType transitionType = PageTransitionType.slideFromRight,
    Duration duration = const Duration(milliseconds: 300),
    RoutePredicate? predicate,
  }) {
    return Navigator.of(this).pushAndRemoveUntilSmooth<T>(
      page,
      transitionType: transitionType,
      duration: duration,
      predicate: predicate,
    );
  }
}
