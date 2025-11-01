import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import 'api_exception.dart';

/// Interceptor para adicionar token e tratar erros
class ApiInterceptor extends Interceptor {
  final Dio dio;

  ApiInterceptor(this.dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.path;
    
    // NÃO adicionar token em endpoints públicos
    final isPublicEndpoint = path.contains('/auth/login') || 
                             path.contains('/auth/register') ||
                             path.contains('/auth/refresh') ||
                             path.contains('/users/check_email') ||
                             path.contains('/users/check_username') ||
                             (path == '/users/' && options.method == 'POST'); // Apenas registro de usuário
    
    if (!isPublicEndpoint) {
      // Adicionar token apenas para endpoints protegidos
      final token = await SecureStorage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    // Adicionar headers padrão
    options.headers['Content-Type'] = 'application/json';
    options.headers['Accept'] = 'application/json';

    return handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    return handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Tratar erro 401 (não autorizado)
    if (err.response?.statusCode == 401) {
      final path = err.requestOptions.path;
      
      // NÃO tentar refresh em endpoints de auth
      if (path.contains('/auth/login') || 
          path.contains('/auth/refresh') || 
          path == '/users/' && err.requestOptions.method == 'POST') { // Apenas registro
        // É erro de login/registro, não fazer retry
        final apiException = _handleError(err);
        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: apiException,
          ),
        );
      }
      
      // Tentar refresh do token para outras requisições
      final refreshed = await _refreshToken();
      if (refreshed) {
        // Retry da requisição original
        final options = err.requestOptions;
        final token = await SecureStorage.getAccessToken();
        options.headers['Authorization'] = 'Bearer $token';
        
        try {
          final response = await dio.fetch(options);
          return handler.resolve(response);
        } catch (e) {
          return handler.reject(err);
        }
      } else {
        // Refresh falhou, fazer logout
        await SecureStorage.clearAll();
        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: UnauthorizedException(),
          ),
        );
      }
    }

    // Converter DioException para ApiException
    final apiException = _handleError(err);
    return handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: apiException,
      ),
    );
  }

  /// Tentar renovar o token
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await dio.post(
        '/auth/refresh/',
        data: {'refresh': refreshToken},
        options: Options(
          headers: {'Authorization': null}, // Remover token antigo
        ),
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['access'];
        final newRefreshToken = response.data['refresh'];
        
        await SecureStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );
        
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Converter DioException para ApiException
  ApiException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException();

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = _extractErrorMessage(error.response?.data);

        switch (statusCode) {
          case 400:
            return ValidationException(
              message: message,
              data: error.response?.data,
            );
          case 401:
            return UnauthorizedException(message: message);
          case 403:
            return ForbiddenException(message: message);
          case 404:
            return NotFoundException(message: message);
          case 409:
            return ConflictException(message: message);
          case 500:
          case 501:
          case 502:
          case 503:
            return ServerException(message: message);
          default:
            return ApiException(
              message: message ?? 'Erro desconhecido',
              statusCode: statusCode,
            );
        }

      case DioExceptionType.connectionError:
        return ConnectionException();

      case DioExceptionType.cancel:
        return ApiException(message: 'Requisição cancelada');

      default:
        return ApiException(
          message: error.message ?? 'Erro desconhecido',
        );
    }
  }

  /// Extrair mensagem de erro da resposta
  String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;

    if (data is Map) {
      // Tentar pegar mensagem de diferentes campos comuns
      if (data['message'] != null) return data['message'].toString();
      if (data['error'] != null) return data['error'].toString();
      
      // Tratamento especial para erro de login
      if (data['detail'] != null) {
        final detail = data['detail'].toString().toLowerCase();
        
        // Detectar erro de usuário não encontrado
        if (detail.contains('no active account') || 
            detail.contains('não foi encontrado') ||
            detail.contains('user not found') ||
            detail.contains('invalid credentials')) {
          // Verificar se é erro de usuário ou senha
          // Django REST JWT retorna "No active account found with the given credentials"
          // para ambos os casos, mas podemos melhorar a mensagem
          return 'Usuário ou senha incorretos';
        }
        
        return data['detail'].toString();
      }
      
      // Se for um mapa de erros de validação (Django REST Framework)
      if (data['errors'] != null) {
        final errors = data['errors'];
        if (errors is Map) {
          return errors.values.first.toString();
        }
      }
      
      // Tratar erros de campos específicos do Django (ex: {"username": ["Este campo já existe"]})
      // Pegar o primeiro campo com erro
      for (var key in data.keys) {
        final value = data[key];
        if (value is List && value.isNotEmpty) {
          // Formatar mensagem: "Username: Este campo já existe"
          final fieldName = _formatFieldName(key);
          return '$fieldName: ${value.first}';
        } else if (value is String) {
          final fieldName = _formatFieldName(key);
          return '$fieldName: $value';
        }
      }
      
      // Pegar primeiro valor do mapa
      if (data.values.isNotEmpty) {
        final firstValue = data.values.first;
        if (firstValue is List && firstValue.isNotEmpty) {
          return firstValue.first.toString();
        }
        return firstValue.toString();
      }
    }

    if (data is String) return data;

    return null;
  }
  
  /// Formatar nome do campo para português
  String _formatFieldName(String fieldName) {
    final translations = {
      'username': 'Usuário',
      'email': 'E-mail',
      'password': 'Senha',
      'first_name': 'Nome',
      'last_name': 'Sobrenome',
      'phone': 'Telefone',
      'non_field_errors': 'Erro',
    };
    
    return translations[fieldName] ?? fieldName;
  }
}