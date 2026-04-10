import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:kivicare_patient/api/auth_apis.dart';
import 'package:kivicare_patient/screens/auth/model/login_response.dart';
import 'package:kivicare_patient/screens/auth/model/notification_model.dart';
import 'package:kivicare_patient/screens/auth/model/patient_wallet_history_res.dart';
import 'package:kivicare_patient/utils/app_common.dart';
import 'package:kivicare_patient/utils/constants.dart';
import 'package:kivicare_patient/utils/local_storage.dart';
import 'package:kivicare_patient/utils/secure_storage.dart';

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

  Future<File> createTempFile(String name, {String content = 'x'}) async {
    final Directory dir =
        await Directory.systemTemp.createTemp('auth_api_release_');
    final File file = File('${dir.path}/$name');
    await file.writeAsString(content);
    return file;
  }

  Future<T> runWithStubResponses<T>({
    required Future<T> Function() action,
    required Map<String, Object?> payloads,
  }) {
    final Map<String, _StubHttpReply> routes = payloads.map(
      (String pattern, Object? payload) => MapEntry(
        pattern,
        _StubHttpReply(body: jsonEncode(payload)),
      ),
    );

    return HttpOverrides.runZoned(
      action,
      createHttpClient: (SecurityContext? context) => _StubHttpClient(
        routes: routes,
        fallback: _StubHttpReply(
          statusCode: 404,
          reasonPhrase: 'Not Found',
          body: jsonEncode(
            <String, dynamic>{'status': false, 'message': 'route not found'},
          ),
        ),
      ),
    );
  }

  const FlutterSecureStorage secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
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

    await GetStorage.init('test-auth-apis-release');
    localStorage = GetStorage('test-auth-apis-release');
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
  });

  setUp(() async {
    await localStorage.erase();
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    isLoggedIn(false);
    selectedLanguageCode('en');
    loginUserData(UserData());
  });

  group('Release: lib/api/auth_apis.dart', () {
    test('clearData from delete account clears full local state', () async {
      isLoggedIn(true);
      loginUserData(UserData(
        id: 11,
        email: 'user@a.com',
        userName: 'u11',
        apiToken: 'tok-11',
      ));
      setValueToLocal(SharedPreferenceConst.USER_EMAIL, 'persist-me');
      setValueToLocal(SharedPreferenceConst.IS_REMEMBER_ME, true);
      setValueToLocal(SharedPreferenceConst.SESSION_LAST_ACTIVITY_AT,
          DateTime.now().millisecondsSinceEpoch);
      await saveUserDataSecure(UserData(id: 11, apiToken: 'tok-11'));

      await AuthServiceApis.clearData(isFromDeleteAcc: true);

      expect(isLoggedIn.value, isFalse);
      expect(loginUserData.value.id, -1);
      expect(getValueFromLocal(SharedPreferenceConst.USER_EMAIL), isNull);
      expect(
        getValueFromLocal(SharedPreferenceConst.SESSION_LAST_ACTIVITY_AT),
        isNull,
      );
      expect(await secure.read(key: SecureStorageKeys.userData), isNull);
    });

    test('clearData normal branch preserves remember me/email/username',
        () async {
      isLoggedIn(true);
      loginUserData(UserData(
        id: 12,
        email: 'remember@a.com',
        userName: 'remember-user',
        apiToken: 'tok-12',
      ));
      setValueToLocal(SharedPreferenceConst.IS_REMEMBER_ME, true);
      setValueToLocal(
        SharedPreferenceConst.SESSION_LAST_ACTIVITY_AT,
        DateTime.now().millisecondsSinceEpoch,
      );
      await saveUserDataSecure(UserData(id: 12, apiToken: 'tok-12'));

      await AuthServiceApis.clearData();

      expect(isLoggedIn.value, isFalse);
      expect(loginUserData.value.id, -1);
      expect(getValueFromLocal(SharedPreferenceConst.FIRST_TIME), isTrue);
      expect(
        getValueFromLocal(SharedPreferenceConst.USER_EMAIL),
        'remember@a.com',
      );
      expect(
        getValueFromLocal(SharedPreferenceConst.USER_NAME),
        'remember-user',
      );
      expect(getValueFromLocal(SharedPreferenceConst.USER_ID), '0');
      expect(
          getValueFromLocal(SharedPreferenceConst.LOGIN_SUCCESSFULL), isFalse);
      expect(getValueFromLocal(SharedPreferenceConst.IS_REMEMBER_ME), isTrue);
      expect(
        getValueFromLocal(SharedPreferenceConst.SESSION_LAST_ACTIVITY_AT),
        isNull,
      );
      expect(await secure.read(key: SecureStorageKeys.userData), isNull);
    });

    test('logged out notification detail returns empty list', () async {
      final res = await AuthServiceApis.getNotificationDetail(
        notifications: <NotificationData>[],
      );
      expect(res, isEmpty);
    });

    test('notification detail logged-in path throws on non-success response',
        () async {
      isLoggedIn(true);
      await expectLater(
        () => AuthServiceApis.getNotificationDetail(
          notifications: <NotificationData>[],
        ),
        throwsA(anything),
      );
    });

    test('notification utility apis execute request path', () async {
      isLoggedIn(true);
      await expectLater(
        () => AuthServiceApis.clearAllNotification(),
        throwsA(anything),
      );
      await expectLater(
        () => AuthServiceApis.removeNotification(notificationId: '10'),
        throwsA(anything),
      );
    });

    test('notification detail success path updates list and callbacks',
        () async {
      isLoggedIn(true);

      final existing = <NotificationData>[
        NotificationData(
          data: NotificationModel(
            subject: 'old',
            notificationDetail: NotificationDetail(incidence: Incidence()),
          ),
        ),
      ];
      bool? lastPage;
      int? unreadCount;

      final res = await runWithStubResponses(
        action: () => AuthServiceApis.getNotificationDetail(
          notifications: existing,
          perPage: 1,
          lastPageCallBack: (bool value) => lastPage = value,
          allUnreadNotification: (int value) => unreadCount = value,
        ),
        payloads: <String, Object?>{
          'notification-list': <String, Object?>{
            'status': true,
            'message': 'ok',
            'all_unread_count': 3,
            'notification_data': <Map<String, Object?>>[
              <String, Object?>{
                'id': 'n-1',
                'type': 'notice',
                'notifiable_type': 'user',
                'notifiable_id': 11,
                'data': <String, Object?>{
                  'subject': 'Created',
                  'data': <String, Object?>{'incidence': <String, Object?>{}},
                },
              },
            ],
          },
        },
      );

      expect(res, hasLength(1));
      expect(res.first.id, 'n-1');
      expect(lastPage, isFalse);
      expect(unreadCount, 3);
    });

    test('notification utility wrappers parse success payloads', () async {
      isLoggedIn(true);

      await runWithStubResponses(
        action: () async {
          final clearRes = await AuthServiceApis.clearAllNotification();
          final removeRes =
              await AuthServiceApis.removeNotification(notificationId: '10');

          expect(clearRes.id, 'all-cleared');
          expect(removeRes.id, '10');
        },
        payloads: <String, Object?>{
          'notification-deleteall': <String, Object?>{
            'status': true,
            'id': 'all-cleared',
            'message': 'ok',
          },
          'notification-remove': <String, Object?>{
            'status': true,
            'id': '10',
            'message': 'ok',
          },
        },
      );
    });

    test('auth create/login/verify/add-phone wrappers execute', () async {
      await expectLater(
        () => AuthServiceApis.createUser(request: {'email': 'a@b.com'}),
        throwsA(anything),
      );
      await expectLater(
        () => AuthServiceApis.loginUser(request: {'email': 'a@b.com'}),
        throwsA(anything),
      );
      await expectLater(
        () => AuthServiceApis.loginUser(
          request: {'email': 'a@b.com'},
          isSocialLogin: true,
        ),
        throwsA(anything),
      );
      await expectLater(
        () => AuthServiceApis.verifyUser(request: {'code': '1234'}),
        throwsA(anything),
      );
      await expectLater(
        () => AuthServiceApis.addUserPhoneNumber(request: {'mobile': '1'}),
        throwsA(anything),
      );
    });

    test('password/logout/delete wrappers execute', () async {
      await expectLater(
        () => AuthServiceApis.changePasswordAPI(request: {'old_password': 'a'}),
        throwsA(anything),
      );
      await expectLater(
        () => AuthServiceApis.forgotPasswordAPI(request: {'email': 'a@b.com'}),
        throwsA(anything),
      );
      await expectLater(() => AuthServiceApis.logoutApi(), throwsA(anything));
      await expectLater(
        () => AuthServiceApis.deleteAccountCompletely(),
        throwsA(anything),
      );
    });

    test('app config and profile wrappers execute', () async {
      isLoggedIn(true);
      setValueToLocal(SharedPreferenceConst.IS_LOGGED_IN, true);
      loginUserData(UserData(id: 99));

      await expectLater(
        () => AuthServiceApis.getAppConfigurations(),
        throwsA(anything),
      );
      await expectLater(
        () => AuthServiceApis.viewProfile(id: 10),
        throwsA(anything),
      );
      await expectLater(
        () => AuthServiceApis.viewProfile(),
        throwsA(anything),
      );
    });

    test('logout/config/profile/wallet/about wrappers parse success', () async {
      isLoggedIn(true);
      loginUserData(UserData(id: 22, apiToken: 'token-22'));
      setValueToLocal(SharedPreferenceConst.IS_LOGGED_IN, true);

      bool? walletLastPage;
      final historySeed = <WalletHistoryElement>[
        WalletHistoryElement(title: 'old'),
      ];

      await runWithStubResponses(
        action: () async {
          final logout = await AuthServiceApis.logoutApi();
          final config = await AuthServiceApis.getAppConfigurations();
          final profile = await AuthServiceApis.viewProfile(id: 10);

          await AuthServiceApis.getUserWallet();

          final history = await AuthServiceApis.getWalletHistory(
            historyData: historySeed,
            page: 1,
            perPage: 1,
            lastPageCallBack: (bool value) => walletLastPage = value,
          );

          final about = await AuthServiceApis.getAboutPageData();

          expect(logout.status, isTrue);
          expect(config.status, isTrue);
          expect(profile.status, isTrue);
          expect(userWalletData.value.walletAmount, 42);
          expect(history, hasLength(1));
          expect(walletLastPage, isFalse);
          expect(about.status, isTrue);
        },
        payloads: <String, Object?>{
          'logout': <String, Object?>{'status': true, 'message': 'bye'},
          'app-configuration': <String, Object?>{
            'status': true,
            'message': 'ok',
            'patient_app_url': <String, Object?>{},
            'clinicadmin_app_url': <String, Object?>{},
            'currency': <String, Object?>{},
          },
          'user-detail': <String, Object?>{
            'status': true,
            'message': 'ok',
            'data': <String, Object?>{'id': 10, 'user_name': 'Patient'},
          },
          'get-patient-wallet': <String, Object?>{
            'status': true,
            'message': 'ok',
            'wallet_amount': 42,
          },
          'get-wallet-history': <String, Object?>{
            'status': true,
            'message': 'ok',
            'data': <Map<String, Object?>>[
              <String, Object?>{
                'title': 'credit',
                'amount': 100,
                'credit_debit_amount': 100,
                'date': '2025-01-01',
                'transaction_type': 'credit',
              },
            ],
          },
          'page-list': <String, Object?>{
            'status': true,
            'message': 'ok',
            'data': <Map<String, Object?>>[
              <String, Object?>{
                'id': 1,
                'slug': 'about-us',
                'name': 'About',
                'url': 'https://example.com/about',
              },
            ],
          },
        },
      );
    });

    test('wallet APIs execute including catch path', () async {
      await AuthServiceApis.getUserWallet();

      await expectLater(
        () => AuthServiceApis.getWalletHistory(
            historyData: <WalletHistoryElement>[]),
        throwsA(anything),
      );
    });

    test('updateProfile logged-out no-op and logged-in error branch', () async {
      await AuthServiceApis.updateProfile(firstName: 'Noop');

      isLoggedIn(true);
      final image = await createTempFile('profile.png', content: 'img');
      await expectLater(
        () => AuthServiceApis.updateProfile(
          firstName: 'A',
          lastName: 'B',
          mobile: '999',
          address: 'Addr',
          gender: 'male',
          email: 'a@b.com',
          dateOfBirth: '1990-01-01',
          imageFile: image,
        ),
        throwsA(anything),
      );
    });

    test('updateProfile success calls onSuccess callback', () async {
      isLoggedIn(true);
      loginUserData(UserData(id: 33, apiToken: 'token-33'));

      dynamic callbackData;
      await runWithStubResponses(
        action: () => AuthServiceApis.updateProfile(
          firstName: 'A',
          onSuccess: (dynamic data) {
            callbackData = data;
          },
        ),
        payloads: <String, Object?>{
          'update-profile': <String, Object?>{
            'status': true,
            'message': 'updated',
          },
        },
      );

      expect(callbackData, contains('"status":true'));
    });

    test('about page wrapper executes request path', () async {
      await expectLater(
        () => AuthServiceApis.getAboutPageData(),
        throwsA(anything),
      );
    });
  });
}

