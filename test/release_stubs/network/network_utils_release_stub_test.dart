import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:kivicare_patient/main.dart';
import 'package:kivicare_patient/network/network_utils.dart';
import 'package:kivicare_patient/screens/auth/model/login_response.dart';
import 'package:kivicare_patient/utils/api_end_points.dart';
import 'package:kivicare_patient/utils/app_common.dart';
import 'package:kivicare_patient/utils/constants.dart';
import 'package:kivicare_patient/utils/local_storage.dart';
import 'package:nb_utils/nb_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel pathProviderChannel =
      MethodChannel('plugins.flutter.io/path_provider');
  const MethodChannel connectivityChannel =
      MethodChannel('dev.fluttercommunity.plus/connectivity');
    const MethodChannel googleSignInChannel =
      MethodChannel('plugins.flutter.io/google_sign_in');
    const MethodChannel firebaseMessagingChannel =
      MethodChannel('plugins.flutter.io/firebase_messaging');
      const MethodChannel flutterToastChannel =
        MethodChannel('PonnamKarthik/fluttertoast');

  Future<File> createTempFile(String name, {String content = 'tmp'}) async {
    final Directory dir = await Directory.systemTemp.createTemp('nu_release_');
    final File file = File('${dir.path}/$name');
    await file.writeAsString(content);
    return file;
  }

  setUpAll(() async {
    setupFirebaseCoreMocks();
    Get.testMode = true;

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
        .setMockMethodCallHandler(googleSignInChannel,
            (MethodCall methodCall) async {
      if (methodCall.method == 'signOut') {
        return <String, dynamic>{};
      }
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(firebaseMessagingChannel,
            (MethodCall methodCall) async {
      if (methodCall.method == 'Messaging#unsubscribeFromTopic' ||
          methodCall.method == 'Messaging#subscribeToTopic' ||
          methodCall.method == 'Messaging#getToken') {
        return <String, dynamic>{};
      }
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(flutterToastChannel,
            (MethodCall methodCall) async {
      if (methodCall.method == 'showToast' ||
          methodCall.method == 'cancel') {
        return true;
      }
      return null;
    });

    await GetStorage.init('test-network-utils-release');
    localStorage = GetStorage('test-network-utils-release');
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(connectivityChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(googleSignInChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(firebaseMessagingChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(flutterToastChannel, null);
  });

  setUp(() async {
    await localStorage.erase();
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    isLoggedIn(false);
    selectedLanguageCode('en');
    loginUserData(UserData(apiToken: 'session-token'));
  });

  group('Release: lib/network/network_utils.dart', () {
    test('buildBaseUrl resolves internal and external endpoints', () {
      expect(buildBaseUrl('/patients').toString(), contains('/patients'));

      const external = 'http://127.0.0.1:9999/ok';
      expect(buildBaseUrl(external).toString(), external);
    });

    test('buildHeaderTokens includes auth only when logged in', () {
      isLoggedIn(true);
      loginUserData(UserData(apiToken: 'abc-token'));

      final loggedInHeader = buildHeaderTokens();
      expect(loggedInHeader.containsKey(HttpHeaders.authorizationHeader),
          isTrue);
      expect(loggedInHeader[HttpHeaders.authorizationHeader],
          'Bearer abc-token');

      isLoggedIn(false);
      final loggedOutHeader = buildHeaderTokens();
      expect(loggedOutHeader.containsKey(HttpHeaders.authorizationHeader),
          isFalse);
    });

    test('buildHeaderTokens supports register, flutterWave and airtel', () {
      isLoggedIn(true);

      final registerHeader = buildHeaderTokens(endPoint: APIEndPoints.register);
      expect(registerHeader[HttpHeaders.acceptHeader], 'application/json');

      final flutterWave = buildHeaderTokens(extraKeys: {
        'isFlutterWave': true,
        'flutterWaveSecretKey': 'sk_test_123',
      });
      expect(flutterWave[HttpHeaders.authorizationHeader],
          'Bearer sk_test_123');

      final airtel = buildHeaderTokens(extraKeys: {
        'isAirtelMoney': true,
        'access_token': 'airtel-token',
        'X-Country': 'IN',
        'X-Currency': 'INR',
      });
      expect(airtel[HttpHeaders.authorizationHeader], 'Bearer airtel-token');
      expect(airtel['X-Country'], 'IN');
      expect(airtel['X-Currency'], 'INR');
    });

    test('parse stripe error message successfully', () {
      final message = parseStripeError(
          '{"error": {"message": "<b>Card failed</b>"}}');
      expect(message, 'Card failed');
    });

    test('throw fallback on invalid stripe error response', () {
      expect(
        () => parseStripeError('{"error": 12}'),
        throwsA(anything),
      );
    });

    test('parseStripeError malformed JSON enters catch fallback', () {
      expect(
        () => parseStripeError('{'),
        throwsA(anything),
      );
    });

    test('skip session logout for external non-success response', () async {
      isLoggedIn(true);
      final response =
          await buildHttpResponse('http://example.com/external-error');

      // In widget tests, HttpClient requests are mocked to return 400.
      expect(response.statusCode, 400);
      expect(isLoggedIn.value, isTrue);
    });

    test('do not stamp activity for external response', () async {
      isLoggedIn(true);
      await buildHttpResponse('http://example.com/external-any');

      expect(
        getValueFromLocal(SharedPreferenceConst.SESSION_LAST_ACTIVITY_AT),
        isNull,
      );
    });

    test('request method branches execute for POST PUT and DELETE', () async {
      final post = await buildHttpResponse(
        'http://example.com/post',
        method: HttpMethodType.POST,
        request: {'a': 1},
      );
      final put = await buildHttpResponse(
        'http://example.com/put',
        method: HttpMethodType.PUT,
        request: {'b': 2},
      );
      final del = await buildHttpResponse(
        'http://example.com/delete',
        method: HttpMethodType.DELETE,
      );

      expect(post.statusCode, 400);
      expect(put.statusCode, 400);
      expect(del.statusCode, 400);
    });

    test('request retry catches socket and timeout exceptions', () async {
      await HttpOverrides.runZoned(
        () async {
          await expectLater(
            () => buildHttpResponse('http://example.com/socket-fail'),
            throwsA(errorInternetNotAvailable),
          );
        },
        createHttpClient: (SecurityContext? context) {
          throw const SocketException('forced socket');
        },
      );

      await HttpOverrides.runZoned(
        () async {
          await expectLater(
            () => buildHttpResponse('http://example.com/timeout-fail'),
            throwsA(errorInternetNotAvailable),
          );
        },
        createHttpClient: (SecurityContext? context) {
          throw TimeoutException('forced timeout');
        },
      );
    });

    test('handleResponse success payload with status true returns body',
        () async {
      final result = await handleResponse(
        http.Response('{"status": true, "message": "ok"}', 200),
      );
      expect(result['status'], true);
    });

    test('handleResponse success payload without status returns body',
        () async {
      final result = await handleResponse(
        http.Response('{"data": {"id": 1}}', 200),
      );
      expect(result['data']['id'], 1);
    });

    test('handleResponse flutterWave success branch returns body', () async {
      final result = await handleResponse(
        http.Response('{"status": "success", "message": "ok"}', 200),
        isFlutterWave: true,
      );
      expect(result['status'], 'success');
    });

    test('handleResponse flutterWave failure throws message', () async {
      await expectLater(
        () => handleResponse(
          http.Response('{"status": "failed", "message": "denied"}', 200),
          isFlutterWave: true,
        ),
        throwsA('denied'),
      );
    });

    test('handleResponse status false throws message', () async {
      await expectLater(
        () => handleResponse(
          http.Response('{"status": false, "message": "bad"}', 200),
        ),
        throwsA('bad'),
      );
    });

    test('handleResponse deleted-account branch triggers local logout flow',
        () async {
      await runZonedGuarded(() async {
        isLoggedIn(true);

        final result = await handleResponse(
          http.Response(
            '{"status": false, "is_deleted": true, "message": "deleted"}',
            200,
          ),
        );

        expect(result, isNull);
        expect(isLoggedIn.value, isFalse);

        // Allow fire-and-forget side effects to settle in this guarded zone.
        await Future<void>.delayed(Duration.zero);
      }, (Object error, StackTrace stackTrace) {
        // Ignore async side-effects from non-awaited logout helpers in this path.
      });
    });

    test('handleResponse non-json success throws fallback', () async {
      await expectLater(
        () => handleResponse(http.Response('not-json', 200)),
        throwsA(anything),
      );
    });

    test('handleResponse maps common HTTP error codes', () async {
      await expectLater(
        () => handleResponse(http.Response('{}', 400)),
        throwsA(locale.value.badRequest),
      );
      await expectLater(
        () => handleResponse(http.Response('{}', 403)),
        throwsA(locale.value.forbidden),
      );
      await expectLater(
        () => handleResponse(http.Response('{}', 404)),
        throwsA(locale.value.pageNotFound),
      );
      await expectLater(
        () => handleResponse(http.Response('{}', 429)),
        throwsA(locale.value.tooManyRequests),
      );
      await expectLater(
        () => handleResponse(http.Response('{}', 500)),
        throwsA(locale.value.internalServerError),
      );
      await expectLater(
        () => handleResponse(http.Response('{}', 502)),
        throwsA(locale.value.badGateway),
      );
      await expectLater(
        () => handleResponse(http.Response('{}', 503)),
        throwsA(locale.value.serviceUnavailable),
      );
      await expectLater(
        () => handleResponse(http.Response('{}', 504)),
        throwsA(locale.value.gatewayTimeout),
      );
    });

    test('handleResponse generic non-success branch parses body', () async {
      final body = await handleResponse(
        http.Response('{"status": true, "data": 1}', 418),
      );
      expect(body['data'], 1);

      await expectLater(
        () => handleResponse(http.Response('{"status": false, "message":"x"}', 418)),
        throwsA('x'),
      );
    });

    test('block request when pre-flight session expired', () async {
      isLoggedIn(true);
      final int stale = DateTime.now()
          .subtract(const Duration(minutes: 31))
          .millisecondsSinceEpoch;
      setValueToLocal(SharedPreferenceConst.SESSION_LAST_ACTIVITY_AT, stale);

      await expectLater(
        () => buildHttpResponse('/internal-expired'),
        throwsA('Session expired. Please sign in again.'),
      );
    });

    test('multipart non-success invokes onError callback', () async {
      dynamic successValue;
      dynamic errorValue;
      final req = await getMultiPartRequest(
        'http://example.com/multipart-error',
        baseUrl: 'http://example.com/multipart-error',
      );
      req.fields['k'] = 'v';

      await sendMultiPartRequest(
        req,
        onSuccess: (val) => successValue = val,
        onError: (val) => errorValue = val,
      );

      expect(successValue, isNull);
      expect(errorValue, isNotNull);
    });

    test('multipart preflight expiry on internal URL triggers session error',
        () async {
      isLoggedIn(true);
      final stale = DateTime.now()
          .subtract(const Duration(minutes: 31))
          .millisecondsSinceEpoch;
      setValueToLocal(SharedPreferenceConst.SESSION_LAST_ACTIVITY_AT, stale);

      final req = await getMultiPartRequest('/internal-multipart');
      dynamic errorValue;
      await sendMultiPartRequest(req, onError: (val) {
        errorValue = val;
      });

      expect(errorValue, 'Session expired. Please sign in again.');
    });

    test('multipart non-401 invokes onError reason phrase', () async {
      final req = await getMultiPartRequest(
        'http://example.com/multipart-500',
        baseUrl: 'http://example.com/multipart-500',
      );
      req.fields['k'] = 'v';

      dynamic callbackValue;
      await sendMultiPartRequest(req, onError: (val) {
        callbackValue = val;
      });

      expect(callbackValue, isNotNull);
    });

    test('build multipart response blocks expired session', () async {
      isLoggedIn(true);
      final int stale = DateTime.now()
          .subtract(const Duration(minutes: 31))
          .millisecondsSinceEpoch;
      setValueToLocal(SharedPreferenceConst.SESSION_LAST_ACTIVITY_AT, stale);

      await expectLater(
        () => buildMultiPartResponse(
          endPoint: '/multipart-expired',
          request: <String, dynamic>{'a': 1},
        ),
        throwsA('Session expired. Please sign in again.'),
      );
    });

    test('buildMultiPartResponse external request hits handler path', () async {
      await expectLater(
        () => buildMultiPartResponse(
          endPoint: 'http://example.com/multipart',
          request: <String, dynamic>{'a': 1, 'b': 'x'},
        ),
        throwsA(locale.value.badRequest),
      );
    });

    test('buildMultiPartResponse file list branches execute', () async {
      final fileA = await createTempFile('a.txt', content: 'a');
      final fileB = await createTempFile('b.txt', content: 'b');

      await expectLater(
        () => buildMultiPartResponse(
          endPoint: 'http://example.com/multipart-files-many',
          request: <String, dynamic>{'a': 1},
          files: [fileA, fileB],
          fileKey: 'docs',
        ),
        throwsA(locale.value.badRequest),
      );

      await expectLater(
        () => buildMultiPartResponse(
          endPoint: 'http://example.com/multipart-files-one',
          request: <String, dynamic>{'a': 1},
          files: [fileA],
          fileKey: 'doc',
          isKeyRequireIndexing: true,
        ),
        throwsA(locale.value.badRequest),
      );

      await expectLater(
        () => buildMultiPartResponse(
          endPoint: 'http://example.com/multipart-files-one-no-index',
          request: <String, dynamic>{'a': 1},
          files: [fileA],
          fileKey: 'doc',
          isKeyRequireIndexing: false,
        ),
        throwsA(locale.value.badRequest),
      );
    });

    test('buildMultiPartResponse invalid endpoint enters exception path',
        () async {
      await expectLater(
        () => buildMultiPartResponse(
          endPoint: 'http://[invalid-host',
          request: <String, dynamic>{'a': 1},
        ),
        throwsA(anything),
      );
    });

    test('buildMultiPartResponse socket exception branch rethrows', () async {
      await HttpOverrides.runZoned(
        () async {
          await expectLater(
            () => buildMultiPartResponse(
              endPoint: 'http://example.com/socket-multipart',
              request: <String, dynamic>{'a': 1},
            ),
            throwsA(anything),
          );
        },
        createHttpClient: (SecurityContext? context) {
          throw const SocketException('forced multipart socket');
        },
      );
    });

    test('getMultipartImages and getMultipartImages2 build file parts',
        () async {
      final fileA = await createTempFile('imgA.png', content: 'a');
      final fileB = await createTempFile('imgB.png', content: 'b');

      final parts1 = await getMultipartImages(
        files: [
          PlatformFile(path: fileA.path, name: 'imgA.png', size: 1),
          PlatformFile(path: fileB.path, name: 'imgB.png', size: 1),
        ],
        name: 'photo',
      );

      final parts2 = await getMultipartImages2(
        files: [XFile(fileA.path), XFile(fileB.path)],
        name: 'xphoto',
      );

      expect(parts1.length, 2);
      expect(parts2.length, 2);
    });

    test('defaultHeaders and getMultipartFields produce expected maps',
        () async {
      final headers = defaultHeaders();
      expect(headers[HttpHeaders.cacheControlHeader], 'no-cache');
      expect(headers['Access-Control-Allow-Origin'], '*');

      final fields = await getMultipartFields(val: <String, dynamic>{
        'intVal': 1,
        'stringVal': 'x',
      });
      expect(fields['intVal'], '1');
      expect(fields['stringVal'], 'x');
    });

    test('apiPrint and formatJson utility branches execute', () {
      apiPrint(
        url: 'http://example.com',
        endPoint: '/endpoint',
        headers: '{"authorization":"Bearer abc"}',
        request: '{"password":"secret"}',
        statusCode: 200,
        responseBody: '{"api_token":"abc"}',
        methodtype: 'GET',
        hasRequest: true,
        fullLog: false,
      );

      apiPrint(
        url: 'http://example.com',
        endPoint: '/endpoint',
        headers: '{"authorization":"Bearer abc"}',
        request: '{"old_password":"1","new_password":"2"}',
        statusCode: 500,
        responseBody: '{"error":true}',
        methodtype: 'POST',
        hasRequest: true,
        fullLog: true,
      );

      expect(formatJson('{"a":1}'), contains('"a": 1'));
      expect(formatJson('not-json'), 'not-json');
    });
  });
}
