import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../errors/failures.dart';

// Callback so ApiClient can notify AuthBloc about 401s without a circular dep
typedef OnUnauthorized = void Function();

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage? _secureStorage;
  final SharedPreferences? _prefs;
  OnUnauthorized? onUnauthorized;

  ApiClient({
    FlutterSecureStorage? secureStorage,
    SharedPreferences? prefs,
  })  : _secureStorage = secureStorage,
        _prefs = prefs {
    _dio = Dio(
      BaseOptions(
        baseUrl: kIsWeb
            ? 'http://localhost:3000/api'
            : AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _dio.interceptors.add(_authInterceptor());
    _dio.interceptors.add(_errorInterceptor());
  }

  Future<String?> _readToken() async {
    if (kIsWeb) {
      return _prefs?.getString(AppConstants.accessTokenKey);
    }
    return _secureStorage?.read(key: AppConstants.accessTokenKey);
  }

  Interceptor _authInterceptor() => InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await _readToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
  );

  Interceptor _errorInterceptor() => InterceptorsWrapper(
    onError: (error, handler) {
      // When we get a 401, notify auth system
      if (error.response?.statusCode == 401) {
        onUnauthorized?.call();
      }
      handler.next(error);
    },
  );

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    return _dio.delete(path);
  }

  static Failure handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const NetworkFailure('Connection timed out. Please try again.');
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = _extractMessage(e.response?.data);
        if (statusCode == 401) return UnauthorizedFailure(message);
        if (statusCode == 404) return NotFoundFailure(message);
        if (statusCode == 400 || statusCode == 422) {
          return ValidationFailure(message);
        }
        return ServerFailure(message);
      default:
        return const ServerFailure('Unexpected error. Please try again.');
    }
  }

  static String _extractMessage(dynamic data) {
    if (data is Map) {
      return data['message']?.toString() ?? 'An error occurred';
    }
    return 'An error occurred';
  }
}