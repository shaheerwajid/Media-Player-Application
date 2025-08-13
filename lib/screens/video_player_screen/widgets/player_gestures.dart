import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class PlayerGestures extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Function(TapDownDetails, BoxConstraints)? onTapDown;
  final Function(DragStartDetails)? onHorizontalDragStart;
  final Function(DragUpdateDetails)? onHorizontalDragUpdate;
  final Function(DragEndDetails)? onHorizontalDragEnd;
  final Function(DragStartDetails, BoxConstraints)? onVerticalDragStart;
  final Function(DragUpdateDetails, BoxConstraints)? onVerticalDragUpdate;
  final Function(DragEndDetails)? onVerticalDragEnd;
  final Function(TapDownDetails, BoxConstraints)? onDoubleTapDown;
  final VoidCallback? onDoubleTap;

  const PlayerGestures({
    Key? key,
    required this.child,
    this.onTap,
    this.onTapDown,
    this.onHorizontalDragStart,
    this.onHorizontalDragUpdate,
    this.onHorizontalDragEnd,
    this.onVerticalDragStart,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
    this.onDoubleTapDown,
    this.onDoubleTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onTapDown: (details) {
            onTapDown?.call(details, constraints);
          },
          onDoubleTapDown: (details) {
            onDoubleTapDown?.call(details, constraints);
          },
          onDoubleTap: onDoubleTap,
          onHorizontalDragStart: onHorizontalDragStart,
          onHorizontalDragUpdate: onHorizontalDragUpdate,
          onHorizontalDragEnd: onHorizontalDragEnd,
          onVerticalDragStart: (details) {
            onVerticalDragStart?.call(details, constraints);
          },
          onVerticalDragUpdate: (details) {
            onVerticalDragUpdate?.call(details, constraints);
          },
          onVerticalDragEnd: onVerticalDragEnd,
          child: child,
        );
      },
    );
  }
}
