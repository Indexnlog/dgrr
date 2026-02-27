import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 카드 스켈레톤 (로딩 시 CircularProgressIndicator 대체)
class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key, 
    this.height = 120,
    this.borderRadius = 16,
  });

  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShimmerLine(width: 120, height: 16),
            const SizedBox(height: 12),
            _ShimmerLine(width: double.infinity, height: 12),
            const SizedBox(height: 8),
            _ShimmerLine(width: 200, height: 12),
            const Spacer(),
            _ShimmerLine(width: 80, height: 10),
          ],
        ),
      ),
    );
  }
}

class _ShimmerLine extends StatefulWidget {
  const _ShimmerLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  State<_ShimmerLine> createState() => _ShimmerLineState();
}

class _ShimmerLineState extends State<_ShimmerLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppTheme.textMuted.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }
}
