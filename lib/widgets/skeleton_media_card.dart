import 'package:flutter/material.dart';
import 'dart:ui';

class SkeletonMediaCard extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonMediaCard({
    Key? key,
    this.width = double.infinity,
    this.height = 120,
    this.borderRadius = 28,
  }) : super(key: key);

  @override
  State<SkeletonMediaCard> createState() => _SkeletonMediaCardState();
}

class _SkeletonMediaCardState extends State<SkeletonMediaCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        color: const Color(0xFF11212D).withOpacity(0.28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF06141B).withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          width: 1.2,
          style: BorderStyle.solid,
          color: Colors.white.withOpacity(0.10),
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          children: [
            // Liquid glass blur
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: const SizedBox.expand(),
            ),
            // Shimmer effect
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(
                      _animation.value * MediaQuery.of(context).size.width,
                      0,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.1),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Skeleton content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Skeleton icon
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      // Skeleton star
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Skeleton title
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Skeleton subtitle
                  Container(
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double itemWidth;

  const SkeletonList({
    Key? key,
    this.itemCount = 6,
    this.itemHeight = 120,
    this.itemWidth = double.infinity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return SkeletonMediaCard(width: itemWidth, height: itemHeight);
      },
    );
  }
}
