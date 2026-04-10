import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker_macos/image_picker_macos.dart';
import 'package:kivicare_patient/main.dart';
import 'package:kivicare_patient/screens/auth/model/common_model.dart';
import 'package:kivicare_patient/screens/auth/model/login_response.dart';
import 'package:kivicare_patient/screens/auth/profile/edit_user_profile_controller.dart';
import 'package:kivicare_patient/utils/api_end_points.dart';
import 'package:kivicare_patient/utils/app_common.dart';
import 'package:kivicare_patient/utils/common_base.dart';
import 'package:kivicare_patient/utils/constants.dart';
import 'package:kivicare_patient/utils/local_storage.dart';
import 'package:kivicare_patient/utils/secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel pathProviderChannel =
      MethodChannel('plugins.flutter.io/path_provider');
  const MethodChannel connectivityChannel =
      MethodChannel('dev.fluttercommunity.plus/connectivity');
  const MethodChannel flutterToastChannel =
      MethodChannel('PonnamKarthik/fluttertoast');

  String? nextPickedImagePath;
  late final FileSelectorPlatform originalFileSelector;

  Future<File> createTempFile(String name, {String content = 'x'}) async {
    final Directory dir =
        await Directory.systemTemp.createTemp('edit_profile_release_');
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
          statusCode: 400,
          reasonPhrase: 'Bad Request',
          body: jsonEncode(
            <String, dynamic>{'status': false, 'message': 'route not found'},
          ),
        ),
      ),
    );
  }

  Future<T> runWithStubReplies<T>({
    required Future<T> Function() action,
    required Map<String, _StubHttpReply> replies,
  }) {
    return HttpOverrides.runZoned(
      action,
      createHttpClient: (SecurityContext? context) => _StubHttpClient(
        routes: replies,
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

  Future<void> waitUntil(
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 1),
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    while (!condition()) {
      if (stopwatch.elapsed > timeout) break;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  Future<BuildContext> pumpHost(WidgetTester tester) async {
    final GlobalKey hostKey = GlobalKey();

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Container(key: hostKey),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    return hostKey.currentContext!;
  }

  Future<void> pumpUi(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  setUpAll(() async {
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

    originalFileSelector = ImagePickerMacOS.fileSelector;
    ImagePickerMacOS.fileSelector = _FakeFileSelectorPlatform(
      getPath: () => nextPickedImagePath,
    );

    await GetStorage.init('test-edit-user-profile-controller-release');
    localStorage = GetStorage('test-edit-user-profile-controller-release');
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(flutterToastChannel, null);
    ImagePickerMacOS.fileSelector = originalFileSelector;
  });

  setUp(() async {
    Get.reset();
    Get.testMode = true;
    await localStorage.erase();
    FlutterSecureStorage.setMockInitialValues(<String, String>{});

    isLoggedIn(true);
    selectedLanguageCode('en');

    loginUserData(
      UserData(
        id: 21,
        firstName: 'Base',
        lastName: 'User',
        userName: 'Base User',
        email: 'real.user@example.com',
        apiToken: 'token-21',
        userRole: const <String>[LoginTypeConst.LOGIN_TYPE_USER],
        mobile: '+91 9000000000',
        gender: 'male',
        dateOfBirth: '1991-01-01',
        address: 'Address',
      ),
    );

    nextPickedImagePath = null;
  });

  group('Release: lib/screens/auth/profile/edit_user_profile_controller.dart',
      () {
    test('init maps profile response and valid phone code parsing', () async {
      final controller = EditUserProfileController();

      await runWithStubResponses(
        action: () => controller.init(),
        payloads: <String, Object?>{
          APIEndPoints.userDetail: <String, Object?>{
            'status': true,
            'data': <String, Object?>{
              'first_name': 'John',
              'last_name': 'Doe',
              'mobile': '+91 9876543210',
              'email': 'john@example.com',
              'gender': 'male',
              'date_of_birth': '1999-01-02',
              'address': 'Street 1',
              'profile_image': 'https://img/john.png',
            },
          },
        },
      );

      expect(controller.isLoading.value, isFalse);
      expect(controller.fNameCont.text, 'John');
      expect(controller.lNameCont.text, 'Doe');
      expect(controller.mobileCont.text, '9876543210');
      expect(controller.emailCont.text, 'john@example.com');
      expect(controller.addressCont.text, 'Street 1');
      expect(controller.pickedPhoneCode.value.phoneCode, '91');
      expect(controller.selectedGender.value.slug, 'male');
      expect(controller.dateOfBirthCont.text, '1999-01-02');

      final UserData? secureUser = await getUserDataSecure();
      expect(secureUser, isNotNull);
      expect(secureUser!.firstName, 'John');

      controller.onClose();
    });

    test('init fallback phone-code parser branch and gender fallback',
        () async {
      final controller = EditUserProfileController();

      await runWithStubResponses(
        action: () => controller.init(),
        payloads: <String, Object?>{
          APIEndPoints.userDetail: <String, Object?>{
            'status': true,
            'data': <String, Object?>{
              'first_name': 'Alex',
              'last_name': 'K',
              'mobile': '+999 12345',
              'email': 'alex@example.com',
              'gender': 'unsupported',
              'date_of_birth': '2001-02-03',
              'address': 'Street 2',
            },
          },
        },
      );

      expect(controller.mobileCont.text, '12345');
      expect(
          controller.pickedPhoneCode.value.phoneCode, defaultCountry.phoneCode);
      expect(controller.selectedGender.value.slug, 'other');
      expect(controller.isLoading.value, isFalse);

      controller.onClose();
    });

    test('init handles invalid phone code format branch', () async {
      final controller = EditUserProfileController();

      await runWithStubResponses(
        action: () => controller.init(),
        payloads: <String, Object?>{
          APIEndPoints.userDetail: <String, Object?>{
            'status': true,
            'data': <String, Object?>{
              'first_name': 'Sam',
              'last_name': 'L',
              'mobile': '0 88776655',
              'email': 'sam@example.com',
              'gender': 'female',
              'date_of_birth': '2002-02-03',
              'address': 'Street 3',
            },
          },
        },
      );

      expect(controller.mobileCont.text, '88776655');
      expect(
          controller.pickedPhoneCode.value.phoneCode, defaultCountry.phoneCode);
      expect(controller.selectedGender.value.slug, 'female');

      controller.onClose();
    });

    test('updateUserProfile success updates login user and secure storage',
        () async {
      final controller = EditUserProfileController();
      final File image = await createTempFile('profile.png');

      controller.fNameCont.text = 'Updated';
      controller.lNameCont.text = 'Person';
      controller.mobileCont.text = '9999911111';
      controller.addressCont.text = 'Updated Address';
      controller.emailCont.text = 'updated@example.com';
      controller
          .selectedGender(CMNModel(id: 2, name: 'Female', slug: 'female'));
      controller.selectedDate(DateTime(2001, 2, 3));
      controller.imageFile(image);

      await runWithStubResponses(
        action: () => controller.updateUserProfile(),
        payloads: <String, Object?>{
          APIEndPoints.updateProfile: <String, Object?>{
            'status': true,
            'message': 'updated',
            'data': <String, Object?>{
              'first_name': 'Updated',
              'last_name': 'Person',
              'mobile': '+91 9999911111',
              'email': 'updated@example.com',
              'gender': 'female',
              'date_of_birth': '2001-02-03',
              'address': 'Updated Address',
              'profile_image': 'https://example.com/profile.png',
            },
          },
        },
      );

      await waitUntil(() => controller.isLoading.value == false);

      expect(controller.isLoading.value, isFalse);
      expect(loginUserData.value.firstName, 'Updated');
      expect(loginUserData.value.lastName, 'Person');
      expect(loginUserData.value.gender, 'female');
      expect(loginUserData.value.dateOfBirth, '2001-02-03');

      final UserData? secureUser = await getUserDataSecure();
      expect(secureUser, isNotNull);
      expect(secureUser!.firstName, 'Updated');

      controller.onClose();
    });

    test('updateUserProfile failure branch resets loading state', () async {
      final controller = EditUserProfileController();

      controller.fNameCont.text = 'Name';
      controller.lNameCont.text = 'Surname';
      controller.mobileCont.text = '1234567890';
      controller.selectedGender(CMNModel(id: 1, name: 'Male', slug: 'male'));
      controller.selectedDate(DateTime(2000, 1, 1));

      await runWithStubReplies(
        action: () => controller.updateUserProfile(),
        replies: <String, _StubHttpReply>{
          APIEndPoints.updateProfile: const _StubHttpReply(
            statusCode: 400,
            reasonPhrase: 'Bad Request',
            body: '{"status":false,"message":"invalid payload"}',
          ),
        },
      );

      await waitUntil(() => controller.isLoading.value == false);

      expect(controller.isLoading.value, isFalse);
      expect(loginUserData.value.firstName, 'Base');

      controller.onClose();
    });

    testWidgets(
      'gallery flow updates image and opens profile-photo confirm',
      (WidgetTester tester) async {
        final BuildContext context = await pumpHost(tester);
        final controller = EditUserProfileController(isProfilePhoto: true);
        final File image = await createTempFile('gallery.png');
        nextPickedImagePath = image.path;

        controller.showBottomSheet(context);
        await pumpUi(tester);

        expect(find.text(locale.value.gallery), findsOneWidget);
        await tester.tap(find.text(locale.value.gallery));
        await pumpUi(tester);

        expect(controller.imageFile.value.path, image.path);
        expect(find.text(locale.value.wouldYouLikeToSetProfilePhotoAs),
            findsOneWidget);

        controller.onClose();
      },
      skip: true,
    );

    testWidgets(
      'camera flow updates image and opens profile-photo confirm',
      (WidgetTester tester) async {
        final BuildContext context = await pumpHost(tester);
        final controller = EditUserProfileController(isProfilePhoto: true);
        final File image = await createTempFile('camera.png');
        nextPickedImagePath = image.path;

        controller.showBottomSheet(context);
        await pumpUi(tester);

        expect(find.text(locale.value.camera), findsOneWidget);
        await tester.tap(find.text(locale.value.camera));
        await pumpUi(tester);

        expect(controller.imageFile.value.path, image.path);
        expect(find.text(locale.value.wouldYouLikeToSetProfilePhotoAs),
            findsOneWidget);

        controller.onClose();
      },
      skip: true,
    );

    testWidgets('confirm yes path triggers profile-photo update request',
        (WidgetTester tester) async {
      await pumpHost(tester);

      final controller = EditUserProfileController(isProfilePhoto: true);
      final File image = await createTempFile('confirm.png');
      controller.imageFile(image);
      controller.selectedDate(DateTime(2003, 4, 5));

      await runWithStubResponses(
        action: () async {
          controller.showConfimDialogChoosePhoto();
          await pumpUi(tester);

          expect(find.text(locale.value.yes), findsOneWidget);
          await tester.tap(find.text(locale.value.yes));
          await pumpUi(tester);
        },
        payloads: <String, Object?>{
          APIEndPoints.updateProfile: <String, Object?>{
            'status': true,
            'message': 'updated',
            'data': <String, Object?>{
              'first_name': loginUserData.value.firstName,
              'last_name': loginUserData.value.lastName,
              'mobile': loginUserData.value.mobile,
              'email': loginUserData.value.email,
              'gender': loginUserData.value.gender,
              'date_of_birth': '2003-04-05',
              'address': loginUserData.value.address,
              'profile_image': 'https://example.com/new.png',
            },
          },
        },
      );

      await waitUntil(() => controller.isLoading.value == false);

      expect(controller.isLoading.value, isFalse);
      expect(loginUserData.value.profileImage, 'https://example.com/new.png');

      controller.onClose();
    });

    testWidgets('pickDate writes selected date into controller',
        (WidgetTester tester) async {
      final BuildContext context = await pumpHost(tester);
      final controller = EditUserProfileController();

      final Future<void> pickDateFuture = controller.pickDate(context);
      await pumpUi(tester);

      await tester.tap(find.text('OK'));
      await pumpUi(tester);

      await pickDateFuture;

      expect(controller.dateOfBirthCont.text, isNotEmpty);
      expect(
        controller.dateOfBirthCont.text,
        controller.selectedDate.value.formatDateYYYYmmdd(),
      );

      controller.onClose();
    });

    test('onClose disposes all controllers and focus nodes', () {
      final controller = EditUserProfileController();
      controller.onClose();

      expect(
        () => controller.fNameCont.addListener(() {}),
        throwsA(anything),
      );
      expect(
        () => controller.fNameFocus.addListener(() {}),
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

class _FakeFileSelectorPlatform extends FileSelectorPlatform {
  _FakeFileSelectorPlatform({required this.getPath});

  final String? Function() getPath;

  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async {
    final String? path = getPath();
    if (path == null || path.isEmpty) return null;
    return XFile(path);
  }

  @override
  Future<List<XFile>> openFiles({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async {
    final String? path = getPath();
    if (path == null || path.isEmpty) return <XFile>[];
    return <XFile>[XFile(path)];
  }
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