class _StubHttpReply {
  final int statusCode;
  final String body;
  final String reasonPhrase;

  const _StubHttpReply({
    required this.body,
    this.statusCode = 200,
    this.reasonPhrase = 'OK',
  });
}

class _StubHttpClient implements HttpClient {
  final Map<String, _StubHttpReply> routes;
  final _StubHttpReply fallback;

  _StubHttpClient({required this.routes, required this.fallback});

  _StubHttpReply _resolve(Uri url) {
    final String raw = url.toString();
    for (final MapEntry<String, _StubHttpReply> entry in routes.entries) {
      if (raw.contains(entry.key)) return entry.value;
    }
    return fallback;
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _StubHttpClientRequest(
      reply: _resolve(url),
      method: method,
      uri: url,
    );
  }

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubHttpClientRequest implements HttpClientRequest {
  final _StubHttpReply reply;

  @override
  final String method;

  @override
  final Uri uri;

  final _StubHttpHeaders _headers = _StubHttpHeaders();
  final List<int> _buffer = <int>[];
  final Completer<HttpClientResponse> _doneCompleter =
      Completer<HttpClientResponse>();
  Encoding _encoding = utf8;

  _StubHttpClientRequest({
    required this.reply,
    required this.method,
    required this.uri,
  });

  @override
  bool bufferOutput = false;

  @override
  int contentLength = -1;

  @override
  List<Cookie> cookies = <Cookie>[];

  @override
  Encoding get encoding => _encoding;

  @override
  set encoding(Encoding value) {
    _encoding = value;
  }

  @override
  bool followRedirects = true;

  @override
  HttpHeaders get headers => _headers;

  @override
  int maxRedirects = 5;

  @override
  bool persistentConnection = true;

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}

