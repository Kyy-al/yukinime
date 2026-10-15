import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

/// Centralized API client with rate limiting and error handling
class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;

  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.apiTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.apiTimeout),
      headers: {
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      logPrint: (obj) {},
    ));
  }

  factory ApiClient() {
    _instance ??= ApiClient._();
    return _instance!;
  }

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  AppException _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppException(
          'Koneksi timeout. Periksa koneksi internet Anda.',
          type: ErrorType.timeout,
        );
      case DioExceptionType.connectionError:
        return AppException(
          'Tidak ada koneksi internet.',
          type: ErrorType.noConnection,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        if (statusCode == 429) {
          return AppException(
            'Terlalu banyak permintaan. Coba lagi nanti.',
            type: ErrorType.rateLimit,
          );
        }
        return AppException(
          'Server error ($statusCode). Coba lagi nanti.',
          type: ErrorType.server,
        );
      case DioExceptionType.cancel:
        return AppException(
          'Permintaan dibatalkan.',
          type: ErrorType.cancelled,
        );
      default:
        return AppException(
          'Terjadi kesalahan. Coba lagi.',
          type: ErrorType.unknown,
        );
    }
  }
}

enum ErrorType {
  noConnection,
  timeout,
  server,
  rateLimit,
  cancelled,
  parse,
  unknown,
}

class AppException implements Exception {
  final String message;
  final ErrorType type;

  AppException(this.message, {this.type = ErrorType.unknown});

  @override
  String toString() => message;
}
