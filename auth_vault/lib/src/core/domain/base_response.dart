class BaseResponse {
  final String? code;
  final String? message;
  final dynamic data;
  final bool isSuccess;
  const BaseResponse({
    this.code,
    this.message,
    this.data,
    this.isSuccess = false,
  });
  factory BaseResponse.fromSuccessJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return BaseResponse(
        isSuccess: json['isSuccess'] == true,
        code: json['code']?.toString(),
        message: json['message']?.toString(),
        data: json['data'],
      );
    }
    return BaseResponse(isSuccess: true, data: json);
  }
  factory BaseResponse.fromErrorJson(Map<String, dynamic> json) {
    return BaseResponse(
      isSuccess: false,
      code: json['code']?.toString(),
      message: json['message']?.toString() ?? json['code']?.toString() ?? 'Error',
      data: json['data'],
    );
  }
}
