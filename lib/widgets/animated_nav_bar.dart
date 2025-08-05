import 'package:flutter/material.dart';
import 'dart:ui';

class AnimatedNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavBarItem> items;

  const AnimatedNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : super(key: key);

  @override
  State<AnimatedNavBar> createState() => _AnimatedNavBarState();
}

class _AnimatedNavBarState extends State<AnimatedNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bumpAnimation;
  late int _oldIndex;

  @override
  void initState() {
    super.initState();
    _oldIndex = widget.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _bumpAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != _oldIndex) {
      _controller.forward(from: 0);
      _oldIndex = widget.currentIndex;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _getBumpPosition(double width) {
    final itemWidth = width / widget.items.length;
    return (widget.currentIndex + 0.5) * itemWidth;
  }

  double _getOldBumpPosition(double width) {
    final itemWidth = width / widget.items.length;
    return (_oldIndex + 0.5) * itemWidth;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final navBarHeight = 88.0;
    final floatingIconExtra = 32.0; // extra height for popout
    return SafeArea(
      top: false,
      bottom: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final itemWidth = width / widget.items.length;
          final bumpStart = _getOldBumpPosition(width);
          final bumpEnd = _getBumpPosition(width);
          final bumpX =
              bumpStart + (bumpEnd - bumpStart) * _bumpAnimation.value;
          return SizedBox(
            height: navBarHeight, // Only the bar height, no extra
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                // Glassmorphic bar with bump
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 100.0,
                        sigmaY: 100.0,
                      ), // lighter blur
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          size: Size(width, navBarHeight),
                          painter: _NavBarBumpPainter(
                            bumpX: bumpX,
                            barColor:
                                Colors.transparent, // No overlay, pure glass
                            glassGradient: const LinearGradient(
                              colors: [Colors.transparent, Colors.transparent],
                            ),
                            borderColor: Colors.transparent,
                            shadowColor: Colors.black.withOpacity(0.13),
                            itemCount: widget.items.length,
                            primary: primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Floating icon (popout) above the bar
                Positioned(
                  left: 0,
                  right: 0,
                  bottom:
                      32, // Lower the floating icon so it docks into the bump
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(widget.items.length, (index) {
                      if (widget.currentIndex == index) {
                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () => widget.onTap(index),
                            child: AnimatedNavBarItem(
                              key: ValueKey('floating_$index'),
                              icon: widget.items[index].icon,
                              label: widget.items[index].label,
                              assetPath: widget.items[index].assetPath,
                              isSelected: true,
                              onTap: () => widget.onTap(index),
                              highlightColor: primary,
                              floating: true,
                            ),
                          ),
                        );
                      } else {
                        return const Expanded(child: SizedBox.shrink());
                      }
                    }),
                  ),
                ),
                // All nav bar items (in place, not floating)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SizedBox(
                    height: navBarHeight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(widget.items.length, (index) {
                        if (widget.currentIndex == index) {
                          // Hide the in-bar icon for the selected index
                          return const Expanded(child: SizedBox.shrink());
                        }
                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () => widget.onTap(index),
                            child: AnimatedNavBarItem(
                              key: ValueKey(index),
                              icon: widget.items[index].icon,
                              label: widget.items[index].label,
                              assetPath: widget.items[index].assetPath,
                              isSelected: false, // not selected in-bar
                              onTap: () => widget.onTap(index),
                              highlightColor: primary,
                              floating: false,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NavBarBumpPainter extends CustomPainter {
  final double bumpX;
  final Color barColor;
  final Gradient glassGradient;
  final Color borderColor;
  final Color shadowColor;
  final int itemCount;
  final Color primary;

  _NavBarBumpPainter({
    required this.bumpX,
    required this.barColor,
    required this.glassGradient,
    required this.borderColor,
    required this.shadowColor,
    required this.itemCount,
    required this.primary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bumpWidth = 68.0;
    final bumpHeight = 32.0;
    final barHeight = size.height;
    final barTop = 0.0;
    final barBottom = barHeight;

    final path = Path();
    // Start from bottom left
    path.moveTo(0, barTop + 18);
    // Left curve up
    path.quadraticBezierTo(0, barTop, 28, barTop);
    // Line to before bump
    final bumpStart = bumpX - bumpWidth / 2;
    final bumpEnd = bumpX + bumpWidth / 2;
    path.lineTo(bumpStart - 18, barTop);
    // Bump curve
    path.cubicTo(
      bumpStart,
      barTop, // control point 1
      bumpX - bumpWidth / 4,
      barTop + bumpHeight, // control point 2
      bumpX,
      barTop + bumpHeight, // bump peak
    );
    path.cubicTo(
      bumpX + bumpWidth / 4,
      barTop + bumpHeight, // control point 1
      bumpEnd,
      barTop, // control point 2
      bumpEnd + 18,
      barTop, // end of bump
    );
    // Line to top right
    path.lineTo(size.width - 28, barTop);
    // Right curve down
    path.quadraticBezierTo(size.width, barTop, size.width, barTop + 18);
    // Down to bottom right
    path.lineTo(size.width, barBottom);
    // Bottom left
    path.lineTo(0, barBottom);
    path.close();

    // Draw outer shadow
    canvas.drawShadow(path, shadowColor.withOpacity(0.18), 16, true);

    // Draw glassmorphic background (gradient + white overlay)
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final Paint glassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.22),
          Colors.white.withOpacity(0.10),
          Colors.white.withOpacity(0.04),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(rect)
      ..color = barColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, glassPaint);

    // Draw frosted highlight at the top edge (fix: reduce opacity, start a few px below top)
    final highlightHeight = 1.0; // was 24
    final highlightYOffset = 2.0; // start 2px below top
    final highlightPaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.13),
              Colors.transparent,
            ], // was 0.25
            stops: [0.0, 0.8],
          ).createShader(
            Rect.fromLTWH(0, highlightYOffset, size.width, highlightHeight),
          );
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
      Rect.fromLTWH(0, highlightYOffset, size.width, highlightHeight),
      highlightPaint,
    );
    canvas.restore();

    // Draw border (fully skip if transparent)
    // (No border drawn)

    // Draw highlight for bump
    final bumpCirclePaint = Paint()
      ..color = primary.withOpacity(0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(
      Offset(bumpX, barTop + bumpHeight - 8),
      32,
      bumpCirclePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _NavBarBumpPainter oldDelegate) {
    return bumpX != oldDelegate.bumpX ||
        barColor != oldDelegate.barColor ||
        shadowColor != oldDelegate.shadowColor ||
        primary != oldDelegate.primary;
  }
}

class NavBarItem {
  final IconData? icon;
  final String label;
  final String? assetPath;

  NavBarItem({this.icon, required this.label, this.assetPath});
}

class AnimatedNavBarItem extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String? assetPath;
  final bool isSelected;
  final VoidCallback onTap;
  final Color highlightColor;
  final bool showLabel;
  final bool floating;

  const AnimatedNavBarItem({
    Key? key,
    this.icon,
    required this.label,
    this.assetPath,
    required this.isSelected,
    required this.onTap,
    required this.highlightColor,
    this.showLabel = true,
    this.floating = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final iconWidget = TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: isSelected ? 1.0 : 0.0),
      curve: Curves.easeOutBack,
      duration: const Duration(milliseconds: 350),
      builder: (context, value, child) {
        // Popout height so icon sits in the bump (smaller value for less popout)
        final double popout = floating ? -4.0 * value : -10 * value;
        return Transform.translate(
          offset: Offset(0, popout),
          child: Transform.scale(
            scale: 1.0 + (0.18 * value),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? highlightColor.withOpacity(0.95)
                    : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: highlightColor.withOpacity(0.25),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: assetPath != null
                  ? Image.asset(assetPath!, width: 32, height: 32)
                  : Icon(
                      icon,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.7),
                      size: 32,
                    ),
            ),
          ),
        );
      },
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget,
        if (showLabel) const SizedBox(height: 4),
        if (showLabel)
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? highlightColor
                  : Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
      ],
    );
  }
}

// Example usage for asset icons in the nav bar
// Replace your nav bar item list with the following:
final navBarItems = [
  NavBarItem(label: 'Video', assetPath: 'assets/video.png'),
  NavBarItem(label: 'Music', assetPath: 'assets/music.png'),
  NavBarItem(label: 'Settings', assetPath: 'assets/settings.png'),
];
