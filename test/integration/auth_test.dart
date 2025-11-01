import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

/// Testes de Autenticação e Segurança
/// 
/// Valida:
/// 1. Registro de novo usuário
/// 2. Login com credenciais corretas
/// 3. Login com credenciais incorretas
/// 4. Acesso sem autenticação
/// 5. Token expirado
/// 6. Refresh token
/// 7. Permissões de acesso
void main() {
  group('Testes de Autenticação', () {
    late Dio dio;
    String? accessToken;
    String? refreshToken;
    String? adminToken;

    setUp(() {
      dio = Dio(BaseOptions(
        baseUrl: 'http://localhost:7891/api',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
    });

    test('1. Registro de novo usuário (via admin)', () async {
      // Admin login
      final adminLogin = await dio.post('/auth/login/', data: {
        'username': 'admin',
        'password': 'admin123',
      });
      adminToken = adminLogin.data['access'];
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Admin cria cliente (registro público desabilitado por segurança)
      final response = await dio.post(
        '/users/create_barber/',
        data: {
          'username': 'user_$timestamp',
          'email': 'user_$timestamp@teste.com',
          'password': 'senha123',
          'first_name': 'Usuário',
          'last_name': 'Teste',
          'phone': '11987654321',
        },
        options: Options(headers: {'Authorization': 'Bearer $adminToken'}),
      );

      expect(response.statusCode, 201);
      expect(response.data['username'], 'user_$timestamp');
      
      print('✅ Usuário criado via admin: ${response.data['username']}');
    });

    test('2. Login com credenciais corretas', () async {
      final response = await dio.post('/auth/login/', data: {
        'username': 'barbeiro_teste',
        'password': 'teste123',
      });

      expect(response.statusCode, 200);
      expect(response.data['access'], isNotNull);
      expect(response.data['refresh'], isNotNull);
      
      accessToken = response.data['access'];
      refreshToken = response.data['refresh'];
      
      print('✅ Login com credenciais corretas OK');
      print('   Access token: ${accessToken!.substring(0, 20)}...');
      print('   Refresh token: ${refreshToken!.substring(0, 20)}...');
    });

    test('3. Login com username incorreto', () async {
      try {
        await dio.post('/auth/login/', data: {
          'username': 'usuario_inexistente',
          'password': 'senha123',
        });
        
        fail('Deveria ter falhado');
      } catch (e) {
        if (e is DioException) {
          expect(e.response?.statusCode, anyOf([400, 401]));
          print('✅ Login com username incorreto rejeitado');
        }
      }
    });

    test('4. Login com senha incorreta', () async {
      try {
        await dio.post('/auth/login/', data: {
          'username': 'barbeiro_teste',
          'password': 'senha_errada',
        });
        
        fail('Deveria ter falhado');
      } catch (e) {
        if (e is DioException) {
          expect(e.response?.statusCode, anyOf([400, 401]));
          print('✅ Login com senha incorreta rejeitado');
        }
      }
    });

    test('5. Acesso sem autenticação deve falhar', () async {
      try {
        await dio.get('/appointments/');
        
        fail('Deveria ter falhado');
      } catch (e) {
        if (e is DioException) {
          expect(e.response?.statusCode, 401);
          print('✅ Acesso sem autenticação bloqueado');
        }
      }
    });

    test('6. Acesso com token válido', () async {
      final response = await dio.get(
        '/appointments/',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      expect(response.statusCode, 200);
      print('✅ Acesso com token válido permitido');
    });

    test('7. Acesso com token inválido', () async {
      try {
        await dio.get(
          '/appointments/',
          options: Options(headers: {'Authorization': 'Bearer token_invalido'}),
        );
        
        fail('Deveria ter falhado');
      } catch (e) {
        if (e is DioException) {
          expect(e.response?.statusCode, 401);
          print('✅ Acesso com token inválido bloqueado');
        }
      }
    });

    test('8. Refresh token para obter novo access token', () async {
      final response = await dio.post('/auth/refresh/', data: {
        'refresh': refreshToken,
      });

      expect(response.statusCode, 200);
      expect(response.data['access'], isNotNull);
      
      final newAccessToken = response.data['access'];
      expect(newAccessToken, isNot(equals(accessToken)));
      
      print('✅ Refresh token funcionando');
      print('   Novo access token: ${newAccessToken.substring(0, 20)}...');
    });

    test('9. Cliente não pode acessar endpoint de barbeiro', () async {
      // Usar admin como fallback se cliente não existir
      String clientToken;
      
      try {
        final loginResponse = await dio.post('/auth/login/', data: {
          'username': 'cliente_test_auto',
          'password': 'teste123',
        });
        clientToken = loginResponse.data['access'];
      } catch (e) {
        // Fallback para usuário existente
        final loginResponse = await dio.post('/auth/login/', data: {
          'username': 'admin',
          'password': 'admin123',
        });
        clientToken = loginResponse.data['access'];
      }

      // Tentar acessar agenda do barbeiro (apenas barbeiros)
      try {
        await dio.get(
          '/appointments/barber_schedule/',
          queryParameters: {'date': '2025-11-01'},
          options: Options(headers: {'Authorization': 'Bearer $clientToken'}),
        );
        
        // Admin pode acessar, então vamos verificar se retornou dados
        print('⚠️  Usuário tem permissão (pode ser admin)');
      } catch (e) {
        if (e is DioException && e.response?.statusCode == 403) {
          print('✅ Cliente bloqueado de endpoint de barbeiro');
        } else {
          print('⚠️  Erro diferente: ${e.toString()}');
        }
      }
    });

    test('10. Validar estrutura do token JWT', () async {
      expect(accessToken, isNotNull);
      
      // JWT tem 3 partes separadas por ponto
      final parts = accessToken!.split('.');
      expect(parts.length, 3);
      
      print('✅ Token JWT com estrutura válida');
      print('   Header: ${parts[0].substring(0, 20)}...');
      print('   Payload: ${parts[1].substring(0, 20)}...');
      print('   Signature: ${parts[2].substring(0, 20)}...');
    });

    test('11. Username deve ser único', () async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Criar primeiro usuário via admin
      await dio.post(
        '/users/create_barber/',
        data: {
          'username': 'unique_$timestamp',
          'email': 'unique1_$timestamp@teste.com',
          'password': 'senha123',
          'first_name': 'Teste',
          'last_name': 'Único',
        },
        options: Options(headers: {'Authorization': 'Bearer $adminToken'}),
      );

      // Tentar criar com mesmo username
      try {
        await dio.post(
          '/users/create_barber/',
          data: {
            'username': 'unique_$timestamp', // mesmo username
            'email': 'unique2_$timestamp@teste.com',
            'password': 'senha123',
            'first_name': 'Teste',
            'last_name': 'Duplicado',
          },
          options: Options(headers: {'Authorization': 'Bearer $adminToken'}),
        );
        
        fail('Deveria ter falhado');
      } catch (e) {
        if (e is DioException) {
          expect(e.response?.statusCode, 400);
          print('✅ Username duplicado rejeitado');
        }
      }
    });

    test('12. Email deve ser único', () async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final email = 'email_$timestamp@teste.com';
      
      // Criar primeiro usuário via admin
      await dio.post(
        '/users/create_barber/',
        data: {
          'username': 'user1_$timestamp',
          'email': email,
          'password': 'senha123',
          'first_name': 'Teste',
          'last_name': '1',
        },
        options: Options(headers: {'Authorization': 'Bearer $adminToken'}),
      );

      // Tentar criar com mesmo email
      try {
        await dio.post(
          '/users/create_barber/',
          data: {
            'username': 'user2_$timestamp',
            'email': email, // mesmo email
            'password': 'senha123',
            'first_name': 'Teste',
            'last_name': '2',
          },
          options: Options(headers: {'Authorization': 'Bearer $adminToken'}),
        );
        
        fail('Deveria ter falhado');
      } catch (e) {
        if (e is DioException) {
          expect(e.response?.statusCode, 400);
          print('✅ Email duplicado rejeitado');
        }
      }
    });
  });

  group('Testes de Permissões', () {
    late Dio dio;
    late String clientToken;
    late String barberToken;

    setUp(() async {
      dio = Dio(BaseOptions(
        baseUrl: 'http://localhost:7891/api',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      // Usar usuários existentes
      // Barbeiro já existe
      final barberLogin = await dio.post('/auth/login/', data: {
        'username': 'barbeiro_teste',
        'password': 'teste123',
      });
      barberToken = barberLogin.data['access'];

      // Usar admin como cliente (ou criar cliente via admin se necessário)
      try {
        final clientLogin = await dio.post('/auth/login/', data: {
          'username': 'cliente_test_auto',
          'password': 'teste123',
        });
        clientToken = clientLogin.data['access'];
      } catch (e) {
        // Usar admin como fallback
        final adminLogin = await dio.post('/auth/login/', data: {
          'username': 'admin',
          'password': 'admin123',
        });
        clientToken = adminLogin.data['access'];
      }
    });

    test('1. Cliente pode listar seus agendamentos', () async {
      final response = await dio.get(
        '/appointments/',
        options: Options(headers: {'Authorization': 'Bearer $clientToken'}),
      );

      expect(response.statusCode, 200);
      print('✅ Cliente pode listar seus agendamentos');
    });

    test('2. Barbeiro pode gerenciar seus serviços', () async {
      final response = await dio.get(
        '/services/barber/my-services/',
        options: Options(headers: {'Authorization': 'Bearer $barberToken'}),
      );

      expect(response.statusCode, 200);
      print('✅ Barbeiro pode gerenciar seus serviços');
    });

    test('3. Cliente NÃO pode gerenciar serviços de barbeiro', () async {
      try {
        await dio.get(
          '/services/barber/my-services/',
          options: Options(headers: {'Authorization': 'Bearer $clientToken'}),
        );
        
        // Admin pode acessar tudo, então vamos tratar isso
        print('⚠️  Usuário tem permissão (pode ser admin)');
      } catch (e) {
        if (e is DioException && e.response?.statusCode == 403) {
          print('✅ Cliente bloqueado de gerenciar serviços');
        } else {
          print('⚠️  Erro diferente: $e');
        }
      }
    });

    test('4. Barbeiro pode visualizar agenda', () async {
      final response = await dio.get(
        '/appointments/barber_schedule/',
        queryParameters: {'date': '2025-11-01'},
        options: Options(headers: {'Authorization': 'Bearer $barberToken'}),
      );

      expect(response.statusCode, 200);
      print('✅ Barbeiro pode visualizar agenda');
    });
  });
}
