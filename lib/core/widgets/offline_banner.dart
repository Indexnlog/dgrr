import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 네트워크 연결 상태를 감지하고 오프라인 시 배너 표시
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = Connectivity().onConnectivityChanged.listen(_updateStatus);
    Connectivity().checkConnectivity().then(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final offline = results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none);
    if (mounted && _isOffline != offline) {
      setState(() => _isOffline = offline);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isOffline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: AppTheme.absentRed.withValues(alpha: 0.9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  '오프라인 — 네트워크 연결을 확인해 주세요',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
