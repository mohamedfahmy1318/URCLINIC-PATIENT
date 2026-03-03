import 'dashboard_res_model.dart';

class BannerListResponse {
  bool status;
  List<BannerModel> data;
  String message;

  BannerListResponse({
    this.status = false,
    this.data = const <BannerModel>[],
    this.message = "",
  });

  factory BannerListResponse.fromJson(Map<String, dynamic> json) {
    return BannerListResponse(
      status: json['status'] is bool ? json['status'] : false,
      data: json['data'] is List
          ? List<BannerModel>.from(
              json['data'].map((x) => BannerModel.fromJson(x)))
          : [],
      message: json['message'] is String ? json['message'] : "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data.map((e) => e.toJson()).toList(),
      'message': message,
    };
  }
}
