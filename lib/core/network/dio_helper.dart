import 'package:dio/dio.dart';
import '../errors/failures.dart';

class DioHelper {
  late Dio _dio;
  static DioHelper? _instance;

  DioHelper._internal() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        responseType: ResponseType.json,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'IPTV-Smarters/1.0.0',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Log requests in debug mode
          print('🚀 REQUEST: ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ RESPONSE: ${response.statusCode}');
          return handler.next(response);
        },
        onError: (error, handler) {
          print('❌ ERROR: ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  factory DioHelper() {
    _instance ??= DioHelper._internal();
    return _instance!;
  }

  Dio get dio => _dio;

  Future<Response> get(
      String url, {
        Map<String, dynamic>? queryParameters,
      }) async {
    try {
      final response = await _dio.get(url, queryParameters: queryParameters);
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> post(
      String url, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
      }) async {
    try {
      final response = await _dio.post(url, data: data, queryParameters: queryParameters);
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('انتهت مهلة الاتصال، تحقق من الإنترنت');
      case DioExceptionType.badResponse:
        if (error.response?.statusCode == 401 || error.response?.statusCode == 403) {
          return AuthException('بيانات الدخول غير صحيحة');
        }
        return ServerException('خطأ في السيرفر: ${error.response?.statusCode}');
      case DioExceptionType.connectionError:
        return NetworkException('لا يوجد اتصال بالإنترنت');
      case DioExceptionType.cancel:
        return ServerException('تم إلغاء الطلب');
      default:
        return ServerException('حدث خطأ غير متوقع');
    }
  }
}
