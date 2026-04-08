import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:kivicare_patient/screens/booking/appointment_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../models/notificationdata_model.dart';
import '../screens/booking/model/appointments_res_model.dart';
import 'app_common.dart';
import 'common_base.dart';
import 'constants.dart';

class PushNotificationService {
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final Set<String> _handledMessageIds = <String>{};
  StreamSubscription<String>? _tokenRefreshSubscription;

  bool _listenersRegistered = false;
  bool _localNotificationsInitialized = false;

  Future<void> setupFirebaseMessaging() async {
    await _initializeLocalNotifications();
    await initFirebaseMessaging();
    await enableIOSNotifications();
  }

  Future<void> initFirebaseMessaging() async {
    NotificationSettings settings;
    try {
      settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: Platform.isIOS,
      );
    } catch (_) {
      return;
    }

    final bool canHandleNotifications =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!canHandleNotifications) return;

    await registerNotificationListeners();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> registerFCMAndTopics() async {
    if (!isLoggedIn.value) return;

    if (Platform.isIOS) {
      String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (apnsToken == null) {
        await Future.delayed(const Duration(seconds: 3));
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      }
      if (kDebugMode) {
        log(
          "===============${FirebaseTopicConst.apnsNotificationTokenKey}===============\n${apnsToken != null}",
        );
      }
    }

    await subScribeToTopic();

    final String? token = await FirebaseMessaging.instance.getToken();
    if (kDebugMode) {
      log(
        "===============${FirebaseTopicConst.fcmNotificationTokenKey}===============\n${token != null}",
      );
    }

    _tokenRefreshSubscription ??=
        FirebaseMessaging.instance.onTokenRefresh.listen((_) async {
      await subScribeToTopic();
    });
  }

  Future<void> subScribeToTopic() async {
    await FirebaseMessaging.instance.subscribeToTopic(appNameTopic);
    await FirebaseMessaging.instance.subscribeToTopic(
      "${FirebaseTopicConst.userWithUnderscoreKey}${loginUserData.value.id}",
    );
  }

  Future<void> unsubscribeFirebaseTopic() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;

    await FirebaseMessaging.instance.unsubscribeFromTopic(appNameTopic);
    if (loginUserData.value.id > 0) {
      await FirebaseMessaging.instance.unsubscribeFromTopic(
        '${FirebaseTopicConst.userWithUnderscoreKey}${loginUserData.value.id}',
      );
    }
  }

  void handleNotificationClick(RemoteMessage message,
      {bool isForeGround = false}) {
    final String messageId =
        message.messageId ?? message.data['message_id']?.toString() ?? '';

    if (messageId.isNotEmpty && _handledMessageIds.contains(messageId)) {
      return;
    }

    if (messageId.isNotEmpty) {
      _handledMessageIds.add(messageId);
      if (_handledMessageIds.length > 300) {
        _handledMessageIds.remove(_handledMessageIds.first);
      }
    }

    final dynamic rawUrl = message.data['url'];
    if (rawUrl is String && rawUrl.trim().isNotEmpty) {
      final Uri? parsed = Uri.tryParse(rawUrl.trim());
      if (parsed != null &&
          (parsed.scheme == 'https' || parsed.scheme == 'http')) {
        commonLaunchUrl(rawUrl, launchMode: LaunchMode.externalApplication);
      }
    }

    if (kDebugMode) {
      printLogsNotificationData(message);
    }

    NotificationData.fromJson(message.data);

    if (isForeGround) {
      final String title = message.notification?.title?.trim() ?? '';
      final String body = message.notification?.body?.trim() ?? '';
      if (title.isNotEmpty || body.isNotEmpty) {
        showNotification(currentTimeStamp(), title, body, message);
      }
      return;
    }

    _handleAdditionalData(message.data);
  }

  void _handleAdditionalData(Map<String, dynamic> data) {
    try {
      final dynamic additionalRaw = data[FirebaseTopicConst.additionalDataKey];
      Map<String, dynamic> additionalData = <String, dynamic>{};

      if (additionalRaw is String && additionalRaw.trim().isNotEmpty) {
        final dynamic parsed = jsonDecode(additionalRaw);
        if (parsed is Map<String, dynamic>) {
          additionalData = parsed;
        }
      } else if (additionalRaw is Map<String, dynamic>) {
        additionalData = additionalRaw;
      }

      if (additionalData.isEmpty) return;

      final dynamic notIdRaw = additionalData[FirebaseTopicConst.idKey];
      final int? notificationId =
          notIdRaw is int ? notIdRaw : int.tryParse(notIdRaw?.toString() ?? '');

      if (notificationId != null) {
        Get.to(
          () => AppointmentDetail(),
          arguments: AppointmentData(id: notificationId),
        );
      }
    } catch (_) {
      // Keep push payload parsing resilient.
    }
  }

  Future<void> registerNotificationListeners() async {
    if (_listenersRegistered) return;

    _listenersRegistered = true;

    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        handleNotificationClick(message, isForeGround: true);
      },
    );

    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        handleNotificationClick(message);
      },
    );

    FirebaseMessaging.instance.getInitialMessage().then(
      (RemoteMessage? message) {
        if (message != null) {
          handleNotificationClick(message);
        }
      },
    );
  }

  Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsInitialized) return;

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      FirebaseTopicConst.notificationChannelIdKey,
      FirebaseTopicConst.notificationChannelNameKey,
      importance: Importance.high,
      enableLights: true,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_stat_notification');

    const DarwinInitializationSettings iOS = DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: iOS,
      macOS: iOS,
    );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        final String? payload = details.payload;
        if (payload == null || payload.trim().isEmpty) return;

        try {
          final dynamic decoded = jsonDecode(payload);
          if (decoded is Map<String, dynamic>) {
            _handleAdditionalData(decoded);
          }
        } catch (_) {
          // Ignore malformed payloads.
        }
      },
    );

    _localNotificationsInitialized = true;
  }

  Future<void> showNotification(
    int id,
    String title,
    String message,
    RemoteMessage remoteMessage,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      FirebaseTopicConst.notificationChannelIdKey,
      FirebaseTopicConst.notificationChannelNameKey,
      importance: Importance.high,
      visibility: NotificationVisibility.public,
      priority: Priority.high,
      icon: '@drawable/ic_stat_notification',
      colorized: true,
    );

    const DarwinNotificationDetails darwinPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentSound: true,
      presentBanner: true,
      presentBadge: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics,
      macOS: darwinPlatformChannelSpecifics,
    );

    await _localNotificationsPlugin.show(
      id,
      title,
      message,
      platformChannelSpecifics,
      payload: jsonEncode(remoteMessage.data),
    );
  }

  Future<void> enableIOSNotifications() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void printLogsNotificationData(RemoteMessage message) {
    if (!kDebugMode) return;

    log("====================");
    log('${FirebaseTopicConst.notificationDataKey} keys: ${message.data.keys.toList()}');
    log('${FirebaseTopicConst.notificationTitleKey} available: ${message.notification?.title != null}');
    log('${FirebaseTopicConst.notificationBodyKey} available: ${message.notification?.body != null}');
    log('${FirebaseTopicConst.messageDataMessageIdKey} : ${message.messageId}');
  }
}
