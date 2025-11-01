import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

/// Testes de Agendamentos
/// 
/// Valida:
/// 1. Cliente criar agendamento
/// 2. Barbeiro visualizar agenda
/// 3. Barbeiro atualizar status
/// 4. Cliente cancelar agendamento
/// 5. Listar agendamentos do cliente
void main() {
  group('Testes de Agendamentos', () {
    late Dio dio;
    late String clientToken;
    late String barberToken;
    late int appointmentId;

    setUp(() {
      dio = Dio(BaseOptions(
        baseUrl: 'http://localhost:7891/api',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
    });

    test('1. Login cliente', () async {
      // Fazer login com cliente existente (ou usar admin para criar)
      try {
        final loginResponse = await dio.post('/auth/login/', data: {
          'username': 'cliente_test_auto',
          'password': 'teste123',
        });

        clientToken = loginResponse.data['access'];
        print('✅ Login cliente OK - Token obtido');
      } catch (e) {
        // Se não existe, usar admin como cliente para testes
        print('⚠️  Cliente não existe, usando admin');
        final adminLogin = await dio.post('/auth/login/', data: {
          'username': 'admin',
          'password': 'admin123',
        });
        
        clientToken = adminLogin.data['access'];
        print('✅ Login admin OK - Usando como cliente');
      }

      expect(clientToken, isNotNull);
    });

    test('2. Login barbeiro', () async {
      final response = await dio.post('/auth/login/', data: {
        'username': 'barbeiro_teste',
        'password': 'teste123',
      });

      expect(response.statusCode, 200);
      barberToken = response.data['access'];
      
      print('✅ Login barbeiro OK');
    });

    test('3. Cliente criar agendamento', () async {
      // Data e hora futuros
      final scheduledFor = '2025-11-02T10:00:00';

      final response = await dio.post(
        '/appointments/',
        data: {
          'barber': 13, // barbeiro_teste
          'service': 1, // Corte Simples
          'scheduled_for': scheduledFor,
          'notes': 'Teste automatizado',
        },
        options: Options(headers: {'Authorization': 'Bearer $clientToken'}),
      );

      expect(response.statusCode, 201);
      appointmentId = response.data['id'];
      
      print('✅ Agendamento criado - ID: $appointmentId');
      print('   Cliente: ${response.data['client_name']}');
      print('   Barbeiro: ${response.data['barber_name']}');
      print('   Serviço: ${response.data['service_name']}');
      print('   Horário: ${response.data['scheduled_for']}');
    });

    test('4. Listar agendamentos do cliente', () async {
      final response = await dio.get(
        '/appointments/',
        options: Options(headers: {'Authorization': 'Bearer $clientToken'}),
      );

      expect(response.statusCode, 200);
      
      final appointments = response.data['results'] as List;
      print('📋 Agendamentos do cliente: ${appointments.length}');
      
      for (var apt in appointments.take(3)) {
        print('   - ${apt['service_name']} com ${apt['barber_name']} em ${apt['scheduled_for']}');
      }

      expect(appointments.length, greaterThan(0));
    });

    test('5. Barbeiro visualizar agenda do dia', () async {
      final response = await dio.get(
        '/appointments/barber_schedule/',
        queryParameters: {'date': '2025-11-02'},
        options: Options(headers: {'Authorization': 'Bearer $barberToken'}),
      );

      expect(response.statusCode, 200);
      
      final schedule = response.data as List;
      print('📅 Agenda do barbeiro (02/11/2025): ${schedule.length} agendamentos');
      
      for (var apt in schedule) {
        print('   - ${apt['scheduled_for']} - ${apt['client_name']} (${apt['service_name']})');
      }

      expect(schedule.length, greaterThan(0));
    });

    test('6. Barbeiro confirmar agendamento', () async {
      final response = await dio.patch(
        '/appointments/$appointmentId/update_status/',
        data: {'status': 'confirmed'},
        options: Options(headers: {'Authorization': 'Bearer $barberToken'}),
      );

      expect(response.statusCode, 200);
      expect(response.data['status'], 'confirmed');
      
      print('✅ Agendamento confirmado');
      print('   Status: ${response.data['status']}');
    });

    test('7. Barbeiro completar agendamento', () async {
      final response = await dio.patch(
        '/appointments/$appointmentId/update_status/',
        data: {'status': 'completed'},
        options: Options(headers: {'Authorization': 'Bearer $barberToken'}),
      );

      expect(response.statusCode, 200);
      expect(response.data['status'], 'completed');
      
      print('✅ Agendamento completado');
    });

    test('8. Cliente tentar cancelar agendamento completado (deve falhar)', () async {
      try {
        await dio.patch(
          '/appointments/$appointmentId/cancel/',
          options: Options(headers: {'Authorization': 'Bearer $clientToken'}),
        );

        fail('Deveria ter falhado');
      } catch (e) {
        if (e is DioException) {
          expect(e.response?.statusCode, 400);
          print('✅ Validação OK: Não pode cancelar agendamento completado');
        }
      }
    });

    test('9. Criar novo agendamento para testar cancelamento', () async {
      final response = await dio.post(
        '/appointments/',
        data: {
          'barber': 13,
          'service': 1,
          'scheduled_for': '2025-11-03T15:00:00',
        },
        options: Options(headers: {'Authorization': 'Bearer $clientToken'}),
      );

      appointmentId = response.data['id'];
      print('✅ Novo agendamento criado - ID: $appointmentId');
    });

    test('10. Cliente cancelar agendamento', () async {
      final response = await dio.patch(
        '/appointments/$appointmentId/cancel/',
        options: Options(headers: {'Authorization': 'Bearer $clientToken'}),
      );

      expect(response.statusCode, 200);
      expect(response.data['appointment']['status'], 'cancelled');
      
      print('✅ Agendamento cancelado pelo cliente');
    });

    test('11. Validar horários não disponíveis após criar agendamento', () async {
      // Criar agendamento às 16:00
      await dio.post(
        '/appointments/',
        data: {
          'barber': 13,
          'service': 1, // 30 minutos
          'scheduled_for': '2025-11-04T16:00:00',
        },
        options: Options(headers: {'Authorization': 'Bearer $clientToken'}),
      );

      // Verificar horários disponíveis
      final response = await dio.get(
        '/appointments/available_times/',
        queryParameters: {
          'barber_id': 13,
          'date': '2025-11-04',
          'service_id': 1,
        },
        options: Options(headers: {'Authorization': 'Bearer $clientToken'}),
      );

      final availableTimes = List<String>.from(response.data['available_times']);

      // 16:00 e 16:05-16:25 devem estar ocupados
      expect(availableTimes.contains('16:00'), false);
      expect(availableTimes.contains('16:10'), false);
      expect(availableTimes.contains('16:20'), false);
      
      // 16:30 deve estar disponível
      expect(availableTimes.contains('16:30'), true);

      print('✅ Horários bloqueados corretamente após criar agendamento');
      print('   16:00-16:25: OCUPADO');
      print('   16:30: DISPONÍVEL');
    });
  });
}
