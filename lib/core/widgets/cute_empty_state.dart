import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 빈 상태(아무 데이터 없음)에서 보여주는 "귀여운" 안내 위젯
class CuteEmptyState extends StatefulWidget {
  const CuteEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.accentColor,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? accentColor;

  @override
  State<CuteEmptyState> createState() => _CuteEmptyStateState();
}

class _CuteEmptyStateState extends State<CuteEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _float = Tween<double>(begin: 0, end: 6).animate(
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
    final accent = widget.accentColor ?? AppTheme.accentLime;

    return AnimatedBuilder(
      animation: _float,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_float.value),
          child: child,
        );
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.22)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.14),
                  Colors.white.withValues(alpha: 0.04),
                ],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: accent.withValues(alpha: 0.25)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(widget.icon, color: accent, size: 22),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.subtitle != null &&
                          widget.subtitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.subtitle!,
                          style: TextStyle(
                            color: AppTheme.textSecondary.withValues(alpha: 0.9),
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

