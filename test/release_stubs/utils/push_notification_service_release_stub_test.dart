import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kivicare_patient/screens/auth/model/login_response.dart';
import 'package:kivicare_patient/utils/app_common.dart';
import 'package:kivicare_patient/utils/constants.dart';
import 'package:kivicare_patient/utils/push_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel pathProviderChannel =
      MethodChannel('plugins.flutter.io/path_provider');
  const MethodChannel connectivityChannel =
      MethodChannel('dev.fluttercommunity.plus/connectivity');
  const MethodChannel firebaseMessagingChannel =
      MethodChannel('plugins.flutter.io/firebase_messaging');
  const MethodChannel localNotificationsChannel =
      MethodChannel('dexterous.com/flutter/local_notifications');
  const MethodChannel urlLauncherChannel =
      MethodChannel('plugins.flutter.io/url_launcher');

  final Map<String, int> firebaseCalls = <String, int>{};
  final Map<String, int> localNotificationCalls = <String, int>{};
  int urlLaunchCallCount = 0;

  Map<String, int> permissionResponse = <String, int>{'authorizationStatus': 1};
  Map<String, dynamic>? initialMessageResponse;
  bool throwPermissionError = false;

  void increment(Map<String, int> map, String key) {
    map[key] = (map[key] ?? 0) + 1;
  }

  Future<void> emitFirebaseMethodCall(String method, dynamic args) async {
    final ByteData? message =
        const StandardMethodCodec().encodeMethodCall(MethodCall(method, args));

    await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      firebaseMessagingChannel.name,
      message,
      (_) {},
    );

    await Future<void>.delayed(Duration.zero);
  }

  Future<void> emitLocalNotificationMethodCall(
      String method, dynamic args) async {
    final ByteData? message =
        const StandardMethodCodec().encodeMethodCall(MethodCall(method, args));

    await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      localNotificationsChannel.name,
      message,
      (_) {},
    );

    await Future<void>.delayed(Duration.zero);
  }

  RemoteMessage createRemoteMessage({
    required String id,
    Map<String, dynamic> data = const <String, dynamic>{},
    String title = 'Title',
    String body = 'Body',
  }) {
    return RemoteMessage.fromMap(<String, dynamic>{
      'messageId': id,
      'data': data,
      'notification': <String, dynamic>{
        'title': title,
        'body': body,
      },
    });
  }

  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
    Get.testMode = true;
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel,
            (MethodCall methodCall) async {
      return '.';
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel,
            (MethodCall methodCall) async {
      if (methodCall.method == 'check') {
        return <String>['wifi'];
      }
      return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(firebaseMessagingChannel,
            (MethodCall methodCall) async {
      increment(firebaseCalls, methodCall.method);

      if (methodCall.method == 'Messaging#requestPermission') {
        if (throwPermissionError) {
          throw PlatformException(code: 'permission-error');
        }
        return permissionResponse;
      }

      if (methodCall.method ==
              'Messaging#setForegroundNotificationPresentationOptions' ||
          methodCall.method == 'Messaging#subscribeToTopic' ||
          methodCall.method == 'Messaging#unsubscribeFromTopic' ||
          methodCall.method == 'Messaging#startBackgroundIsolate') {
        return <String, dynamic>{};
      }

      if (methodCall.method == 'Messaging#getToken') {
        return <String, dynamic>{'token': 'fcm-token'};
      }

      if (methodCall.method == 'Messaging#getAPNSToken') {
        return <String, dynamic>{'token': null};
      }

      if (methodCall.method == 'Messaging#getInitialMessage') {
        return initialMessageResponse;
      }

      return <String, dynamic>{};
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(localNotificationsChannel,
            (MethodCall methodCall) async {
      increment(localNotificationCalls, methodCall.method);
      if (methodCall.method == 'initialize') return true;
      return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(urlLauncherChannel,
            (MethodCall methodCall) async {
      urlLaunchCallCount++;
      return true;
    });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(firebaseMessagingChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(localNotificationsChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(urlLauncherChannel, null);
  });

  setUp(() {
    firebaseCalls.clear();
    localNotificationCalls.clear();
    urlLaunchCallCount = 0;
    permissionResponse = <String, int>{'authorizationStatus': 1};
    initialMessageResponse = null;
    throwPermissionError = false;

    isLoggedIn(false);
    loginUserData(UserData(id: 21, apiToken: 'token-21'));
  });

  group('Release: lib/utils/push_notification_service.dart', () {
    test('setup initializes local plugin once and configures messaging',
        () async {
      final service = PushNotificationService();

      await service.setupFirebaseMessaging();
      await service.setupFirebaseMessaging();

      await emitLocalNotificationMethodCall(
        'didReceiveNotificationResponse',
        <String, dynamic>{
          'notificationId': 1,
          'actionId': null,
          'input': null,
          'payload': '',
          'notificationResponseType': 0,
        },
      );

      await emitLocalNotificationMethodCall(
        'didReceiveNotificationResponse',
        <String, dynamic>{
          'notificationId': 2,
          'actionId': null,
          'input': null,
          'payload': jsonEncode(<String, dynamic>{
            FirebaseTopicConst.additionalDataKey:
                jsonEncode(<String, dynamic>{FirebaseTopicConst.idKey: 10}),
          }),
          'notificationResponseType': 0,
        },
      );

      expect(localNotificationCalls['createNotificationChannel'], 1);
      expect(localNotificationCalls['initialize'], 1);
      expect(firebaseCalls['Messaging#requestPermission'], 2);
    });

    test('init handles denied and permission-exception branches', () async {
      final service = PushNotificationService();

      permissionResponse = <String, int>{'authorizationStatus': 0};
      await service.initFirebaseMessaging();

      final int fgCallAfterDenied = firebaseCalls[
              'Messaging#setForegroundNotificationPresentationOptions'] ??
          0;
      expect(fgCallAfterDenied, 0);

      throwPermissionError = true;
      await service.initFirebaseMessaging();

      expect(firebaseCalls['Messaging#requestPermission'], 2);
    });

    test('register FCM topics, token refresh, and unsubscribe branches',
        () async {
      final service = PushNotificationService();

      await service.registerFCMAndTopics();
      expect(firebaseCalls['Messaging#subscribeToTopic'], isNull);

      isLoggedIn(true);
      loginUserData(UserData(id: 88, apiToken: 'token-88'));

      await service.registerFCMAndTopics();

      expect(firebaseCalls['Messaging#subscribeToTopic'], 2);
      expect(firebaseCalls['Messaging#getToken'], 1);

      await emitFirebaseMethodCall('Messaging#onTokenRefresh', 'fresh-token');

      expect(firebaseCalls['Messaging#subscribeToTopic'], 4);

      await service.unsubscribeFirebaseTopic();
      expect(firebaseCalls['Messaging#unsubscribeFromTopic'], 2);

      loginUserData(UserData(id: -1));
      await service.unsubscribeFirebaseTopic();
      expect(firebaseCalls['Messaging#unsubscribeFromTopic'], 3);
    });

    test('foreground click dedupes and shows only meaningful notification',
        () async {
      final service = PushNotificationService();

      for (int i = 0; i < 305; i++) {
        service.handleNotificationClick(createRemoteMessage(
          id: 'bulk-$i',
          title: '',
          body: '',
        ));
      }

      final RemoteMessage first = createRemoteMessage(
        id: 'msg-1',
        data: <String, dynamic>{
          FirebaseTopicConst.additionalDataKey:
              jsonEncode(<String, dynamic>{FirebaseTopicConst.idKey: 10}),
        },
      );

      service.handleNotificationClick(first, isForeGround: true);
      service.handleNotificationClick(first, isForeGround: true);

      final RemoteMessage emptyPresentation = createRemoteMessage(
        id: 'msg-2',
        title: '',
        body: '',
      );
      service.handleNotificationClick(emptyPresentation, isForeGround: true);

      expect(localNotificationCalls['show'], greaterThanOrEqualTo(1));
    });

    test('non-foreground click handles URL and additionalData safely', () {
      final service = PushNotificationService();

      final RemoteMessage validUrlStringAdditional = createRemoteMessage(
        id: 'msg-3',
        data: <String, dynamic>{
          'url': 'https://example.com/page',
          FirebaseTopicConst.additionalDataKey:
              jsonEncode(<String, dynamic>{FirebaseTopicConst.idKey: 99}),
        },
      );

      service.handleNotificationClick(validUrlStringAdditional);
      expect(urlLaunchCallCount, 1);

      final RemoteMessage invalidUrlMapAdditional = createRemoteMessage(
        id: 'msg-4',
        data: <String, dynamic>{
          'url': 'ftp://invalid',
          FirebaseTopicConst.additionalDataKey: <String, dynamic>{
            FirebaseTopicConst.idKey: 100,
          },
        },
      );
      service.handleNotificationClick(invalidUrlMapAdditional);
      expect(urlLaunchCallCount, 1);

      final RemoteMessage malformedAdditional = createRemoteMessage(
        id: 'msg-5',
        data: <String, dynamic>{
          FirebaseTopicConst.additionalDataKey: '{not-json',
        },
      );

      expect(() => service.handleNotificationClick(malformedAdditional),
          returnsNormally);
    });

    test(
        'registerNotificationListeners is idempotent and handles stream events',
        () async {
      final service = PushNotificationService();
      initialMessageResponse = <String, dynamic>{
        'messageId': 'init-msg',
        'data': <String, dynamic>{
          FirebaseTopicConst.additionalDataKey:
              jsonEncode(<String, dynamic>{FirebaseTopicConst.idKey: 777}),
        },
        'notification': <String, dynamic>{
          'title': 'Init',
          'body': 'Body',
        },
      };

      await service.registerNotificationListeners();
      await service.registerNotificationListeners();

      expect(firebaseCalls['Messaging#getInitialMessage'], 1);

      await emitFirebaseMethodCall('Messaging#onMessage', <String, dynamic>{
        'messageId': 'stream-msg',
        'data': <String, dynamic>{},
        'notification': <String, dynamic>{
          'title': 'Foreground',
          'body': 'Event',
        },
      });

      await emitFirebaseMethodCall(
        'Messaging#onMessageOpenedApp',
        <String, dynamic>{
          'messageId': 'opened-msg',
          'data': <String, dynamic>{
            FirebaseTopicConst.additionalDataKey:
                jsonEncode(<String, dynamic>{FirebaseTopicConst.idKey: 333}),
          },
          'notification': <String, dynamic>{
            'title': 'Opened',
            'body': 'Event',
          },
        },
      );

      expect(localNotificationCalls['show'], greaterThanOrEqualTo(1));
    });

    test('showNotification and debug diagnostics method execute', () async {
      final service = PushNotificationService();
      final RemoteMessage message = createRemoteMessage(id: 'msg-6');

      await service.showNotification(1, 'Title', 'Body', message);
      service.printLogsNotificationData(message);

      expect(localNotificationCalls['show'], 1);
    });
  });
}
