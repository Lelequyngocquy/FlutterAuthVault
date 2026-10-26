class BaseResult<T> {
  final bool success;
  final String? code;
  final String? message;
  final T? data;
  const BaseResult({
    this.success = true,
    this.code,
    this.message,
    this.data,
  });
  factory BaseResult.ok(T? data, {String? message}) => BaseResult(
    success: true,
    data: data,
    message: message,
  );
  factory BaseResult.err(String message, {String? code}) => BaseResult(
    success: false,
    message: message,
    code: code,
  );
}
