import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

/// Teste de integração: Validar horários de 5 em 5 minutos via API
/// 
/// Este teste valida diretamente com a API:
/// 1. Endpoint available_times retorna horários corretos
/// 2. Intervalos de 5 minutos
/// 3. Horários ocupados não aparecem
void main() {
  group('Validação de Horários - API Backend', () {
    late Dio dio;

    setUp(() {
      dio = Dio(BaseOptions(
        baseUrl: 'http://localhost:7891/api',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
    });

    test('1. Login e obter token', () async {
      final response = await dio.post('/auth/login/', data: {
        'username': 'barbeiro_teste',
        'password': 'teste123',
      });

      expect(response.statusCode, 200);
      expect(response.data['access'], isNotNull);
      
      print('✅ Token obtido: ${response.data['access'].substring(0, 20)}...');
    });

    test('2. Horários disponíveis - Intervalos de 5 minutos', () async {
      // Primeiro fazer login
      final loginResponse = await dio.post('/auth/login/', data: {
        'username': 'barbeiro_teste',
        'password': 'teste123',
      });

      final token = loginResponse.data['access'];

      // Buscar horários disponíveis
      final response = await dio.get(
        '/appointments/available_times/',
        queryParameters: {
          'barber_id': 13,
          'date': '2025-11-01',
          'service_id': 1,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      expect(response.statusCode, 200);
      
      final data = response.data;
      final availableTimes = data['available_times'] as List;
      
      print('📊 Total de horários: ${data['total_slots']}');
      print('📊 Primeiros 10: ${availableTimes.take(10).join(", ")}');

      // VALIDAÇÃO 1: Todos os horários terminam em 0 ou 5
      for (String time in availableTimes) {
        final minute = int.parse(time.split(':')[1]);
        expect(minute % 5, 0, 
          reason: 'Horário $time deve terminar em 0 ou 5');
      }
      
      print('✅ Todos os ${availableTimes.length} horários terminam em 0 ou 5');

      // VALIDAÇÃO 2: Horários específicos devem existir
      final expectedTimes = [
        '08:00', '08:05', '08:10', '08:15', '08:20',
        '09:00', '09:30', '10:00', '12:00', '15:00'
      ];
      
      for (String time in expectedTimes) {
        expect(availableTimes.contains(time), true,
          reason: 'Horário $time deve estar disponível');
      }
      
      print('✅ Horários esperados encontrados');

      // VALIDAÇÃO 3: Horários inválidos NÃO devem existir
      final invalidTimes = [
        '08:03', '08:07', '08:12', '09:17', '10:23'
      ];
      
      for (String time in invalidTimes) {
        expect(availableTimes.contains(time), false,
          reason: 'Horário $time NÃO deve existir');
      }
      
      print('✅ Horários inválidos não encontrados');
    });

    test('3. Horários ocupados não aparecem', () async {
      // Login
      final loginResponse = await dio.post('/auth/login/', data: {
        'username': 'barbeiro_teste',
        'password': 'teste123',
      });

      final token = loginResponse.data['access'];

      // Buscar horários disponíveis
      final response = await dio.get(
        '/appointments/available_times/',
        queryParameters: {
          'barber_id': 13,
          'date': '2025-11-01',
          'service_id': 1,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final availableTimes = List<String>.from(response.data['available_times']);
      
      // Horários que DEVEM estar ocupados (agendamento às 14:00, serviço 30min)
      final occupiedTimes = [
        '13:45', '13:50', '13:55', // conflita
        '14:00', '14:05', '14:10', '14:15', '14:20', '14:25', // ocupado
      ];

      print('\n🔍 Verificando horários ocupados:');
      for (String time in occupiedTimes) {
        final isAvailable = availableTimes.contains(time);
        expect(isAvailable, false,
          reason: 'Horário $time deve estar OCUPADO');
        print('  ❌ $time - OCUPADO (correto)');
      }

      // Horários que DEVEM estar disponíveis
      final availableTimesCheck = ['14:30', '14:35', '14:40', '15:00'];
      
      print('\n🔍 Verificando horários disponíveis:');
      for (String time in availableTimesCheck) {
        final isAvailable = availableTimes.contains(time);
        expect(isAvailable, true,
          reason: 'Horário $time deve estar DISPONÍVEL');
        print('  ✅ $time - DISPONÍVEL (correto)');
      }

      print('\n✅ Horários ocupados calculados corretamente');
      print('📊 Total disponível: ${response.data['total_slots']}');
      print('📊 Esperado: ~145 (156 - 11 ocupados)');
    });

    test('4. Serviços do barbeiro - Listar', () async {
      // Login
      final loginResponse = await dio.post('/auth/login/', data: {
        'username': 'barbeiro_teste',
        'password': 'teste123',
      });

      final token = loginResponse.data['access'];

      // Listar serviços do barbeiro
      final response = await dio.get(
        '/services/barber/my-services/',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      expect(response.statusCode, 200);
      
      final services = response.data as List;
      print('📋 Serviços do barbeiro: ${services.length}');
      
      for (var service in services) {
        print('  - ${service['name']} (${service['duration_minutes']}min, R\$ ${service['price']})');
      }

      expect(services.length, greaterThanOrEqualTo(1),
        reason: 'Barbeiro deve ter pelo menos 1 serviço');
    });

    test('5. Serviços do barbeiro - Adicionar', () async {
      // Login
      final loginResponse = await dio.post('/auth/login/', data: {
        'username': 'barbeiro_teste',
        'password': 'teste123',
      });

      final token = loginResponse.data['access'];

      // Adicionar serviço (Barba Completa - ID 3)
      final response = await dio.post(
        '/services/barber/my-services/',
        data: {'service_id': 3},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      expect(response.statusCode, anyOf([200, 201]));
      expect(response.data['message'], contains('sucesso'));
      
      print('✅ Serviço adicionado: ${response.data['message']}');
    });

    test('6. Serviços do barbeiro - Remover', () async {
      // Login
      final loginResponse = await dio.post('/auth/login/', data: {
        'username': 'barbeiro_teste',
        'password': 'teste123',
      });

      final token = loginResponse.data['access'];

      // Remover serviço (Barba Completa - ID 3)
      final response = await dio.delete(
        '/services/barber/my-services/3/',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      expect(response.statusCode, 200);
      expect(response.data['message'], contains('sucesso'));
      
      print('✅ Serviço removido: ${response.data['message']}');
    });
  });
}
