import 'package:flutter/material.dart';

class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final Duration animationDuration;
  final double scaleFactor;
  final bool enableHapticFeedback;
  final String? tooltip;

  const AnimatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.style,
    this.animationDuration = const Duration(milliseconds: 150),
    this.scaleFactor = 0.95,
    this.enableHapticFeedback = true,
    this.tooltip,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = true);
      _controller.forward();
      
      if (widget.enableHapticFeedback) {
        // Add haptic feedback
        // HapticFeedback.lightImpact();
      }
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget button = GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return button;
  }
}

class AnimatedElevatedButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final Duration animationDuration;
  final double scaleFactor;
  final bool enableHapticFeedback;
  final String? tooltip;

  const AnimatedElevatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.style,
    this.animationDuration = const Duration(milliseconds: 150),
    this.scaleFactor = 0.95,
    this.enableHapticFeedback = true,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      onPressed: onPressed,
      animationDuration: animationDuration,
      scaleFactor: scaleFactor,
      enableHapticFeedback: enableHapticFeedback,
      tooltip: tooltip,
      child: ElevatedButton(
        onPressed: null, // Handled by AnimatedButton
        style: style,
        child: child,
      ),
    );
  }
}

class AnimatedOutlinedButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final Duration animationDuration;
  final double scaleFactor;
  final bool enableHapticFeedback;
  final String? tooltip;

  const AnimatedOutlinedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.style,
    this.animationDuration = const Duration(milliseconds: 150),
    this.scaleFactor = 0.95,
    this.enableHapticFeedback = true,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      onPressed: onPressed,
      animationDuration: animationDuration,
      scaleFactor: scaleFactor,
      enableHapticFeedback: enableHapticFeedback,
      tooltip: tooltip,
      child: OutlinedButton(
        onPressed: null, // Handled by AnimatedButton
        style: style,
        child: child,
      ),
    );
  }
}

class AnimatedTextButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final Duration animationDuration;
  final double scaleFactor;
  final bool enableHapticFeedback;
  final String? tooltip;

  const AnimatedTextButton({
    super.key,
    required this.child,
    this.onPressed,
    this.style,
    this.animationDuration = const Duration(milliseconds: 150),
    this.scaleFactor = 0.95,
    this.enableHapticFeedback = true,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      onPressed: onPressed,
      animationDuration: animationDuration,
      scaleFactor: scaleFactor,
      enableHapticFeedback: enableHapticFeedback,
      tooltip: tooltip,
      child: TextButton(
        onPressed: null, // Handled by AnimatedButton
        style: style,
        child: child,
      ),
    );
  }
}

class AnimatedIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final Duration animationDuration;
  final double scaleFactor;
  final bool enableHapticFeedback;
  final String? tooltip;

  const AnimatedIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.style,
    this.animationDuration = const Duration(milliseconds: 150),
    this.scaleFactor = 0.9,
    this.enableHapticFeedback = true,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      onPressed: onPressed,
      animationDuration: animationDuration,
      scaleFactor: scaleFactor,
      enableHapticFeedback: enableHapticFeedback,
      tooltip: tooltip,
      child: IconButton(
        onPressed: null, // Handled by AnimatedButton
        style: style,
        icon: icon,
      ),
    );
  }
}

class AnimatedFloatingActionButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final Duration animationDuration;
  final double scaleFactor;
  final bool enableHapticFeedback;
  final String? tooltip;

  const AnimatedFloatingActionButton({
    super.key,
    required this.child,
    this.onPressed,
    this.style,
    this.animationDuration = const Duration(milliseconds: 150),
    this.scaleFactor = 0.9,
    this.enableHapticFeedback = true,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      onPressed: onPressed,
      animationDuration: animationDuration,
      scaleFactor: scaleFactor,
      enableHapticFeedback: enableHapticFeedback,
      tooltip: tooltip,
      child: FloatingActionButton(
        onPressed: null, // Handled by AnimatedButton
        child: child,
      ),
    );
  }
}
