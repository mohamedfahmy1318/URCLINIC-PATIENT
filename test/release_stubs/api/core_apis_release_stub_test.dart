import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:kivicare_patient/api/core_apis.dart';
import 'package:kivicare_patient/screens/Encounter/model/encounter_list_model.dart';
import 'package:kivicare_patient/screens/auth/model/login_response.dart';
import 'package:kivicare_patient/screens/bed/model/bed_history_model.dart';
import 'package:kivicare_patient/screens/booking/model/appointments_res_model.dart';
import 'package:kivicare_patient/screens/booking/model/employee_review_data.dart';
import 'package:kivicare_patient/screens/booking/model/save_booking_res.dart';
import 'package:kivicare_patient/screens/category/model/category_list_model.dart';
import 'package:kivicare_patient/screens/clinic/model/clinic_gallery_model.dart';
import 'package:kivicare_patient/screens/clinic/model/clinics_res_model.dart';
import 'package:kivicare_patient/screens/doctor/model/doctor_list_res.dart';
import 'package:kivicare_patient/screens/home/model/system_service_res.dart';
import 'package:kivicare_patient/screens/incident_management/model/incident_response_model.dart';
import 'package:kivicare_patient/screens/service/model/service_list_model.dart';
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
  const MethodChannel flutterToastChannel =
      MethodChannel('PonnamKarthik/fluttertoast');

  Future<File> createTempFile(String name, {String content = 'x'}) async {
    final Directory dir =
        await Directory.systemTemp.createTemp('core_api_release_');
    final File file = File('${dir.path}/$name');
    await file.writeAsString(content);
    return file;
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
          statusCode: 404,
          reasonPhrase: 'Not Found',
          body: jsonEncode(
            <String, dynamic>{'status': false, 'message': 'route not found'},
          ),
        ),
      ),
    );
  }

  Future<T> runWithStubResponses<T>({
    required Future<T> Function() action,
    required Map<String, Object?> payloads,
  }) {
    final Map<String, _StubHttpReply> replies = payloads.map(
      (String pattern, Object? payload) => MapEntry(
        pattern,
        _StubHttpReply(body: jsonEncode(payload)),
      ),
    );

    return runWithStubReplies(action: action, replies: replies);
  }

  setUpAll(() async {
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
        .setMockMethodCallHandler(flutterToastChannel,
            (MethodCall methodCall) async {
      if (methodCall.method == 'showToast' || methodCall.method == 'cancel') {
        return true;
      }
      return null;
    });

    await GetStorage.init('test-core-apis-release');
    localStorage = GetStorage('test-core-apis-release');
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(flutterToastChannel, null);
  });

  setUp(() async {
    await localStorage.erase();
    isLoggedIn(false);
    selectedLanguageCode('en');
    loginUserData(UserData(apiToken: 'core-token'));
    saveBookingRes(
      SaveBookingRes(saveBookingResData: SaveBookingResData()),
    );
  });

  group('Release: lib/api/core_apis.dart', () {
    test('collection endpoints populate lists and callbacks', () async {
      bool? systemLastPage;
      bool? categoryLastPage;
      bool? encounterLastPage;
      bool? serviceLastPage;
      bool? doctorServiceLastPage;
      bool? clinicLastPage;
      bool? galleryLastPage;
      bool? doctorLastPage;
      bool? appointmentLastPage;
      bool? reviewLastPage;
      bool? memberLastPage;
      bool? bedLastPage;
      bool? incidentLastPage;

      await runWithStubResponses(
        action: () async {
          final systems = await CoreServiceApis.getSystemService(
            page: 1,
            perPage: 1,
            categoryId: 2,
            systemServiceList: <SystemService>[SystemService(name: 'old')],
            lastPageCallBack: (bool val) => systemLastPage = val,
          );

          final categories = await CoreServiceApis.getCategoryList(
            page: 1,
            perPage: 1,
            categories: <CategoryElement>[CategoryElement(name: 'old')],
            lastPageCallBack: (bool val) => categoryLastPage = val,
          );

          final encounters = await CoreServiceApis.getEncounterList(
            page: 1,
            perPage: 1,
            encounterList: <EncounterElement>[EncounterElement(id: 90)],
            lastPageCallBack: (bool val) => encounterLastPage = val,
          );

          final services = await CoreServiceApis.getServiceList(
            page: 1,
            perPage: 1,
            search: 'flu',
            serviceType: 'home',
            servicePriceMin: '10',
            servicePriceMax: '50',
            categoryId: 1,
            systemServiceId: 2,
            clinicId: 3,
            doctorId: 4,
            isFeatures: 1,
            isPopulars: 1,
            enableAdvancePayment: 1,
            allServices: 'all',
            serviceList: <ServiceElement>[ServiceElement(id: 11)],
            lastPageCallBack: (bool val) => serviceLastPage = val,
          );

          final doctorServices = await CoreServiceApis.getDoctorServiceList(
            page: 1,
            perPage: 1,
            doctorId: 8,
            search: 'dr',
            serviceList: <ServiceElement>[ServiceElement(id: 12)],
            lastPageCallBack: (bool val) => doctorServiceLastPage = val,
          );

          final clinics = await CoreServiceApis.getClinics(
            page: 1,
            perPage: 1,
            search: 'city',
            servicePriceMin: '5',
            servicePriceMax: '100',
            serviceId: 1,
            clinicId: 1,
            isPopulars: 1,
            clinics: <Clinic>[],
            lastPageCallBack: (bool val) => clinicLastPage = val,
          );

          final gallery = await CoreServiceApis.getClinicGalleryList(
            page: 1,
            perPage: 1,
            clinicId: 1,
            galleryList: <GalleryData>[GalleryData(id: 1)],
            lastPageCallBack: (bool val) => galleryLastPage = val,
          );

          final doctors = await CoreServiceApis.getDoctors(
            page: 1,
            perPage: 1,
            clinicId: 1,
            search: 'alex',
            selectedServices: <int>[1, 2],
            doctorRatingMin: '3',
            doctorRatingMax: '5',
            isPopulars: 1,
            doctors: <Doctor>[Doctor(id: 7)],
            lastPageCallBack: (bool val) => doctorLastPage = val,
          );

          final appointments = await CoreServiceApis.getAppointmentList(
            page: 1,
            perPage: 1,
            clinicId: 1,
            doctorId: 2,
            firstDate: '2025-01-01',
            lastDate: '2025-01-02',
            serviceID: 3,
            categoryID: 4,
            consolationType: 'ONLINE',
            paymentStatus: PaymentStatus.REFUNDED,
            filterByStatus: 'upcoming',
            filterByService: 'General',
            search: 'a',
            appointments: <AppointmentData>[AppointmentData(id: 1)],
            lastPageCallBack: (bool val) => appointmentLastPage = val,
          );

          await CoreServiceApis.getAppointmentList(
            page: 1,
            perPage: 1,
            filterByStatus: 'completed',
            appointments: <AppointmentData>[],
          );

          await CoreServiceApis.getAppointmentList(
            page: 1,
            perPage: 1,
            filterByStatus: 'pending',
            appointments: <AppointmentData>[],
          );

          await CoreServiceApis.getAppointmentList(
            page: 1,
            perPage: 1,
            filterByStatus: 'cancelled',
            appointments: <AppointmentData>[],
          );

          final reviews = await CoreServiceApis.getDoctorReviews(
            page: 1,
            perPage: 1,
            doctorId: 3,
            reviewList: <DoctorReviewData>[DoctorReviewData(id: 1)],
            lastPageCallBack: (bool val) => reviewLastPage = val,
          );

          final members = await CoreServiceApis.otherMemberPatientList(
            page: 1,
            perPage: 1,
            memberList: <UserData>[UserData(id: 3)],
            lastPageCallBack: (bool val) => memberLastPage = val,
          );

          final bedHistory = await CoreServiceApis.getBedHistory(
            page: 1,
            perPage: 1,
            bedHistoryList: <BedHistoryData>[BedHistoryData(id: 4)],
            lastPageCallBack: (bool val) => bedLastPage = val,
          );

          final incidents = await CoreServiceApis.getIncidentList(
            page: 1,
            perPage: 1,
            incidents: <Incident>[Incident(fileUrl: '')],
            lastPageCallBack: (bool val) => incidentLastPage = val,
          );

          expect(systems.length, 1);
          expect(categories.length, 1);
          expect(encounters.length, 1);
          expect(services.length, 1);
          expect(doctorServices.length, 1);
          expect(clinics.length, 1);
          expect(gallery.length, 1);
          expect(doctors.length, 1);
          expect(appointments.length, 1);
          expect(reviews.length, 1);
          expect(members.length, 1);
          expect(bedHistory.length, 1);
          expect(incidents.length, 1);
        },
        payloads: <String, Object?>{
          APIEndPoints.getSystemService: <String, Object?>{
            'status': true,
            'data': <Map<String, Object?>>[
              <String, Object?>{'id': 1, 'name': 'System'},
            ],
          },
          APIEndPoints.getCategoryList: <String, Object?>{
            'status': true,
            'data': <Map<String, Object?>>[
              <String, Object?>{'id': 1, 'name': 'Category'},
            ],
          },
          APIEndPoints.getEncounterList: <String, Object?>{
            'status': true,
            'data': <Map<String, Object?>>[
              <String, Object?>{'id': 1},
            ],
          },
          APIEndPoints.getServiceList: <String, Object?>{
            'status': true,
            'data': <Map<String, Object?>>[
              <String, Object?>{'id': 1, 'name': 'Service'},
            ],
          },
          APIEndPoints.getClinicList: <String, Object?>{
            'status': true,
            'data': <Map<String, Object?>>[
              <String, Object?>{'id': 1, 'name': 'Clinic'},
            ],
          },
          APIEndPoints.getClinicGallery: <String, Object?>{
            'status': true,
            'data': <Map<String, Object?>>[
              <String, Object?>{'id': 1, 'full_url': 'https://example.com/1'},
            ],
          },
          APIEndPoints.getDoctorList: <String, Object?>{
            'status': true,
            'data': <Map<String, Object?>>[
              <String, Object?>{'id': 1, 'first_name': 'Alex'},
            ],
          },
          APIEndPoints.getAppointments: <String, Object?>{
            'status': true,
            'data': <Map<String, Object?>>[
              <String, Object?>{'id': 1},
            ],
          },
          APIEndPoints.getRating: <String, Object?>{
            'status': true,
            'data': <Map<String, Object?>>[
              <String, Object?>{'id': 1},
            ],
          },
          APIEndPoints.otherMemberPatientList: <String, Object?>{
            'status': true,
            'data': <Map<String, Object?>>[
              <String, Object?>{'id': 1, 'first_name': 'Member'},
            ],
          },
          APIEndPoints.getBedHistory: <String, Object?>{
            'status': true,
            'data': <Map<String, Object?>>[
              <String, Object?>{'id': 1},
            ],
          },
          APIEndPoints.incidenceList: <String, Object?>{
            'status': true,
            'data': <String, Object?>{
              'data': <Map<String, Object?>>[
                <String, Object?>{'id': 1, 'file_url': ''},
              ],
            },
          },
        },
      );

      expect(systemLastPage, isFalse);
      expect(categoryLastPage, isFalse);
      expect(encounterLastPage, isFalse);
      expect(serviceLastPage, isFalse);
      expect(doctorServiceLastPage, isFalse);
      expect(clinicLastPage, isFalse);
      expect(galleryLastPage, isFalse);
      expect(doctorLastPage, isFalse);
      expect(appointmentLastPage, isFalse);
      expect(reviewLastPage, isFalse);
      expect(memberLastPage, isFalse);
      expect(bedLastPage, isFalse);
      expect(incidentLastPage, isFalse);
    });

    test('detail and command wrappers parse success payloads', () async {
      await runWithStubResponses(
        action: () async {
          final service = await CoreServiceApis.getServiceDetail(serviceId: 1);
          final clinic = await CoreServiceApis.getClinicDetails(clinicId: 2);
          final doctor = await CoreServiceApis.getDoctorDetails(doctorId: 3);
          final appointment = await CoreServiceApis.getAppointmentDetail(
            appointmentId: 4,
            notifyId: '10',
          );
          final invoice = await CoreServiceApis.appointmentInvoice(5);
          final encounter =
              await CoreServiceApis.getEncounterDetail(encounterId: 6);

          final updated = await CoreServiceApis.updateStatus(
            request: <String, Object?>{'status': 'checked_out'},
            appointmentId: 7,
          );
          final rescheduled = await CoreServiceApis.rescheduleBooking(
            request: <String, Object?>{'id': 7},
          );
          final review = await CoreServiceApis.updateReview(
            request: <String, Object?>{'id': 1, 'rating': 5},
          );
          final reviewDelete = await CoreServiceApis.deleteReview(id: 1);
          final payment = await CoreServiceApis.savePayment(
            request: <String, Object?>{'id': 7},
          );
          final deletedMember = await CoreServiceApis.deleteMember(memberId: 9);
          final incidentStatus = await CoreServiceApis.updateIncidentStatus(
            incidentId: 11,
            request: <String, Object?>{'status': 1},
          );

          expect(service.status, isTrue);
          expect(clinic.status, isTrue);
          expect(doctor.status, isTrue);
          expect(appointment.status, isTrue);
          expect(invoice.value.status, isTrue);
          expect(encounter.status, isTrue);
          expect(updated.status, isTrue);
          expect(rescheduled.status, isTrue);
          expect(review.status, isTrue);
          expect(reviewDelete.status, isTrue);
          expect(payment.status, isTrue);
          expect(deletedMember.status, isTrue);
          expect(incidentStatus.status, isTrue);
        },
        payloads: <String, Object?>{
          APIEndPoints.getServiceDetails: <String, Object?>{'status': true},
          APIEndPoints.getClinicDetails: <String, Object?>{'status': true},
          APIEndPoints.getDoctorDetails: <String, Object?>{'status': true},
          APIEndPoints.getAppointmentDetail: <String, Object?>{'status': true},
          APIEndPoints.downloadInvoice: <String, Object?>{'status': true},
          APIEndPoints.encounterDashboardDetail: <String, Object?>{
            'status': true,
            'data': <String, Object?>{},
          },
          APIEndPoints.updateStatus: <String, Object?>{'status': true},
          APIEndPoints.rescheduleBooking: <String, Object?>{'status': true},
          APIEndPoints.saveRating: <String, Object?>{'status': true},
          APIEndPoints.deleteRating: <String, Object?>{'status': true},
          APIEndPoints.savePayment: <String, Object?>{'status': true},
          APIEndPoints.deleteOtherMember: <String, Object?>{'status': true},
          APIEndPoints.updateIncidentStatus: <String, Object?>{'status': true},
        },
      );
    });

    test('time slots parse holiday payload and invalid json fallback',
        () async {
      final slots = <String>[].obs;
      final messageHolder = ''.obs;
      final isHolidayHolder = false.obs;

      await runWithStubResponses(
        action: () async {
          final result = await CoreServiceApis.getTimeSlots(
            slots: slots,
            date: '2025-03-01',
            clinicId: 2,
            doctorId: 3,
            serviceId: 4,
            messageHolder: messageHolder,
            isHolidayHolder: isHolidayHolder,
          );

          expect(result, isEmpty);
          expect(messageHolder.value, 'Holiday');
          expect(isHolidayHolder.value, isTrue);
        },
        payloads: <String, Object?>{
          APIEndPoints.getTimeSlots: <String, Object?>{
            'status': false,
            'message': 'Holiday',
            'data': <String>[],
            'is_holiday': true,
          },
        },
      );

      await runWithStubReplies(
        action: () async {
          await expectLater(
            () => CoreServiceApis.getTimeSlots(
              slots: <String>[].obs,
              date: '2025-03-02',
              clinicId: 1,
              doctorId: 1,
              serviceId: 1,
            ),
            throwsA(anything),
          );
        },
        replies: <String, _StubHttpReply>{
          APIEndPoints.getTimeSlots: const _StubHttpReply(body: 'not-json'),
        },
      );
    });

    test('bookServiceApi success paths execute with and without files',
        () async {
      int successCount = 0;
      int loaderOffCount = 0;

      final File attachment = await createTempFile('booking.txt', content: 'a');

      await runWithStubReplies(
        action: () async {
          await CoreServiceApis.bookServiceApi(
            request: <String, dynamic>{'clinic_id': 1},
            onSuccess: () => successCount++,
            loaderOff: () => loaderOffCount++,
          );

          await CoreServiceApis.bookServiceApi(
            request: <String, dynamic>{'clinic_id': 1},
            files: <PlatformFile>[
              PlatformFile(path: attachment.path, name: 'booking.txt', size: 1),
            ],
            onSuccess: () => successCount++,
            loaderOff: () => loaderOffCount++,
          );
        },
        replies: <String, _StubHttpReply>{
          APIEndPoints.saveBooking: const _StubHttpReply(
            body: '{"status":true,"data":{"id":1},"message":"ok"}',
          ),
        },
      );

      expect(successCount, 2);
      expect(loaderOffCount, 0);
    });

    test('bookServiceApi parse-failure path still calls onSuccess', () async {
      int successCount = 0;
      int loaderOffCount = 0;

      await runWithStubReplies(
        action: () async {
          await CoreServiceApis.bookServiceApi(
            request: <String, dynamic>{'clinic_id': 2},
            onSuccess: () => successCount++,
            loaderOff: () => loaderOffCount++,
          );
        },
        replies: <String, _StubHttpReply>{
          APIEndPoints.saveBooking: const _StubHttpReply(body: 'not-json'),
        },
      );

      expect(successCount, 1);
      expect(loaderOffCount, 0);
    });

    test('bookServiceApi error path invokes loaderOff', () async {
      int successCount = 0;
      int loaderOffCount = 0;

      await runWithStubReplies(
        action: () async {
          await CoreServiceApis.bookServiceApi(
            request: <String, dynamic>{'clinic_id': 9},
            onSuccess: () => successCount++,
            loaderOff: () => loaderOffCount++,
          );
        },
        replies: <String, _StubHttpReply>{
          APIEndPoints.saveBooking: const _StubHttpReply(
            statusCode: 400,
            reasonPhrase: 'Bad Request',
            body: '{"status":false,"message":"bad"}',
          ),
        },
      );

      expect(successCount, 0);
      expect(loaderOffCount, 1);
    });

    test('add/update member and incident multipart flows execute', () async {
      final File profile = await createTempFile('member.png', content: 'img');
      final File incidentImage =
          await createTempFile('incident.png', content: 'img2');

      await runWithStubResponses(
        action: () async {
          final addMember = await CoreServiceApis.addUpdateOtherPatientApi(
            request: <String, dynamic>{'first_name': 'A'},
          );
          final updateMember = await CoreServiceApis.addUpdateOtherPatientApi(
            request: <String, dynamic>{'first_name': 'B'},
            profileImage: profile,
          );

          dynamic successPayload;
          await CoreServiceApis.addIncident(
            title: 'Issue',
            description: 'Desc',
            phoneCode: '1',
            mobileNumber: '1111111111',
            email: 'a@b.com',
            imageFile: incidentImage,
            onSuccess: (dynamic data) {
              successPayload = data;
            },
          );

          expect(addMember.status, isTrue);
          expect(updateMember.status, isTrue);
          expect(successPayload, contains('status'));
        },
        payloads: <String, Object?>{
          APIEndPoints.addPatient: <String, Object?>{
            'status': true,
            'message': 'saved',
          },
          APIEndPoints.incidenceSave: <String, Object?>{
            'status': true,
            'message': 'saved',
          },
        },
      );

      await runWithStubReplies(
        action: () async {
          await expectLater(
            () => CoreServiceApis.addIncident(
              title: 'Issue',
              description: 'Desc',
              phoneCode: '1',
              mobileNumber: '1111111111',
              email: 'a@b.com',
            ),
            throwsA(anything),
          );
        },
        replies: <String, _StubHttpReply>{
          APIEndPoints.incidenceSave: const _StubHttpReply(
            statusCode: 400,
            reasonPhrase: 'Bad Request',
            body: '{"status":false,"message":"bad"}',
          ),
        },
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

  _StubHttpClientResponse({required this.reply}) : _bytes = utf8.encode(reply.body) {
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
