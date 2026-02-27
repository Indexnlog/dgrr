import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/offline_banner.dart';
import '../../features/matches/presentation/providers/match_providers.dart';
import '../../features/notifications/presentation/providers/fcm_provider.dart';
import 'app_top_bar.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fcmProvider).syncTokenToFirestore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final todayCount = ref.watch(todayOrLiveMatchCountProvider);
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Column(
        children: [
          const AppTopBar(),
          Expanded(
            child: OfflineBanner(child: widget.navigationShell),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _NavItem(
                  icon: PhosphorIconsRegular.house,
                  activeIcon: PhosphorIconsFill.house,
                  label: '홈',
                  isActive: widget.navigationShell.currentIndex == 0,
                  onTap: () => widget.navigationShell.goBranch(0),
                ),
                _NavItem(
                  icon: PhosphorIconsRegular.calendarBlank,
                  activeIcon: PhosphorIconsFill.calendar,
                  label: '일정',
                  isActive: widget.navigationShell.currentIndex == 1,
                  onTap: () => widget.navigationShell.goBranch(1),
                ),
                _NavItem(
                  icon: PhosphorIconsRegular.soccerBall,
                  activeIcon: PhosphorIconsFill.soccerBall,
                  label: '매치',
                  isActive: widget.navigationShell.currentIndex == 2,
                  onTap: () => widget.navigationShell.goBranch(2),
                  badgeCount: todayCount > 0 ? todayCount : null,
                ),
                _NavItem(
                  icon: PhosphorIconsRegular.user,
                  activeIcon: PhosphorIconsFill.user,
                  label: 'MY',
                  isActive: widget.navigationShell.currentIndex == 3,
                  onTap: () => widget.navigationShell.goBranch(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeCount,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (badgeCount != null && badgeCount! > 0)
                Badge(
                  backgroundColor: AppTheme.accentLime,
                  textColor: Colors.black,
                  label: Text(
                    badgeCount! > 9 ? '9+' : '$badgeCount',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
                  ),
                  child: _buildIcon(),
                )
              else
                _buildIcon(),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Icon(
      isActive ? activeIcon : icon,
      size: 22,
      color: isActive ? AppTheme.accentLime : Colors.white.withValues(alpha: 0.6),
    );
  }
}
