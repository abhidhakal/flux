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
              case PageTransitionType.slideFromBottom:
                return PageTransitions.slideFromBottom(child, animation);
            }
          },
        );
}

enum PageTransitionType {
  slideFromRight,
  slideFromBottom,
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
}
