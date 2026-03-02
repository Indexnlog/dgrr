import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 전체 팀에서 가입 신청 대기 수 (collectionGroup)
final pendingCountProvider = StreamProvider<int>((ref) {
  return FirebaseFirestore.instance
      .collectionGroup('members')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((s) => s.docs.length);
});

/// 어드민 레이아웃 (사이드바 + 콘텐츠)
class AdminShellPage extends ConsumerWidget {
  const AdminShellPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).value;

    if (user == null) {
      return const _RedirectToLogin();
    }

    final pendingCount = ref.watch(pendingCountProvider).value ?? 0;

    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            currentPath: GoRouterState.of(context).matchedLocation,
            pendingCount: pendingCount,
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class _RedirectToLogin extends ConsumerWidget {
  const _RedirectToLogin();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.go('/admin/login');
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.currentPath, required this.pendingCount});

  final String currentPath;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '영원FC 어드민',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 24),
                _NavItem(
                  icon: Icons.groups,
                  label: '팀 목록',
                  path: '/admin/teams',
                  currentPath: currentPath,
                  badge: pendingCount,
                  onTap: () => context.go('/admin/teams'),
                ),
                _NavItem(
                  icon: Icons.add_circle_outline,
                  label: '팀 생성',
                  path: '/admin/teams/create',
                  currentPath: currentPath,
                  onTap: () => context.go('/admin/teams/create'),
                ),
              ],
            ),
          ),
          // 로그아웃은 사이드바 하단에 고정
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) context.go('/admin/login');
            },
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.currentPath,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final String path;
  final String currentPath;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final isActive = currentPath == path || currentPath.startsWith('$path/');
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(label),
      trailing: badge > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade600,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      selected: isActive,
      onTap: onTap,
    );
  }
}
