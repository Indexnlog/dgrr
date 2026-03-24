import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Crashlytics 공통 유틸
class CrashlyticsService {
  CrashlyticsService._();

  static bool get _isSupported => !kIsWeb;

  static Future<void> initialize() async {
    if (!_isSupported) {
      return;
    }
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      !kDebugMode,
    );
  }

  static Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String reason = 'handled',
    bool fatal = false,
  }) async {
    if (!_isSupported) {
      return;
    }
    await FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: fatal,
    );
  }

  static Future<void> setKey(String key, String value) async {
    if (!_isSupported) {
      return;
    }
    await FirebaseCrashlytics.instance.setCustomKey(key, value);
  }
}
