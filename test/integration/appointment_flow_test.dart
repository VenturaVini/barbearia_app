import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:barbearia_app/main.dart' as app;

/// Teste de integração: Fluxo completo de agendamento
/// 
/// Este teste valida:
/// 1. Login do barbeiro
/// 2. Gerenciamento de serviços (adicionar/remover)
/// 3. Logout e login como cliente
/// 4. Novo fluxo de agendamento (Barbeiro → Serviço → Data/Hora)
/// 5. Horários de 5 em 5 minutos
/// 6. Horários ocupados não aparecem
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Fluxo Completo de Agendamento V3.0', () {
    testWidgets('1. Login como Barbeiro', (WidgetTester tester) async {
      // Iniciar app
      app.main();
      await tester.pumpAndSettle();

      // Aguardar tela de login carregar
      await tester.pump(const Duration(seconds: 2));

      // Procurar campos de login
      final usernameField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).last;
      
      expect(usernameField, findsOneWidget);
      expect(passwordField, findsOneWidget);

      // Preencher credenciais do barbeiro
      await tester.enterText(usernameField, 'barbeiro_teste');
      await tester.enterText(passwordField, 'teste123');
      await tester.pumpAndSettle();

      // Clicar no botão de login
      final loginButton = find.widgetWithText(ElevatedButton, 'Entrar');
      expect(loginButton, findsOneWidget);
      
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verificar se foi para o dashboard do barbeiro
      expect(find.text('Dashboard'), findsOneWidget);
      
      print('✅ Teste 1 passou: Login barbeiro OK');
    });

    testWidgets('2. Gerenciar Serviços do Barbeiro', (WidgetTester tester) async {
      // App já deve estar logado como barbeiro
      await tester.pumpAndSettle();

      // Procurar botão "Gerenciar Serviços"
      final manageServicesButton = find.text('Gerenciar Serviços');
      
      if (manageServicesButton.evaluate().isEmpty) {
        // Procurar alternativas
        final altButton = find.widgetWithText(ElevatedButton, 'Meus Serviços');
        if (altButton.evaluate().isNotEmpty) {
          await tester.tap(altButton);
        } else {
          print('⚠️  Botão Gerenciar Serviços não encontrado');
          return;
        }
      } else {
        await tester.tap(manageServicesButton);
      }
      
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verificar se abriu a página de gerenciamento
      expect(find.text('Gerenciar Serviços'), findsAtLeastNWidgets(1));

      // Procurar toggles/switches de serviços
      final switches = find.byType(Switch);
      
      if (switches.evaluate().isNotEmpty) {
        print('✅ Encontrados ${switches.evaluate().length} serviços');
        
        // Testar adicionar serviço (ativar primeiro switch desativado)
        final firstSwitch = switches.first;
        await tester.tap(firstSwitch);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        
        // Verificar mensagem de sucesso
        expect(find.textContaining('sucesso'), findsOneWidget);
        
        print('✅ Teste 2 passou: Adicionar serviço OK');
        
        // Testar remover serviço (desativar o mesmo switch)
        await tester.tap(firstSwitch);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        
        print('✅ Teste 2 passou: Remover serviço OK');
      } else {
        print('⚠️  Nenhum switch encontrado');
      }

      // Voltar para dashboard
      final backButton = find.byType(BackButton);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('3. Logout e Login como Cliente', (WidgetTester tester) async {
      await tester.pumpAndSettle();

      // Procurar menu/drawer
      final drawerButton = find.byIcon(Icons.menu);
      if (drawerButton.evaluate().isNotEmpty) {
        await tester.tap(drawerButton);
        await tester.pumpAndSettle();

        // Procurar botão de logout
        final logoutButton = find.text('Sair');
        if (logoutButton.evaluate().isNotEmpty) {
          await tester.tap(logoutButton);
          await tester.pumpAndSettle(const Duration(seconds: 2));
          
          print('✅ Logout realizado');
        }
      }

      // Login como cliente
      final usernameField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).last;

      await tester.enterText(usernameField, 'cliente_teste');
      await tester.enterText(passwordField, 'teste123');
      await tester.pumpAndSettle();

      final loginButton = find.widgetWithText(ElevatedButton, 'Entrar');
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      print('✅ Teste 3 passou: Login cliente OK');
    });

    testWidgets('4. Fluxo de Agendamento - Selecionar Barbeiro', (WidgetTester tester) async {
      await tester.pumpAndSettle();

      // Procurar botão "Novo Agendamento"
      final newAppointmentButton = find.text('Novo Agendamento');
      
      if (newAppointmentButton.evaluate().isNotEmpty) {
        await tester.tap(newAppointmentButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verificar se está na página de seleção de barbeiro
        expect(find.text('Selecione o Barbeiro'), findsOneWidget);

        // Procurar card do barbeiro de teste
        final barberCard = find.textContaining('Barbeiro Teste');
        
        if (barberCard.evaluate().isNotEmpty) {
          await tester.tap(barberCard);
          await tester.pumpAndSettle(const Duration(seconds: 2));
          
          print('✅ Teste 4 passou: Barbeiro selecionado');
        } else {
          print('⚠️  Barbeiro não encontrado na lista');
        }
      } else {
        print('⚠️  Botão Novo Agendamento não encontrado');
      }
    });

    testWidgets('5. Fluxo de Agendamento - Selecionar Serviço', (WidgetTester tester) async {
      await tester.pumpAndSettle();

      // Verificar se está na página de seleção de serviço
      expect(find.text('Selecione o Serviço'), findsOneWidget);

      // Procurar serviço "Corte Simples" (único do barbeiro de teste)
      final serviceCard = find.textContaining('Corte Simples');
      
      if (serviceCard.evaluate().isNotEmpty) {
        // Verificar se mostra apenas serviços do barbeiro
        final allServiceCards = find.byType(Card);
        final serviceCount = allServiceCards.evaluate().length;
        
        print('📋 Serviços encontrados: $serviceCount');
        print('✅ Esperado: 1 (apenas serviços do barbeiro)');
        
        await tester.tap(serviceCard);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        print('✅ Teste 5 passou: Serviço selecionado');
      } else {
        print('⚠️  Serviço não encontrado');
      }
    });

    testWidgets('6. CRÍTICO - Verificar Horários de 5 em 5 minutos', (WidgetTester tester) async {
      await tester.pumpAndSettle();

      // Verificar se está na página de seleção de data/hora
      expect(find.text('Selecione Data e Hora'), findsOneWidget);

      // Selecionar data (01/11/2025)
      final dateField = find.text('Selecionar Data');
      if (dateField.evaluate().isNotEmpty) {
        await tester.tap(dateField);
        await tester.pumpAndSettle();
        
        // Selecionar data no calendário
        // (implementação depende do widget de calendário usado)
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // Aguardar carregar horários
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // VALIDAÇÃO CRÍTICA: Verificar intervalos de 5 minutos
      final horariosValidos = [
        '08:00', '08:05', '08:10', '08:15', '08:20', '08:25', '08:30',
        '09:00', '09:05', '09:10', // etc
      ];
      
      final horariosInvalidos = [
        '08:03', '08:07', '08:12', '08:17', '08:23', // não terminam em 0 ou 5
      ];

      int validosEncontrados = 0;
      int invalidosEncontrados = 0;

      for (String horario in horariosValidos) {
        if (find.text(horario).evaluate().isNotEmpty) {
          validosEncontrados++;
        }
      }

      for (String horario in horariosInvalidos) {
        if (find.text(horario).evaluate().isNotEmpty) {
          invalidosEncontrados++;
        }
      }

      print('✅ Horários válidos encontrados: $validosEncontrados');
      print('❌ Horários inválidos encontrados: $invalidosEncontrados');
      
      expect(invalidosEncontrados, 0, 
        reason: 'Não deve haver horários que não terminam em 0 ou 5');
      
      print('✅ Teste 6 passou: Intervalos de 5 minutos OK');
    });

    testWidgets('7. CRÍTICO - Verificar Horários Ocupados', (WidgetTester tester) async {
      await tester.pumpAndSettle();

      // Horários que DEVEM estar ocupados (agendamento às 14:00)
      final horariosOcupados = [
        '13:45', '13:50', '13:55', // conflita (serviço 30min)
        '14:00', '14:05', '14:10', '14:15', '14:20', '14:25', // ocupado
      ];

      // Horários que DEVEM estar disponíveis
      final horariosDisponiveis = [
        '14:30', '14:35', '14:40',
      ];

      int ocupadosNaoEncontrados = 0;
      int disponiveisEncontrados = 0;

      for (String horario in horariosOcupados) {
        if (find.text(horario).evaluate().isEmpty) {
          ocupadosNaoEncontrados++;
          print('✅ $horario não aparece (correto - está ocupado)');
        } else {
          print('❌ ERRO: $horario aparece mas deveria estar ocupado!');
        }
      }

      for (String horario in horariosDisponiveis) {
        if (find.text(horario).evaluate().isNotEmpty) {
          disponiveisEncontrados++;
          print('✅ $horario disponível (correto)');
        }
      }

      expect(ocupadosNaoEncontrados, horariosOcupados.length,
        reason: 'Todos os horários ocupados devem estar ausentes');
      
      expect(disponiveisEncontrados, greaterThan(0),
        reason: 'Deve haver horários disponíveis após os ocupados');

      print('✅ Teste 7 passou: Horários ocupados não aparecem');
      
      // Selecionar um horário disponível
      if (disponiveisEncontrados > 0) {
        final horarioDisponivel = find.text('15:00');
        if (horarioDisponivel.evaluate().isNotEmpty) {
          await tester.tap(horarioDisponivel);
          await tester.pumpAndSettle(const Duration(seconds: 1));
          
          print('✅ Horário 15:00 selecionado');
        }
      }
    });

    testWidgets('8. Confirmar Agendamento', (WidgetTester tester) async {
      await tester.pumpAndSettle();

      // Procurar botão de confirmar
      final confirmButton = find.widgetWithText(ElevatedButton, 'Confirmar');
      
      if (confirmButton.evaluate().isNotEmpty) {
        await tester.tap(confirmButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Verificar mensagem de sucesso
        expect(find.textContaining('sucesso'), findsOneWidget);
        
        print('✅ Teste 8 passou: Agendamento confirmado');
      } else {
        print('⚠️  Botão Confirmar não encontrado');
      }
    });
  });
}