  @override
  void add(List<int> data) {
    _buffer.addAll(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final List<int> chunk in stream) {
      _buffer.addAll(chunk);
    }
  }

  @override
  Future<HttpClientResponse> close() async {
    final response = _StubHttpClientResponse(reply: reply);
    if (!_doneCompleter.isCompleted) {
      _doneCompleter.complete(response);
    }
    return response;
  }

  @override
  Future<HttpClientResponse> get done => _doneCompleter.future;

  void destroy([Object? error]) {}

  @override
  Future<void> flush() async {}

  @override
  void write(Object? obj) {
    if (obj != null) {
      _buffer.addAll(_encoding.encode(obj.toString()));
    }
  }

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) {
    write(objects.join(separator));
  }

  @override
  void writeCharCode(int charCode) {
    _buffer.add(charCode);
  }

  @override
  void writeln([Object? obj = '']) {
    write(obj);
    write('\n');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  final _StubHttpReply reply;
  final List<int> _bytes;
  final _StubHttpHeaders _headers = _StubHttpHeaders();

  _StubHttpClientResponse({required this.reply})
      : _bytes = utf8.encode(reply.body) {
    _headers.set(HttpHeaders.contentTypeHeader, 'application/json');
  }

  @override
  X509Certificate? get certificate => null;

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  int get contentLength => _bytes.length;

  @override
  HttpHeaders get headers => _headers;

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  List<RedirectInfo> get redirects => const <RedirectInfo>[];

  @override
  String get reasonPhrase => reply.reasonPhrase;

  @override
  int get statusCode => reply.statusCode;

  @override
  Future<Socket> detachSocket() async {
    throw UnimplementedError();
  }

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable(<List<int>>[_bytes]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _store = <String, List<String>>{};

  String _normalize(String name) => name.toLowerCase();

  @override
  List<String>? operator [](String name) => _store[_normalize(name)];

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    final String key = _normalize(name);
    (_store[key] ??= <String>[]).add(value.toString());
  }

  @override
  void clear() {
    _store.clear();
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _store.forEach((String key, List<String> values) {
      action(key, List<String>.from(values));
    });
  }

  @override
  void noFolding(String name) {}

  @override
  void remove(String name, Object value) {
    final String key = _normalize(name);
    _store[key]?.remove(value.toString());
    if (_store[key]?.isEmpty ?? false) {
      _store.remove(key);
    }
  }

  @override
  void removeAll(String name) {
    _store.remove(_normalize(name));
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _store[_normalize(name)] = <String>[value.toString()];
  }

  @override
  String? value(String name) {
    final List<String>? values = _store[_normalize(name)];
    if (values == null || values.isEmpty) return null;
    return values.join(',');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
