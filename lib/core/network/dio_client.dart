import 'package:dio/dio.dart';
// import 'package:pretty_dio_logger/pretty_dio_logger.dart'; // Desabilitado
import '../constants/api_config.dart';
import 'api_interceptor.dart';

/// Cliente HTTP centralizado
class DioClient {
  static Dio? _dio;

  /// Obter instância do Dio
  static Dio get instance {
    if (_dio == null) {
      _dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
          headers: {
            'Content-Type': ApiConfig.contentType,
            'Accept': ApiConfig.accept,
          },
        ),
      );

      // Adicionar interceptor customizado
      _dio!.interceptors.add(ApiInterceptor(_dio!));

      // Logger desabilitado para melhor performance
      // _dio!.interceptors.add(
      //   PrettyDioLogger(
      //     requestHeader: true,
      //     requestBody: true,
      //     responseBody: true,
      //     responseHeader: false,
      //     error: true,
      //     compact: true,
      //     maxWidth: 90,
      //   ),
      // );
    }

    return _dio!;
  }

  /// GET request
  static Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await instance.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// POST request
  static Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await instance.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// PUT request
  static Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await instance.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// PATCH request
  static Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await instance.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// DELETE request
  static Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await instance.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Upload de arquivo
  static Future<Response> uploadFile(
    String path,
    String filePath, {
    String fileKey = 'file',
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      fileKey: await MultipartFile.fromFile(filePath),
      ...?data,
    });

    return await instance.post(
      path,
      data: formData,
      onSendProgress: onSendProgress,
    );
  }

  /// Limpar instância (útil para testes)
  static void reset() {
    _dio = null;
  }
}
