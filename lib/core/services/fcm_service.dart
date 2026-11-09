import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../firebase_options.dart';
import '../errors/app_logger.dart';
import '../repositories/exam_repository.dart';
import '../theme/app_theme.dart';
import 'cache_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
}

/// Firebase Cloud Messaging (FCM) Push Notification Service
/// Handles background push delivery, token registration with PostgreSQL,
/// and interaction telemetry logging across Android, iOS, and Web.
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  bool _initialized = false;
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler);
      }

      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // ignore: deprecated_member_use
        _fcmToken = await FirebaseMessaging.instance.getToken();
        if (_fcmToken != null) {
          _syncTokenWithBackend(_fcmToken!);
        }

        // ignore: deprecated_member_use
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          _syncTokenWithBackend(newToken);
        });
      }

      // Handle message when app is in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.info('FCM Foreground Message received: ${message.messageId}');
      });

      // Handle notification open/tap from system tray
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        final notifId =
            message.data['notificationId'] ?? message.messageId ?? '';
        final actionType = message.data['actionType'] ?? 'tap';
        ExamRepository().recordNotificationTapEvent(
          notificationId: notifId,
          event: 'tap',
          actionId: actionType,
          appState: 'background',
        );
      });

      _initialized = true;
    } catch (e) {
      AppLogger.warn('Firebase Messaging initialization skipped: $e');
    }
  }

  Future<void> _syncTokenWithBackend(String token) async {
    try {
      final cachedDeviceId = CacheService().read<String>('device_unique_id');
      String platformName;
      if (kIsWeb) {
        platformName = 'web';
      } else if (Platform.isAndroid) {
        platformName = 'android';
      } else if (Platform.isIOS) {
        platformName = 'ios';
      } else {
        platformName = 'other';
      }

      final deviceId = cachedDeviceId ??
          'prep404_${platformName}_${token.hashCode.abs()}';
      if (cachedDeviceId == null) {
        CacheService().write('device_unique_id', deviceId);
      }

      await ExamRepository().registerDeviceToken(
        fcmToken: token,
        deviceId: deviceId,
        platform: platformName,
      );
    } catch (_) {}
  }

  /// Explicitly request notification permissions with token sync
  Future<bool> requestNotificationPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;

      if (granted) {
        // ignore: deprecated_member_use
        _fcmToken = await FirebaseMessaging.instance.getToken();
        if (_fcmToken != null) {
          await _syncTokenWithBackend(_fcmToken!);
        }
      }
      return granted;
    } catch (_) {
      return false;
    }
  }

  /// Display high-converting in-app permission prompt if not yet granted
  Future<void> showPermissionPromptIfNeeded(BuildContext context) async {
    final prompted =
        CacheService().read<bool>('notification_prompted') ?? false;
    if (prompted) return;

    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        CacheService().write('notification_prompted', true);
        return;
      }
    } catch (_) {}

    if (!context.mounted) return;
    CacheService().write('notification_prompted', true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colors = ctx.colors;
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: colors.cardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.tangerine.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: colors.tangerine,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Stay Ahead with Instant Alerts! 🔔',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Get timely reminders when your daily university exams open, live 1v1 battles start, and study streak alerts so you never lose your flame.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.tangerine,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await requestNotificationPermission();
                  },
                  child: const Text(
                    'Enable Notifications',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Maybe Later',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
