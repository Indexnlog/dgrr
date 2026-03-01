import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../data/models/notification_model.dart';
import '../providers/notification_providers.dart';

/// 알림 목록 페이지
class NotificationListPage extends ConsumerWidget {
  const NotificationListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(myNotificationsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '알림',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(myNotificationsProvider),
              color: AppTheme.teamRed,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PhosphorIconsRegular.bell,
                        color: AppTheme.textMuted.withValues(alpha: 0.5),
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '알림이 없습니다',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myNotificationsProvider),
            color: AppTheme.teamRed,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];
                return _NotificationTile(notification: n);
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppTheme.teamRed,
            strokeWidth: 2.5,
          ),
        ),
        error: (e, _) => ErrorRetryView(
          message: '알림을 불러올 수 없습니다',
          detail: e.toString(),
          onRetry: () => ref.invalidate(myNotificationsProvider),
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});
  final NotificationModel notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider)?.uid;
    final teamId = ref.watch(currentTeamIdProvider);
    final isUnread = uid != null && !(notification.readBy?.contains(uid) ?? false);

    return GestureDetector(
      onTap: () async {
        if (uid != null && teamId != null) {
          await ref.read(notificationDataSourceProvider).markAsRead(
                teamId,
                notification.notificationId,
                uid,
              );
        }
        _navigateToRelated(context, notification);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread
              ? AppTheme.fixedBlue.withValues(alpha: 0.08)
              : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnread
                ? AppTheme.fixedBlue.withValues(alpha: 0.3)
                : AppTheme.divider,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _iconForType(notification.type),
              color: AppTheme.fixedBlue,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  if (notification.message != null &&
                      notification.message!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      notification.message!,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(notification.createdAt),
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorIconsRegular.caretRight,
              color: AppTheme.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String? type) {
    return switch (type) {
      'reservationSuccess' => PhosphorIconsRegular.calendarCheck,
      'pollCreated' => PhosphorIconsRegular.listChecks,
      'matchConfirmed' => PhosphorIconsRegular.soccerBall,
      _ => PhosphorIconsRegular.bell,
    };
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return DateFormat('M/d HH:mm').format(date);
  }

  void _navigateToRelated(BuildContext context, NotificationModel n) {
    switch (n.type) {
      case 'reservationSuccess':
        if (n.relatedId != null) {
          context.push('/schedule/reservation-notices/${n.relatedId}');
        } else {
          context.push('/schedule/reservation-notices');
        }
        break;
      case 'pollCreated':
        if (n.relatedId != null) {
          context.push('/schedule/polls/${n.relatedId}');
        } else {
          context.push('/schedule/polls');
        }
        break;
      case 'matchConfirmed':
        if (n.relatedId != null) {
          context.push('/match/${n.relatedId}');
        } else {
          context.go('/match');
        }
        break;
      default:
        break;
    }
  }
}
