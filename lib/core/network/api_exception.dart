/// Exceções personalizadas da API
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => message;
}

/// Exceção de não autorizado (401)
class UnauthorizedException extends ApiException {
  UnauthorizedException({String? message})
      : super(
          message: message ?? 'Não autorizado. Faça login novamente.',
          statusCode: 401,
        );
}

/// Exceção de não encontrado (404)
class NotFoundException extends ApiException {
  NotFoundException({String? message})
      : super(
          message: message ?? 'Recurso não encontrado.',
          statusCode: 404,
        );
}

/// Exceção de servidor (500+)
class ServerException extends ApiException {
  ServerException({String? message})
      : super(
          message: message ?? 'Erro no servidor. Tente novamente mais tarde.',
          statusCode: 500,
        );
}

/// Exceção de conexão
class ConnectionException extends ApiException {
  ConnectionException()
      : super(
          message: 'Sem conexão com a internet. Verifique sua conexão.',
        );
}

/// Exceção de timeout
class TimeoutException extends ApiException {
  TimeoutException()
      : super(
          message: 'Tempo limite excedido. Tente novamente.',
        );
}

/// Exceção de validação (400)
class ValidationException extends ApiException {
  ValidationException({String? message, super.data})
      : super(
          message: message ?? 'Dados inválidos.',
          statusCode: 400,
        );
}

/// Exceção de conflito (409)
class ConflictException extends ApiException {
  ConflictException({String? message})
      : super(
          message: message ?? 'Conflito de dados.',
          statusCode: 409,
        );
}

/// Exceção de proibido (403)
class ForbiddenException extends ApiException {
  ForbiddenException({String? message})
      : super(
          message: message ?? 'Acesso negado.',
          statusCode: 403,
        );
}
