import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kivicare_patient/screens/auth/model/login_response.dart';
import 'package:kivicare_patient/screens/auth/password/change_password_controller.dart';
import 'package:kivicare_patient/utils/api_end_points.dart';
import 'package:kivicare_patient/utils/app_common.dart';
import 'package:kivicare_patient/utils/secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel pathProviderChannel =
      MethodChannel('plugins.flutter.io/path_provider');
  const MethodChannel connectivityChannel =
      MethodChannel('dev.fluttercommunity.plus/connectivity');
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

  setUpAll(() {
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
        .setMockMethodCallHandler(flutterToastChannel,
            (MethodCall methodCall) async {
      if (methodCall.method == 'showToast' || methodCall.method == 'cancel') {
        return true;
      }
      return null;
    });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(flutterToastChannel, null);
  });

  setUp(() {
    Get.testMode = true;
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    isLoggedIn(true);
    loginUserData(UserData(
      id: 1,
      userName: 'tester',
      email: 'tester@example.com',
      apiToken: 'old-token',
      userRole: <String>['user'],
    ));
  });

  group('Release: lib/screens/auth/password/change_password_controller.dart',
      () {
    test('rejects when new and confirm mismatch', () async {
      final controller = ChangePassController();
      controller.oldPasswordCont.text = 'Old@123';
      controller.newpasswordCont.text = 'New@123';
      controller.confirmPasswordCont.text = 'New@124';

      await controller.saveForm();

      expect(controller.isLoading.value, isFalse);
      controller.onClose();
    });

    test('rejects when old and new passwords are identical', () async {
      final controller = ChangePassController();
      controller.oldPasswordCont.text = 'Same@123';
      controller.newpasswordCont.text = 'Same@123';
      controller.confirmPasswordCont.text = 'Same@123';

      await controller.saveForm();

      expect(controller.isLoading.value, isFalse);
      controller.onClose();
    });

    test('password rules are evaluated correctly', () {
      final controller = ChangePassController();

      controller.checkPasswordRules('Abc@123');
      expect(controller.hasUppercase.value, isTrue);
      expect(controller.hasLetter.value, isTrue);
      expect(controller.hasNumber.value, isTrue);
      expect(controller.hasSpecial.value, isTrue);

      controller.checkPasswordRules('abcdef');
      expect(controller.hasUppercase.value, isFalse);
      expect(controller.hasNumber.value, isFalse);
      expect(controller.hasSpecial.value, isFalse);
      expect(controller.hasLetter.value, isTrue);

      controller.onClose();
    });

    test('change password success updates token and persists secure data',
        () async {
      final controller = ChangePassController();
      controller.oldPasswordCont.text = 'Old@123';
      controller.newpasswordCont.text = 'New@123';
      controller.confirmPasswordCont.text = 'New@123';

      await runWithStubResponses(
        action: () => controller.saveForm(),
        payloads: <String, Object?>{
          APIEndPoints.changePassword: <String, Object?>{
            'status': true,
            'message': 'ok',
            'data': <String, Object?>{
              'api_token': 'new-token',
              'name': 'tester',
            },
          },
        },
      );

      expect(controller.isLoading.value, isFalse);
      expect(loginUserData.value.apiToken, 'new-token');

      final UserData? secureUser = await getUserDataSecure();
      expect(secureUser, isNotNull);
      expect(secureUser!.apiToken, 'new-token');
      controller.onClose();
    });

    test('change password failure resets loading state', () async {
      final controller = ChangePassController();
      controller.oldPasswordCont.text = 'Old@123';
      controller.newpasswordCont.text = 'New@123';
      controller.confirmPasswordCont.text = 'New@123';

      await runWithStubResponses(
        action: () => controller.saveForm(),
        payloads: <String, Object?>{
          APIEndPoints.changePassword: <String, Object?>{
            'status': false,
            'message': 'invalid',
          },
        },
      );

      expect(controller.isLoading.value, isFalse);
      controller.onClose();
    });

    test('onClose disposes controllers without throwing', () {
      final controller = ChangePassController();
      controller.onClose();
      expect(true, isTrue);
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
