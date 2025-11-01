import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../shared/utils/date_utils.dart' as app_date_utils;
import '../auth/presentation/bloc/auth_bloc.dart';
import '../auth/presentation/bloc/auth_event.dart';
import '../auth/presentation/bloc/auth_state.dart';
import '../appointments/select_barber_first_page.dart';
import 'appointments_history_page.dart';
import 'edit_profile_page.dart';

/// Dashboard do Cliente
class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ClientHomePage(),
    const AppointmentsHistoryPage(),
    const ClientProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.textMuted,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Agendamentos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

/// Home do Cliente
class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  Map<String, dynamic>? _nextAppointment;
  bool _isLoadingAppointment = true;

  @override
  void initState() {
    super.initState();
    _loadNextAppointment();
  }

  Future<void> _loadNextAppointment() async {
    setState(() => _isLoadingAppointment = true);
    try {
      final response = await DioClient.get('/appointments/');
      
      // Verificar se a resposta é uma lista ou um objeto paginado
      List appointments;
      if (response.data is List) {
        appointments = response.data as List;
      } else if (response.data is Map && response.data['results'] != null) {
        // Resposta paginada do Django
        appointments = response.data['results'] as List;
      } else {
        print('⚠️ [ClientDashboard] Formato de resposta inesperado: ${response.data.runtimeType}');
        appointments = [];
      }
      
      print('🔵 [ClientDashboard] Total de agendamentos: ${appointments.length}');
      
      // Filtrar agendamentos futuros com status pending ou confirmed
      final now = DateTime.now();
      final futureAppointments = appointments.where((apt) {
        final scheduledFor = app_date_utils.AppDateUtils.parseFromBackend(apt['scheduled_for']);
        final status = apt['status'];
        final isFuture = scheduledFor.isAfter(now);
        final validStatus = (status == 'pending' || status == 'confirmed');
        
        print('📅 Agendamento ID ${apt['id']}: $scheduledFor | Status: $status | Futuro: $isFuture | Status válido: $validStatus');
        
        return isFuture && validStatus;
      }).toList();

      print('✅ [ClientDashboard] Agendamentos futuros encontrados: ${futureAppointments.length}');

      // Ordenar por data mais próxima
      futureAppointments.sort((a, b) {
        final dateA = app_date_utils.AppDateUtils.parseFromBackend(a['scheduled_for']);
        final dateB = app_date_utils.AppDateUtils.parseFromBackend(b['scheduled_for']);
        return dateA.compareTo(dateB);
      });

      setState(() {
        _nextAppointment = futureAppointments.isNotEmpty ? futureAppointments.first : null;
        _isLoadingAppointment = false;
      });
      
      if (_nextAppointment != null) {
        print('🎯 [ClientDashboard] Próximo agendamento: ${_nextAppointment!['service_name']} em ${_nextAppointment!['scheduled_for']}');
      } else {
        print('⚠️ [ClientDashboard] Nenhum agendamento ativo encontrado');
      }
    } catch (e) {
      print('❌ [ClientDashboard] Erro ao carregar agendamentos: $e');
      setState(() {
        _nextAppointment = null;
        _isLoadingAppointment = false;
      });
    }
  }

  Future<void> _cancelAppointment(int appointmentId) async {
    try {
      await DioClient.patch('/appointments/$appointmentId/cancel/');
      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Agendamento cancelado com sucesso');
        _loadNextAppointment(); // Recarregar
      }
    } on ApiException catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, e.message);
      }
    }
  }

  Future<void> _rescheduleAppointment(int appointmentId, String serviceName) async {
    // Mostrar diálogo de confirmação com 3 opções
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reagendar Atendimento'),
        content: Text(
          'O que deseja fazer com o agendamento de $serviceName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel_only'),
            child: const Text('Apenas Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'reschedule'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.primaryDark,
            ),
            child: const Text('Reagendar'),
          ),
        ],
      ),
    );

    if (result == null) return;

    if (result == 'cancel_only') {
      // Apenas cancelar
      await _cancelAppointment(appointmentId);
    } else if (result == 'reschedule') {
      // Cancelar e ir para agendamento
      try {
        await DioClient.patch('/appointments/$appointmentId/cancel/');
        if (mounted) {
          SnackBarUtils.showSuccess(context, 'Agendamento cancelado. Escolha um novo barbeiro.');
          
          // Navegar para tela de seleção de barbeiro
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SelectBarberFirstPage(),
            ),
          ).then((_) {
            _loadNextAppointment();
          });
        }
      } on ApiException catch (e) {
        if (mounted) {
          SnackBarUtils.showError(context, e.message);
        }
      }
    }
  }

  Future<void> _refreshAll() async {
    await _loadNextAppointment();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barbearia Premium'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implementar notificações
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            final user = state.user;
            return RefreshIndicator(
              onRefresh: _refreshAll,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Saudação
                    Text(
                      'Olá, ${user.firstName ?? user.username}! 👋',
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pronto para um novo visual?',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Agendamento Ativo (substitui próximo agendamento e serviços favoritos)
                    _buildActiveAppointmentSection(context),
                    const SizedBox(height: 24),

                    // Ações Rápidas
                    Text(
                      'Ações Rápidas',
                      style: AppTextStyles.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    _buildQuickActions(context),
                  ],
                ),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  // Novo método unificado para a seção de agendamento ativo
  Widget _buildActiveAppointmentSection(BuildContext context) {
    if (_isLoadingAppointment) {
      return const Card(
        color: AppColors.surface,
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_nextAppointment == null) {
      // Sem agendamento ativo - mostrar mensagem e botão
      return Card(
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.event_available,
                size: 64,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum agendamento ativo',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Agende seu próximo corte agora!',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SelectBarberFirstPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.all(16),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Novo Agendamento',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // TEM agendamento ativo - mostrar detalhes completos
    final scheduledFor = app_date_utils.AppDateUtils.parseFromBackend(_nextAppointment!['scheduled_for']);
    final serviceName = _nextAppointment!['service_name'];
    final barberName = _nextAppointment!['barber_name'];
    final status = _nextAppointment!['status'];
    final appointmentId = _nextAppointment!['id'];
    
    // Calcular tempo restante
    final now = DateTime.now();
    final difference = scheduledFor.difference(now);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        Text(
          'Seu Próximo Serviço',
          style: AppTextStyles.headlineMedium,
        ),
        const SizedBox(height: 16),

        // Card principal do agendamento
        Card(
          color: AppColors.surface,
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho com serviço e status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.content_cut,
                        color: AppColors.gold,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            serviceName,
                            style: AppTextStyles.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: status == 'confirmed' 
                                  ? Colors.blue.withOpacity(0.2)
                                  : Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status == 'confirmed' ? 'Confirmado' : 'Pendente',
                              style: TextStyle(
                                color: status == 'confirmed' ? Colors.blue : Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const Divider(height: 32),

                // Data e Hora
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('EEEE, dd \'de\' MMMM', 'pt_BR').format(scheduledFor),
                      style: AppTextStyles.bodyLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('HH:mm', 'pt_BR').format(scheduledFor),
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.person, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Text(
                      barberName,
                      style: AppTextStyles.bodyLarge,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Contagem regressiva
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.gold.withOpacity(0.2),
                        AppColors.gold.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer, color: AppColors.gold),
                      const SizedBox(width: 8),
                      Text(
                        _formatTimeRemaining(difference),
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Botões de ação
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rescheduleAppointment(appointmentId, serviceName),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.gold),
                          padding: const EdgeInsets.all(12),
                        ),
                        icon: const Icon(Icons.edit_calendar, color: AppColors.gold),
                        label: const Text(
                          'Reagendar',
                          style: TextStyle(color: AppColors.gold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showCancelDialog(appointmentId, serviceName),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.all(12),
                        ),
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        label: const Text(
                          'Cancelar',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimeRemaining(Duration difference) {
    if (difference.isNegative) {
      return 'Agendamento passou';
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    if (days > 0) {
      return 'Faltam $days dia${days > 1 ? 's' : ''} e $hours hora${hours != 1 ? 's' : ''}';
    } else if (hours > 0) {
      return 'Faltam $hours hora${hours != 1 ? 's' : ''} e $minutes minuto${minutes != 1 ? 's' : ''}';
    } else {
      return 'Faltam $minutes minuto${minutes != 1 ? 's' : ''}';
    }
  }

  Future<void> _showCancelDialog(int appointmentId, String serviceName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Agendamento'),
        content: Text(
          'Tem certeza que deseja cancelar o agendamento de $serviceName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Sim, Cancelar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _cancelAppointment(appointmentId);
    }
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.calendar_month,
            title: 'Agendar',
            color: AppColors.gold,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SelectBarberFirstPage(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.history,
            title: 'Histórico',
            color: Colors.blue,
            onTap: () {
              // Navegar para aba de agendamentos (index 1)
              final dashboardState = context.findAncestorStateOfType<_ClientDashboardState>();
              dashboardState?.setState(() {
                dashboardState._selectedIndex = 1;
              });
            },
          ),
        ),
      ],
    );
  }
}

/// Card de Ação Rápida
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Página de Serviços do Cliente
class ClientServicesPage extends StatefulWidget {
  const ClientServicesPage({super.key});

  @override
  State<ClientServicesPage> createState() => _ClientServicesPageState();
}

class _ClientServicesPageState extends State<ClientServicesPage> {
  List<dynamic> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await DioClient.get('/services/');
      setState(() {
        _services = response.data as List;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, e.message);
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          'Erro ao carregar serviços',
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nossos Serviços'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _services.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.content_cut,
                        size: 64,
                        color: Colors.white24,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nenhum serviço disponível',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadServices,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _services.length,
                    itemBuilder: (context, index) {
                      final service = _services[index] as Map<String, dynamic>;
                      return Card(
                        color: AppColors.surface,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.gold,
                            child: const Icon(
                              Icons.content_cut,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          title: Text(
                            service['name'] ?? '',
                            style: AppTextStyles.titleMedium,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              if (service['description'] != null &&
                                  service['description'].toString().isNotEmpty)
                                Text(
                                  service['description'],
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${service['duration'] ?? 0} min',
                                    style: AppTextStyles.caption,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    service['category'] ?? 'Geral',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.gold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Text(
                            'R\$ ${service['price'] ?? '0.00'}',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(service['name'] ?? ''),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (service['description'] != null &&
                                        service['description']
                                            .toString()
                                            .isNotEmpty) ...[
                                      Text(service['description']),
                                      const SizedBox(height: 16),
                                    ],
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                            'Duração: ${service['duration'] ?? 0} min'),
                                        Text(
                                          'R\$ ${service['price'] ?? '0.00'}',
                                          style: const TextStyle(
                                            color: AppColors.gold,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Fechar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      // TODO: Implementar fluxo de agendamento
                                      SnackBarUtils.showInfo(
                                        context,
                                        'Funcionalidade de agendamento em desenvolvimento',
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.gold,
                                      foregroundColor: Colors.black,
                                    ),
                                    child: const Text('Agendar'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

/// Página de Agendamentos do Cliente
/// Página de Perfil do Cliente
class ClientProfilePage extends StatelessWidget {
  const ClientProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        actions: [
          // Botão de editar perfil
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar Perfil',
            onPressed: () {
              final authState = context.read<AuthBloc>().state;
              if (authState is Authenticated) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(user: authState.user),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            final user = state.user;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.gold,
                    backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                        ? Text(
                            user.fullName[0].toUpperCase(),
                            style: AppTextStyles.displayLarge.copyWith(
                              color: AppColors.primaryDark,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.fullName,
                    style: AppTextStyles.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Informações
                  _buildInfoCard(
                    icon: Icons.person,
                    title: 'Usuário',
                    subtitle: user.username,
                  ),
                  _buildInfoCard(
                    icon: Icons.phone,
                    title: 'Telefone',
                    subtitle: user.phone ?? 'Não informado',
                  ),
                  _buildInfoCard(
                    icon: Icons.badge,
                    title: 'Tipo',
                    subtitle: user.userType == 'client' ? 'Cliente' : user.userType,
                  ),
                  const SizedBox(height: 32),

                  // Botão de Editar Perfil
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfilePage(user: user),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.gold),
                        padding: const EdgeInsets.all(16),
                      ),
                      icon: const Icon(Icons.edit, color: AppColors.gold),
                      label: const Text(
                        'Editar Perfil',
                        style: TextStyle(color: AppColors.gold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Botão de Logout
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<AuthBloc>().add(LogoutRequested());
                        Navigator.of(context).pushReplacementNamed('/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.all(16),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text('Sair'),
                    ),
                  ),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppColors.gold),
        title: Text(title, style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textMuted,
        )),
        subtitle: Text(subtitle, style: AppTextStyles.titleMedium),
      ),
    );
  }
}
