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
import 'package:kivicare_patient/screens/auth/model/login_response.dart';
import 'package:kivicare_patient/screens/auth/model/app_configuration_res.dart';
import 'package:kivicare_patient/screens/auth/sign_in_sign_up/sign_in_controller.dart';
import 'package:kivicare_patient/screens/dashboard/dashboard_controller.dart';
import 'package:kivicare_patient/screens/home/home_controller.dart';
import 'package:kivicare_patient/utils/api_end_points.dart';
import 'package:kivicare_patient/utils/app_common.dart';
import 'package:kivicare_patient/utils/constants.dart';
import 'package:kivicare_patient/utils/local_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel pathProviderChannel =
      MethodChannel('plugins.flutter.io/path_provider');
  const MethodChannel connectivityChannel =
      MethodChannel('dev.fluttercommunity.plus/connectivity');
  const MethodChannel firebaseMessagingChannel =
      MethodChannel('plugins.flutter.io/firebase_messaging');
  const MethodChannel googleSignInChannel =
      MethodChannel('plugins.flutter.io/google_sign_in');
  const MethodChannel appleSignInChannel = MethodChannel('the_apple_sign_in');
  const MethodChannel flutterToastChannel =
      MethodChannel('PonnamKarthik/fluttertoast');

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
          statusCode: 400,
          reasonPhrase: 'Bad Request',
          body: jsonEncode(
            <String, dynamic>{'status': false, 'message': 'route not found'},
          ),
        ),
      ),
    );
  }

  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
    HttpOverrides.global = _AlwaysSuccessHttpOverrides();

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
      if (methodCall.method == 'Messaging#subscribeToTopic' ||
          methodCall.method == 'Messaging#unsubscribeFromTopic' ||
          methodCall.method ==
              'Messaging#setForegroundNotificationPresentationOptions') {
        return <String, dynamic>{};
      }
      if (methodCall.method == 'Messaging#getToken') {
        return <String, dynamic>{'token': 'token'};
      }
      if (methodCall.method == 'Messaging#requestPermission') {
        return <String, int>{'authorizationStatus': 1};
      }
      if (methodCall.method == 'Messaging#getInitialMessage') {
        return null;
      }
      return <String, dynamic>{};
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(googleSignInChannel,
            (MethodCall methodCall) async {
      if (methodCall.method == 'init') return <String, dynamic>{};
      if (methodCall.method == 'signIn') return null;
      if (methodCall.method == 'signOut') return <String, dynamic>{};
      return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(appleSignInChannel,
            (MethodCall methodCall) async {
      if (methodCall.method == 'isAvailable') return false;
      return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(flutterToastChannel,
            (MethodCall methodCall) async {
      if (methodCall.method == 'showToast' || methodCall.method == 'cancel') {
        return true;
      }
      return null;
    });

    await GetStorage.init('test-sign-in-controller-release');
    localStorage = GetStorage('test-sign-in-controller-release');
  });

  tearDownAll(() {
    HttpOverrides.global = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(firebaseMessagingChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(googleSignInChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(appleSignInChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(flutterToastChannel, null);
  });

  setUp(() async {
    Get.reset();
    Get.testMode = true;
    await localStorage.erase();
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    isLoggedIn(false);
    selectedLanguageCode('en');
    loginUserData(UserData());
    appConfigs(
      ConfigurationResponse(
        patientAppUrl: PatientAppUrl(),
        clinicadminAppUrl: ClinicadminAppUrl(),
        currency: Currency(),
      ),
    );
    appConfigs.value.isDummyCredential = 0;

    Get.put<DashboardController>(_NoopDashboardController());
  });

  group('Release: lib/screens/auth/sign_in_sign_up/sign_in_controller.dart',
      () {
    test('onInit applies dummy credentials when enabled', () {
      appConfigs.value.isDummyCredential = 1;

      final controller = SignInController();
      controller.onInit();

      expect(controller.emailCont.text, Constants.DEFAULT_EMAIL);
      expect(controller.passwordCont.text, Constants.DEFAULT_PASS);
      controller.onClose();
    });

    test('onInit, toggle and formattedTime follow stored prefs', () {
      setValueToLocal(SharedPreferenceConst.IS_REMEMBER_ME, true);
      setValueToLocal(SharedPreferenceConst.USER_EMAIL, 'remember@x.com');
      setValueToLocal(SharedPreferenceConst.USER_NAME, 'Remembered');

      final controller = SignInController();
      controller.onInit();

      expect(controller.emailCont.text, 'remember@x.com');
      expect(controller.userName.value, 'Remembered');
      expect(controller.isRememberMe.value, isFalse);

      controller.toggleSwitch();
      expect(controller.isRememberMe.value, isTrue);

      controller.remainingSeconds.value = 61;
      expect(controller.formattedTime, '01:01');

      controller.onClose();
    });

    test('saveForm calls login and starts timer', () async {
      final controller = _TestSignInController();
      controller.onInit();

      await controller.saveForm();

      expect(controller.callLoginApiCalled, isTrue);
      expect(controller.remainingSeconds.value, 600);
      controller.onClose();
    });

    test('callLoginApi success path persists login and remember-me values',
        () async {
      final controller = SignInController();
      controller.onInit();
      controller.isNavigateToDashboard(true);
      controller.isRememberMe(true);
      controller.userName('remembered-name');
      controller.emailCont.text = Constants.DEFAULT_EMAIL;
      controller.passwordCont.text = Constants.DEFAULT_PASS;

      await runWithStubResponses(
        action: () => controller.callLoginApi(),
        payloads: <String, Object?>{
          APIEndPoints.login: <String, Object?>{
            'status': true,
            'message': 'ok',
            'data': <String, Object?>{
              'id': 50,
              'user_name': 'john',
              'email': 'john@example.com',
              'api_token': 'token-50',
              'user_role': <String>[LoginTypeConst.LOGIN_TYPE_USER],
            },
          },
        },
      );

      expect(controller.loginSucessfull.value, isTrue);
      expect(isLoggedIn.value, isTrue);
      expect(
        getValueFromLocal(SharedPreferenceConst.USER_EMAIL),
        Constants.DEFAULT_EMAIL,
      );
      expect(
        getValueFromLocal(SharedPreferenceConst.USER_NAME),
        'remembered-name',
      );
      expect(controller.otpCont.text, Constants.DEFAULT_PASS);

      controller.onClose();
    });

    test('callLoginApi catch branch stops loading', () async {
      final controller = SignInController();
      controller.onInit();
      controller.isLoading(true);
      controller.emailCont.text = 'error@example.com';
      controller.passwordCont.text = 'bad';

      await runWithStubResponses(
        action: () => controller.callLoginApi(),
        payloads: <String, Object?>{
          APIEndPoints.login: <String, Object?>{
            'status': false,
            'message': 'bad'
          },
        },
      );

      expect(controller.isLoading.value, isFalse);
      controller.onClose();
    });

    test('callLoginApi handles non-success response status branch', () async {
      final controller = _ControlledSignInController();
      controller.onInit();
      controller.isLoading(true);
      controller.emailCont.text = 'status-false@example.com';
      controller.passwordCont.text = 'secret';
      controller.loginResponseOverride = UserResponse(
        status: false,
        message: 'not allowed',
        userData: UserData(),
      );

      await controller.callLoginApi();

      expect(controller.isLoading.value, isFalse);
      controller.onClose();
    });

    test('callLoginApi clears remembered credentials when remember-me is false',
        () async {
      final controller = _ControlledSignInController();
      controller.onInit();
      controller.isRememberMe(false);
      controller.loginResponseOverride = UserResponse(
        status: true,
        message: 'ok',
        userData: UserData(
          id: 19,
          userName: 'u19',
          email: 'u19@example.com',
          apiToken: 't19',
          userRole: <String>[LoginTypeConst.LOGIN_TYPE_USER],
        ),
      );

      await controller.callLoginApi();

      expect(getValueFromLocal(SharedPreferenceConst.USER_EMAIL), '');
      expect(getValueFromLocal(SharedPreferenceConst.USER_NAME), '');
      controller.onClose();
    });

    test('verifyUser success updates navigation flag and login state',
        () async {
      final controller = SignInController();
      controller.onInit();
      controller.isNavigateToDashboard(false);
      controller.otpCont.text = '1234';
      setValueToLocal(SharedPreferenceConst.USER_ID, 70);

      await runWithStubResponses(
        action: () => controller.verifyUser(authentication: 'app'),
        payloads: <String, Object?>{
          APIEndPoints.verify: <String, Object?>{
            'status': true,
            'message': 'ok',
            'data': <String, Object?>{
              'id': 70,
              'user_name': 'verify-user',
              'email': 'verify@example.com',
              'api_token': 'token-70',
              'user_role': <String>[LoginTypeConst.LOGIN_TYPE_USER],
            },
          },
        },
      );

      expect(controller.isNavigateToDashboard.value, isTrue);
      expect(isLoggedIn.value, isTrue);

      controller.onClose();
    });

    test('verifyUser catch branch stops loading', () async {
      final controller = SignInController();
      controller.onInit();
      controller.isLoading(true);
      setValueToLocal(SharedPreferenceConst.USER_ID, 90);

      await runWithStubResponses(
        action: () => controller.verifyUser(authentication: 'app'),
        payloads: <String, Object?>{
          APIEndPoints.verify: <String, Object?>{
            'status': false,
            'message': 'bad'
          },
        },
      );

      expect(controller.isLoading.value, isFalse);
      controller.onClose();
    });

    test('handleLoginResponse non-user path executes toast branch', () async {
      final controller = SignInController();
      controller.onInit();
      controller.isLoading(true);

      await controller.handleLoginResponse(
        loginResponse: UserResponse(
          status: true,
          message: '',
          userData: UserData(
            userRole: <String>['admin'],
          ),
        ),
        isVerifyOTP: true,
      );

      expect(controller.isLoading.value, isFalse);
      controller.onClose();
    });

    test('handleLoginResponse non-navigate path handles missing controllers',
        () async {
      final controller = SignInController();
      controller.onInit();
      controller.isNavigateToDashboard(false);
      controller.isRememberMe(false);

      if (Get.isRegistered<DashboardController>()) {
        Get.delete<DashboardController>();
      }
      if (Get.isRegistered<HomeController>()) {
        Get.delete<HomeController>();
      }

      await controller.handleLoginResponse(
        loginResponse: UserResponse(
          status: true,
          message: 'ok',
          userData: UserData(
            id: 10,
            userName: 'user-10',
            email: 'u10@example.com',
            apiToken: 'tok-10',
            userRole: <String>[LoginTypeConst.LOGIN_TYPE_USER],
          ),
        ),
      );

      expect(isLoggedIn.value, isTrue);

      controller.onClose();
    });

    test('social sign-in methods execute catch branch safely', () async {
      final controller = SignInController();
      controller.onInit();

      await controller.googleSignIn();
      expect(controller.isLoading.value, isFalse);

      await controller.appleSignIn();
      expect(controller.isLoading.value, isFalse);

      controller.onClose();
    });

    test(
        'googleSignIn success path executes request-build and login-error catch',
        () async {
      final controller = _ControlledSignInController();
      controller.onInit();
      controller.googleUserOverride = UserData(
        firstName: 'A',
        lastName: 'B',
        userName: 'AB',
        email: 'ab@example.com',
        profileImage: 'img',
      );
      controller.loginErrorOverride = 'social-login-failed';

      await controller.googleSignIn();

      expect(controller.isLoading.value, isFalse);
      controller.onClose();
    });

    test('googleSignIn success path executes social login success branch',
        () async {
      final controller = _ControlledSignInController();
      controller.onInit();
      controller.googleUserOverride = UserData(
        firstName: 'G',
        lastName: 'S',
        userName: 'GS',
        email: 'gs@example.com',
        profileImage: 'img',
      );
      controller.loginResponseOverride = UserResponse(
        status: true,
        message: 'ok',
        userData: UserData(
          id: 51,
          userName: 'gs-user',
          email: 'gs@example.com',
          apiToken: 'gs-token',
          userRole: <String>[LoginTypeConst.LOGIN_TYPE_USER],
        ),
      );

      await controller.googleSignIn();

      expect(isLoggedIn.value, isTrue);
      controller.onClose();
    });

    test(
        'appleSignIn success path executes request-build and login-error catch',
        () async {
      final controller = _ControlledSignInController();
      controller.onInit();
      controller.appleUserOverride = UserData(
        firstName: 'A',
        lastName: 'P',
        userName: 'AP',
        email: 'ap@example.com',
        profileImage: 'img',
      );
      controller.loginErrorOverride = 'apple-login-failed';

      await controller.appleSignIn();

      expect(controller.isLoading.value, isFalse);
      controller.onClose();
    });

    test('appleSignIn success branch marks login successful flag', () async {
      final controller = _ControlledSignInController();
      controller.onInit();
      controller.appleUserOverride = UserData(
        firstName: 'A',
        lastName: 'S',
        userName: 'AS',
        email: 'as@example.com',
        profileImage: 'img',
      );
      controller.loginResponseOverride = UserResponse(
        status: true,
        message: 'ok',
        userData: UserData(
          id: 77,
          userName: 'apple-user',
          email: 'apple@example.com',
          apiToken: 'apple-token',
          userRole: <String>[LoginTypeConst.LOGIN_TYPE_USER],
        ),
      );

      await controller.appleSignIn();

      expect(
        getValueFromLocal(SharedPreferenceConst.LOGIN_SUCCESSFULL),
        isTrue,
      );
      controller.onClose();
    });

    test('handleLoginResponse uses found controllers when available', () async {
      Get.put<DashboardController>(_NoopDashboardController());
      Get.put<HomeController>(_NoopHomeController());

      final controller = SignInController();
      controller.onInit();
      controller.isNavigateToDashboard(false);

      await controller.handleLoginResponse(
        loginResponse: UserResponse(
          status: true,
          message: 'ok',
          userData: UserData(
            id: 110,
            userName: 'h-user',
            email: 'h@example.com',
            apiToken: 'h-token',
            userRole: <String>[LoginTypeConst.LOGIN_TYPE_USER],
          ),
        ),
      );

      expect(isLoggedIn.value, isTrue);
      controller.onClose();
    });

    test('non-user branch resolves otpSentToEmail fallback text path',
        () async {
      final controller = SignInController();
      controller.onInit();
      controller.isLoading(true);

      await controller.handleLoginResponse(
        loginResponse: UserResponse(
          status: true,
          message: '',
          userData: UserData(userRole: <String>['admin']),
        ),
        isVerifyOTP: false,
      );

      expect(controller.isLoading.value, isFalse);
      controller.onClose();
    });

    test('timer APIs decrement and reset values', () async {
      final controller = SignInController();
      controller.onInit();

      controller.startTimer();
      controller.remainingSeconds.value = 1;
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      expect(controller.remainingSeconds.value, 0);

      controller.resetTimer();
      expect(controller.remainingSeconds.value, 60);

      controller.onClose();
    });
  });
}

class _NoopDashboardController extends DashboardController {
  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {}

  @override
  void reloadBottomTabs() {}
}

class _NoopHomeController extends HomeController {
  @override
  Future<void> init() async {}
}

class _TestSignInController extends SignInController {
  bool callLoginApiCalled = false;

  @override
  Future<void> callLoginApi() async {
    callLoginApiCalled = true;
  }
}

class _ControlledSignInController extends SignInController {
  UserResponse? loginResponseOverride;
  Object? loginErrorOverride;

  UserResponse? verifyResponseOverride;
  Object? verifyErrorOverride;

  UserData? googleUserOverride;
  Object? googleErrorOverride;

  UserData? appleUserOverride;
  Object? appleErrorOverride;

  @override
  Future<UserResponse> loginUserRequest({
    required Map<String, dynamic> request,
    bool isSocialLogin = false,
  }) async {
    if (loginErrorOverride != null) throw loginErrorOverride!;
    return loginResponseOverride ??
        UserResponse(
          status: true,
          userData: UserData(
            id: 1,
            userName: 'default',
            email: 'default@example.com',
            apiToken: 'token',
            userRole: <String>[LoginTypeConst.LOGIN_TYPE_USER],
          ),
          message: 'ok',
        );
  }

  @override
  Future<UserResponse> verifyUserRequest(
      {required Map<String, dynamic> request}) async {
    if (verifyErrorOverride != null) throw verifyErrorOverride!;
    return verifyResponseOverride ??
        UserResponse(
          status: true,
          userData: UserData(
            id: 2,
            userName: 'verify',
            email: 'verify@example.com',
            apiToken: 'verify-token',
            userRole: <String>[LoginTypeConst.LOGIN_TYPE_USER],
          ),
          message: 'ok',
        );
  }

  @override
  Future<UserData> socialGoogleSignInRequest() async {
    if (googleErrorOverride != null) throw googleErrorOverride!;
    return googleUserOverride ?? UserData(userName: 'google-user');
  }

  @override
  Future<UserData> socialAppleSignInRequest() async {
    if (appleErrorOverride != null) throw appleErrorOverride!;
    return appleUserOverride ?? UserData(userName: 'apple-user');
  }
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

class _AlwaysSuccessHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _StubHttpClient(
      routes: <String, _StubHttpReply>{},
      fallback: _StubHttpReply(
        statusCode: 200,
        body: jsonEncode(
          <String, dynamic>{'status': true, 'data': <String, dynamic>{}},
        ),
      ),
    );
  }
}
