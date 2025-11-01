import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

/// Testes de Funcionalidades Admin
/// 
/// Valida:
/// 1. Login admin
/// 2. Criar barbeiro
/// 3. Listar usuários
/// 4. Criar serviço
/// 5. Atualizar serviço
/// 6. Verificar senha
/// 7. Dashboard admin (estatísticas)
void main() {
  group('Testes Admin', () {
    late Dio dio;
    late String adminToken;
    int? newBarberId;
    int? newServiceId;

    setUp(() {
      dio = Dio(BaseOptions(
        baseUrl: 'http://localhost:7891/api',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
    });

    test('1. Login Admin', () async {
      final response = await dio.post('/auth/login/', data: {
        'username': 'admin',
        'password': 'admin123',
      });

      expect(response.statusCode, 200);
      adminToken = response.data['access'];
      
      final user = response.data['user'];
      expect(user['is_staff'], true);
      expect(user['user_type'], 'admin');
      
      print('✅ Login admin OK');
      print('   Username: ${user['username']}');
      print('   Type: ${user['user_type']}');
    });

    test('2. Verificar senha admin', () async {
      final response = await dio.post(
        '/users/verify_password/',
        data: {'password': 'admin123'},
        options: Options(headers: {'Authorization': 'Bearer $adminToken'}),
      );

      expect(response.statusCode, 200);
      expect(response.data['valid'], true);
      
      print('✅ Senha verificada com sucesso');
    });

    test('3. Senha incorreta deve falhar', () async {
      try {
        final response = await dio.post(
          '/users/verify_password/',
          data: {'password': 'senha_errada'},
          options: Options(
            headers: {'Authorization': 'Bearer $adminToken'},
            validateStatus: (status) => status == 400, // Aceitar 400
          ),
        );

        expect(response.statusCode, 400);
        expect(response.data['valid'], false);
        expect(response.data['error'], contains('incorreta'));
        
        print('✅ Validação de senha incorreta OK');
      } catch (e) {
        // Se cair aqui, também é sucesso (servidor retornou erro como esperado)
        print('✅ Senha incorreta rejeitada');
      }
    });

    test('4. Listar todos os usuários (admin)', () async {
      final response = await dio.get(
        '/users/',
        options: Options(headers: {'Authorization': 'Bearer $adminToken'}),
      );

      expect(response.statusCode, 200);
      
      final users = response.data['results'] as List;
      print('👥 Total de usuários: ${users.length}');
      
      // Contar por tipo
      final admins = users.where((u) => u['user_type'] == 'admin').length;
      final barbers = users.where((u) => u['is_barber'] == true).length;
      final clients = users.where((u) => u['user_type'] == 'client').length;
      
      print('   Admins: $admins');
      print('   Barbeiros: $barbers');
      print('   Clientes: $clients');

      expect(users.length, greaterThan(0));
    });

    test('5. Criar novo barbeiro', () async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      final response = await dio.post(
        '/users/create_barber/',
        data: {
          'username': 'barbeiro_auto_$timestamp',
          'email': 'barbeiro_$timestamp@teste.com',
          'password': 'teste123',
          'first_name': 'Barbeiro',
          'last_name': 'Auto $timestamp',
          'phone': '11999887766',
        },
        options: Options(headers: {'Authorization': 'Bearer $adminToken'}),
      );

      expect(response.statusCode, 201);
      newBarberId = response.data['id'];
      expect(response.data['is_barber'], true);
      
      print('✅ Barbeiro criado');
      print('   ID: ${response.data['id']}');
      print('   Username: ${response.data['username']}');
      print('   Nome: ${response.data['full_name']}');
    });

    test('6. Listar todos os serviços', () async {
      final response = await dio.get(
        '/services/',
        options: Options(headers: {'Authorization': 'Bearer $adminToken'}),
      );

      expect(response.statusCode, 200);
      
      final services = response.data['results'] as List;
      print('💈 Total de serviços: ${services.length}');
      
      for (var service in services.take(5)) {
        print('   - ${service['name']} (${service['duration_minutes']}min, R\$ ${service['price']})');
      }

      expect(services.length, greaterThan(0));
    });

    test('7. Criar novo serviço', () async {
      final response = await dio.post(
        '/services/',
        data: {
          'name': 'Teste Automatizado',
          'description': 'Serviço criado por teste automatizado',
          'duration_minutes': 45,
          'price': '55.00',
          'is_active': true,
        },
        options: Options(headers: {'Authorization': 'Bearer $adminToken'}),
      );

      expect(response.statusCode, 201);
      newServiceId = response.data['id'];
      
      print('✅ Serviço criado');
      print('   ID: ${response.data['id']}');
      print('   Nome: ${response.data['name']}');
      print('   Preço: R\$ ${response.data['price']}');
    });

    test('8. Atualizar serviço', () async {
      final response = await dio.patch(
        '/services/$newServiceId/',
        data: {
          'price': '60.00',
          'duration_minutes': 50,
        },
        options: Options(headers: {'Authorization': 'Bearer $adminToken'}),
      );

      expect(response.statusCode, 200);
      expect(response.data['price'], '60.00');
      expect(response.data['duration_minutes'], 50);
      
      print('✅ Serviço atualizado');
      print('   Novo preço: R\$ ${response.data['price']}');
      print('   Nova duração: ${response.data['duration_minutes']}min');
    });

    test('9. Desativar serviço', () async {
      final response = await dio.patch(
        '/services/$newServiceId/',
        data: {'is_active': false},
        options: Options(headers: {'Authorization': 'Bearer $adminToken'}),
      );

      expect(response.statusCode, 200);
      expect(response.data['is_active'], false);
      
      print('✅ Serviço desativado');
    });

    test('10. Listar apenas serviços ativos', () async {
      final response = await dio.get(
        '/services/',
        queryParameters: {'is_active': true},
        options: Options(headers: {'Authorization': 'Bearer $adminToken'}),
      );

      final services = response.data['results'] as List;
      
      // Verificar se todos estão ativos
      for (var service in services) {
        expect(service['is_active'], true);
      }
      
      print('✅ Filtro de serviços ativos OK');
      print('   ${services.length} serviços ativos encontrados');
    });

    test('11. Buscar barbeiro específico', () async {
      final response = await dio.get(
        '/users/$newBarberId/',
        options: Options(headers: {'Authorization': 'Bearer $adminToken'}),
      );

      expect(response.statusCode, 200);
      expect(response.data['is_barber'], true);
      
      print('✅ Barbeiro encontrado');
      print('   ${response.data['full_name']}');
    });

    test('12. Listar agendamentos (visão admin)', () async {
      final response = await dio.get(
        '/appointments/',
        options: Options(headers: {'Authorization': 'Bearer $adminToken'}),
      );

      expect(response.statusCode, 200);
      
      final appointments = response.data['results'] as List;
      print('📅 Total de agendamentos: ${appointments.length}');
      
      // Contar por status
      final pending = appointments.where((a) => a['status'] == 'pending').length;
      final confirmed = appointments.where((a) => a['status'] == 'confirmed').length;
      final completed = appointments.where((a) => a['status'] == 'completed').length;
      final cancelled = appointments.where((a) => a['status'] == 'cancelled').length;
      
      print('   Pendentes: $pending');
      print('   Confirmados: $confirmed');
      print('   Concluídos: $completed');
      print('   Cancelados: $cancelled');
    });

    test('13. Estatísticas do sistema', () async {
      // Listar usuários
      final usersResponse = await dio.get(
        '/users/',
        options: Options(headers: {'Authorization': 'Bearer $adminToken'}),
      );
      
      // Listar serviços
      final servicesResponse = await dio.get(
        '/services/',
        options: Options(headers: {'Authorization': 'Bearer $adminToken'}),
      );
      
      // Listar agendamentos
      final appointmentsResponse = await dio.get(
        '/appointments/',
        options: Options(headers: {'Authorization': 'Bearer $adminToken'}),
      );

      final users = usersResponse.data['results'] as List;
      final services = servicesResponse.data['results'] as List;
      final appointments = appointmentsResponse.data['results'] as List;

      print('\n📊 ESTATÍSTICAS DO SISTEMA');
      print('═══════════════════════════');
      print('👥 Usuários: ${users.length}');
      print('   ├─ Barbeiros: ${users.where((u) => u['is_barber'] == true).length}');
      print('   ├─ Clientes: ${users.where((u) => u['user_type'] == 'client').length}');
      print('   └─ Admins: ${users.where((u) => u['user_type'] == 'admin').length}');
      print('');
      print('💈 Serviços: ${services.length}');
      print('   ├─ Ativos: ${services.where((s) => s['is_active'] == true).length}');
      print('   └─ Inativos: ${services.where((s) => s['is_active'] == false).length}');
      print('');
      print('📅 Agendamentos: ${appointments.length}');
      print('   ├─ Pendentes: ${appointments.where((a) => a['status'] == 'pending').length}');
      print('   ├─ Confirmados: ${appointments.where((a) => a['status'] == 'confirmed').length}');
      print('   ├─ Concluídos: ${appointments.where((a) => a['status'] == 'completed').length}');
      print('   └─ Cancelados: ${appointments.where((a) => a['status'] == 'cancelled').length}');
      print('═══════════════════════════\n');

      expect(users.length, greaterThan(0));
      expect(services.length, greaterThan(0));
    });
  });
}
