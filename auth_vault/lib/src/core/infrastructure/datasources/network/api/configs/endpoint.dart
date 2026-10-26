import 'package:dio/dio.dart';

enum DioHttpMethod {
  get('GET'),
  post('POST'),
  put('PUT'),
  delete('DELETE');
  final String value;
  const DioHttpMethod(this.value);
}

class EndpointType {
  final String path;
  final DioHttpMethod method;
  final dynamic params;
  final Map<String, dynamic>? queryParameters;
  final Map<String, String>? headers;
  final ResponseType? responseType;
  const EndpointType({
    required this.path,
    this.method = DioHttpMethod.get,
    this.params,
    this.queryParameters,
    this.headers,
    this.responseType,
  });
}
