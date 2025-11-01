import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../shared/utils/date_utils.dart' as app_date_utils;
import '../auth/presentation/bloc/auth_bloc.dart';
import '../auth/presentation/bloc/auth_event.dart';
import '../auth/presentation/bloc/auth_state.dart';
import 'manage_availability_page.dart';
import 'manage_barber_services_page.dart';
import 'edit_barber_profile_page.dart';

/// Dashboard do Barbeiro
class BarberDashboard extends StatefulWidget {
  const BarberDashboard({super.key});

  @override
  State<BarberDashboard> createState() => _BarberDashboardState();
}

class _BarberDashboardState extends State<BarberDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const BarberHomePage(),
    const BarberSchedulePage(),
    const BarberProfilePage(),
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
            icon: Icon(Icons.dashboard),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Agenda',
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

/// Home do Barbeiro
class BarberHomePage extends StatefulWidget {
  const BarberHomePage({super.key});

  @override
  State<BarberHomePage> createState() => _BarberHomePageState();
}

class _BarberHomePageState extends State<BarberHomePage> {
  int _totalToday = 0;
  int _completed = 0;
  int _pending = 0;
  List<dynamic> _upcomingAppointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayStats();
  }

  String _formatDateToApi(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _loadTodayStats() async {
    setState(() => _isLoading = true);
    try {
      final today = _formatDateToApi(DateTime.now());
      final response = await DioClient.get('/appointments/barber_schedule/?date=$today');
      final appointments = response.data as List;

      // Calcular estatísticas
      int completed = 0;
      int pending = 0;
      
      for (var apt in appointments) {
        if (apt['status'] == 'completed') {
          completed++;
        } else if (apt['status'] == 'pending' || apt['status'] == 'confirmed') {
          pending++;
        }
      }

      // Filtrar próximos atendimentos (ainda não concluídos)
      final now = DateTime.now();
      final upcoming = appointments.where((apt) {
        final scheduledFor = app_date_utils.AppDateUtils.parseFromBackend(apt['scheduled_for']);
        return scheduledFor.isAfter(now) && apt['status'] != 'completed' && apt['status'] != 'cancelled';
      }).toList();

      // Ordenar por horário
      upcoming.sort((a, b) {
        final dateA = app_date_utils.AppDateUtils.parseFromBackend(a['scheduled_for']);
        final dateB = app_date_utils.AppDateUtils.parseFromBackend(b['scheduled_for']);
        return dateA.compareTo(dateB);
      });

      setState(() {
        _totalToday = appointments.length;
        _completed = completed;
        _pending = pending;
        _upcomingAppointments = upcoming.take(3).toList(); // Mostrar apenas os 3 próximos
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _totalToday = 0;
        _completed = 0;
        _pending = 0;
        _upcomingAppointments = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel do Barbeiro'),
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
              onRefresh: _loadTodayStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Saudação
                    Text(
                      'Olá, ${user.firstName ?? user.username}! ✂️',
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vamos atender bem hoje!',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Estatísticas do Dia
                    _buildDayStats(),
                    const SizedBox(height: 24),

                    // Próximos Atendimentos
                    Text(
                      'Próximos Atendimentos',
                      style: AppTextStyles.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    _buildUpcomingAppointments(),
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

  Widget _buildDayStats() {
    if (_isLoading) {
      return const Card(
        color: AppColors.surface,
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estatísticas de Hoje',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatCard(
                  icon: Icons.check_circle,
                  value: _completed.toString(),
                  label: 'Concluídos',
                  color: Colors.green,
                ),
                _StatCard(
                  icon: Icons.pending,
                  value: _pending.toString(),
                  label: 'Pendentes',
                  color: Colors.orange,
                ),
                _StatCard(
                  icon: Icons.event_available,
                  value: _totalToday.toString(),
                  label: 'Agendados',
                  color: AppColors.gold,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    if (_isLoading) {
      return const Card(
        color: AppColors.surface,
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_upcomingAppointments.isEmpty) {
      return Card(
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(
                Icons.calendar_month,
                size: 48,
                color: AppColors.gold,
              ),
              const SizedBox(height: 12),
              Text(
                'Nenhum agendamento próximo',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _upcomingAppointments.map((appointment) {
        final scheduledFor = app_date_utils.AppDateUtils.parseFromBackend(appointment['scheduled_for']);
        final status = appointment['status'];
        final appointmentId = appointment['id'];
        
        // Só permite swipe se status for 'pending'
        if (status != 'pending') {
          return Card(
            color: AppColors.surface,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getStatusColor(status).withOpacity(0.2),
                child: Icon(
                  Icons.schedule,
                  color: _getStatusColor(status),
                ),
              ),
              title: Text(
                _formatTime(scheduledFor),
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(appointment['client_name']),
                  Text(
                    appointment['service_name'],
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusLabel(status),
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }
        
        // Card com swipe para status 'pending'
        return Dismissible(
          key: Key('appointment_$appointmentId'),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
              // Swipe DIREITA→ESQUERDA: Confirmar
              return await _showConfirmSwipeDialog(
                context,
                'Confirmar Atendimento',
                'Deseja confirmar este atendimento?',
                'Confirmar',
                Colors.green,
                () => _updateAppointmentStatusFromSwipe(appointmentId, 'confirmed'),
              );
            } else if (direction == DismissDirection.startToEnd) {
              // Swipe ESQUERDA→DIREITA: Cancelar
              return await _showConfirmSwipeDialog(
                context,
                'Cancelar Atendimento',
                'Deseja cancelar este atendimento?',
                'Cancelar',
                Colors.red,
                () => _updateAppointmentStatusFromSwipe(appointmentId, 'cancelled'),
              );
            }
            return false;
          },
          background: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cancel, color: Colors.white, size: 32),
                SizedBox(height: 4),
                Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          secondaryBackground: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 32),
                SizedBox(height: 4),
                Text(
                  'Confirmar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          child: Card(
            color: AppColors.surface,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getStatusColor(status).withOpacity(0.2),
                child: Icon(
                  Icons.schedule,
                  color: _getStatusColor(status),
                ),
              ),
              title: Text(
                _formatTime(scheduledFor),
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(appointment['client_name']),
                  Text(
                    appointment['service_name'],
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusLabel(status),
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pendente';
      case 'confirmed':
        return 'Confirmado';
      case 'completed':
        return 'Concluído';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  // Diálogo de confirmação para swipe
  Future<bool> _showConfirmSwipeDialog(
    BuildContext context,
    String title,
    String message,
    String actionText,
    Color actionColor,
    VoidCallback onConfirm,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          title,
          style: TextStyle(color: actionColor),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
            ),
            child: Text(actionText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // Atualiza status do agendamento pelo swipe
  Future<void> _updateAppointmentStatusFromSwipe(
    int appointmentId,
    String newStatus,
  ) async {
    try {
      await DioClient.patch(
        '/appointments/$appointmentId/',
        data: {'status': newStatus},
      );

      if (mounted) {
        String message = '✓ Agendamento atualizado';
        if (newStatus == 'confirmed') {
          message = '✅ Atendimento confirmado!';
        } else if (newStatus == 'cancelled') {
          message = '❌ Atendimento cancelado';
        }
        
        SnackBarUtils.showSuccess(context, message);
        await _loadTodayStats(); // Recarrega os dados
      }
    } on ApiException catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Erro ao atualizar agendamento');
      }
    }
  }
}

/// Card de Estatística
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.headlineMedium.copyWith(color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

/// Página de Agenda do Barbeiro
class BarberSchedulePage extends StatefulWidget {
  const BarberSchedulePage({super.key});

  @override
  State<BarberSchedulePage> createState() => _BarberSchedulePageState();
}

class _BarberSchedulePageState extends State<BarberSchedulePage> {
  List<dynamic> _appointments = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  String _selectedFilter = 'pending'; // Filtro padrão: Pendentes

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  List<dynamic> get _filteredAppointments {
    if (_selectedFilter == 'all') {
      return _appointments;
    }
    return _appointments.where((apt) => apt['status'] == _selectedFilter).toList();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Formatar data para o backend (YYYY-MM-DD)
      final dateStr = _formatDateToApi(_selectedDate);
      final response = await DioClient.get('/appointments/barber_schedule/?date=$dateStr');
      
      setState(() {
        _appointments = response.data as List;
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
        SnackBarUtils.showError(context, 'Erro ao carregar agendamentos');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadAppointments();
  }

  String _formatDateFull(DateTime date) {
    final weekday = _getWeekdayName(date.weekday);
    final day = date.day.toString().padLeft(2, '0');
    final month = _getMonthName(date.month);
    return '$weekday, $day $month';
  }

  String _getWeekdayName(int weekday) {
    const weekdays = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
    return weekdays[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = ['janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
                    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'];
    return months[month - 1];
  }

  String _formatDateToApi(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatDateBr(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = _formatDateFull(_selectedDate);
    final isToday = _formatDateToApi(_selectedDate) == _formatDateToApi(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Agenda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
          ),
        ],
      ),
      body: Column(
        children: [
          // Seletor de Data
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeDate(-1),
                ),
                Column(
                  children: [
                    Text(
                      isToday ? 'Hoje' : dateFormatted,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.gold,
                      ),
                    ),
                    Text(
                      _formatDateBr(_selectedDate),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeDate(1),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Filtro de Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.primaryDark,
            child: Row(
              children: [
                const Icon(Icons.filter_list, color: AppColors.gold, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Filtrar por:',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedFilter,
                        isExpanded: true,
                        dropdownColor: AppColors.surface,
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.gold),
                        items: const [
                          DropdownMenuItem(
                            value: 'pending',
                            child: Text('Pendentes'),
                          ),
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('Todos'),
                          ),
                          DropdownMenuItem(
                            value: 'confirmed',
                            child: Text('Confirmados'),
                          ),
                          DropdownMenuItem(
                            value: 'completed',
                            child: Text('Concluídos'),
                          ),
                          DropdownMenuItem(
                            value: 'cancelled',
                            child: Text('Cancelados'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedFilter = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Lista de Agendamentos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAppointments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_available,
                              size: 64,
                              color: Colors.white24,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedFilter == 'all'
                                  ? (isToday 
                                      ? 'Nenhum agendamento para hoje'
                                      : 'Nenhum agendamento para esta data')
                                  : 'Nenhum agendamento ${_getFilterLabel(_selectedFilter).toLowerCase()}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAppointments,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredAppointments.length,
                          itemBuilder: (context, index) {
                            final appointment = _filteredAppointments[index] as Map<String, dynamic>;
                            return _buildAppointmentCard(appointment);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'all':
        return 'Todos';
      case 'pending':
        return 'Pendente';
      case 'confirmed':
        return 'Confirmado';
      case 'completed':
        return 'Concluído';
      case 'cancelled':
        return 'Cancelado';
      default:
        return '';
    }
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final scheduledFor = app_date_utils.AppDateUtils.parseFromBackend(appointment['scheduled_for']);
    final time = _formatTime(scheduledFor);
    final status = appointment['status'] ?? 'pending';
    final appointmentId = appointment['id'];
    
    // Verificar se o agendamento já passou e deve ser auto-concluído
    final now = DateTime.now();
    final duration = appointment['service_duration'] ?? 30;
    final endTime = scheduledFor.add(Duration(minutes: duration));
    final isPastDue = now.isAfter(endTime) && status == 'confirmed';
    
    // Auto-concluir se passou da hora
    if (isPastDue) {
      Future.delayed(Duration.zero, () {
        _updateAppointmentStatus(appointmentId, 'completed');
      });
    }
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (status) {
      case 'confirmed':
        statusColor = AppColors.info;
        statusText = 'Confirmado';
        statusIcon = Icons.check_circle;
        break;
      case 'completed':
        statusColor = AppColors.success;
        statusText = 'Concluído';
        statusIcon = Icons.done_all;
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        statusText = 'Cancelado';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = AppColors.warning;
        statusText = 'Pendente';
        statusIcon = Icons.schedule;
    }

    // Se já está concluído ou cancelado, não permite swipe
    if (status == 'cancelled' || status == 'completed') {
      return _buildStaticCard(
        appointment,
        time,
        status,
        statusColor,
        statusText,
        statusIcon,
      );
    }

    // Card com swipe para agendamentos ativos
    return Dismissible(
      key: Key('appointment_${appointment['id']}'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Deslizar direita → esquerda: Concluir (verde)
          return await _showConfirmDialog(
            context,
            'Concluir Agendamento',
            'Deseja marcar este atendimento como concluído?',
            'Concluir',
            Colors.green,
            () => _updateAppointmentStatus(appointmentId, 'completed'),
          );
        } else if (direction == DismissDirection.startToEnd) {
          // Deslizar esquerda → direita: Cancelar (vermelho)
          return await _showConfirmDialog(
            context,
            'Cancelar Agendamento',
            'Tem certeza que deseja cancelar este agendamento?',
            'Cancelar',
            Colors.red,
            () => _updateAppointmentStatus(appointmentId, 'cancelled'),
          );
        }
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel, color: Colors.white, size: 32),
            SizedBox(height: 4),
            Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.done_all, color: Colors.white, size: 32),
            SizedBox(height: 4),
            Text(
              'Concluir',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: Card(
        color: AppColors.surface,
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      time,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Menu de 3 pontos
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
                    onSelected: (value) {
                      switch (value) {
                        case 'confirm':
                          _updateAppointmentStatus(appointmentId, 'confirmed');
                          break;
                        case 'complete':
                          _showConfirmDialog(
                            context,
                            'Concluir Agendamento',
                            'Deseja marcar este atendimento como concluído?',
                            'Concluir',
                            Colors.green,
                            () => _updateAppointmentStatus(appointmentId, 'completed'),
                          );
                          break;
                        case 'cancel':
                          _showConfirmDialog(
                            context,
                            'Cancelar Agendamento',
                            'Tem certeza que deseja cancelar este agendamento?',
                            'Cancelar',
                            Colors.red,
                            () => _updateAppointmentStatus(appointmentId, 'cancelled'),
                          );
                          break;
                      }
                    },
                    itemBuilder: (context) {
                      List<PopupMenuEntry<String>> items = [];
                      
                      if (status == 'pending') {
                        items.add(
                          const PopupMenuItem(
                            value: 'confirm',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.blue, size: 20),
                                SizedBox(width: 12),
                                Text('Confirmar'),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      if (status == 'confirmed' || status == 'pending') {
                        items.add(
                          const PopupMenuItem(
                            value: 'complete',
                            child: Row(
                              children: [
                                Icon(Icons.done_all, color: Colors.green, size: 20),
                                SizedBox(width: 12),
                                Text('Concluir'),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      items.add(
                        const PopupMenuItem(
                          value: 'cancel',
                          child: Row(
                            children: [
                              Icon(Icons.cancel, color: Colors.red, size: 20),
                              SizedBox(width: 12),
                              Text('Cancelar'),
                            ],
                          ),
                        ),
                      );
                      
                      return items;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.gold.withOpacity(0.2),
                  child: Icon(Icons.person, color: AppColors.gold, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment['client_name'] ?? 'Cliente',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appointment['service_name'] ?? 'Serviço',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (appointment['notes'] != null && 
                appointment['notes'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notes, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        appointment['notes'],
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.attach_money, size: 16, color: AppColors.gold),
                const SizedBox(width: 4),
                Text(
                  'R\$ ${appointment['service_price'] ?? '0.00'}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  '${appointment['service_duration'] ?? 0} min',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    ); // Fecha o Dismissible
  }

  // Card estático para agendamentos concluídos ou cancelados (sem swipe)
  Widget _buildStaticCard(
    Map<String, dynamic> appointment,
    String time,
    String status,
    Color statusColor,
    String statusText,
    IconData statusIcon,
  ) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    time,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.gold.withOpacity(0.2),
                  child: Icon(Icons.person, color: AppColors.gold, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment['client_name'] ?? 'Cliente',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appointment['service_name'] ?? 'Serviço',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (appointment['notes'] != null && 
                appointment['notes'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notes, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        appointment['notes'],
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.attach_money, size: 16, color: AppColors.gold),
                const SizedBox(width: 4),
                Text(
                  'R\$ ${appointment['service_price'] ?? '0.00'}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  '${appointment['service_duration'] ?? 0} min',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Diálogo de confirmação para swipe e menu
  Future<bool> _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
    String actionText,
    Color actionColor,
    VoidCallback onConfirm,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
              onConfirm();
            },
            child: Text(
              actionText,
              style: TextStyle(color: actionColor),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _updateAppointmentStatus(int appointmentId, String newStatus) async {
    try {
      await DioClient.patch(
        '/appointments/$appointmentId/update_status/',
        data: {'status': newStatus},
      );
      
      if (mounted) {
        String message = 'Status atualizado com sucesso!';
        if (newStatus == 'completed') {
          message = '✅ Atendimento concluído!';
        } else if (newStatus == 'cancelled') {
          message = '❌ Agendamento cancelado';
        } else if (newStatus == 'confirmed') {
          message = '✓ Agendamento confirmado';
        }
        
        SnackBarUtils.showSuccess(context, message);
        _loadAppointments();
      }
    } on ApiException catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, e.message);
      }
    }
  }

}

/// Página de Perfil do Barbeiro
class BarberProfilePage extends StatefulWidget {
  const BarberProfilePage({super.key});

  @override
  State<BarberProfilePage> createState() => _BarberProfilePageState();
}

class _BarberProfilePageState extends State<BarberProfilePage> {
  int _totalAppointments = 0;
  int _todayAppointments = 0;
  int _monthAppointments = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    
    try {
      // Carregar estatísticas gerais do barbeiro
      final response = await DioClient.get('/appointments/barber_stats/');
      
      setState(() {
        _totalAppointments = response.data['total_completed'] ?? 0;
        _todayAppointments = response.data['today_completed'] ?? 0;
        _monthAppointments = response.data['month_completed'] ?? 0;
        _isLoadingStats = false;
      });
    } catch (e) {
      debugPrint('❌ Erro ao carregar estatísticas: $e');
      setState(() => _isLoadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditBarberProfilePage(),
                ),
              ).then((_) => setState(() {})); // Atualiza ao voltar
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            final user = state.user;
            return RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Avatar
                    Stack(
                      children: [
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
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.content_cut,
                              color: AppColors.primaryDark,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.fullName,
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Barbeiro',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Estatísticas Gerais
                    _buildStatsGrid(),
                    const SizedBox(height: 32),

                    // Informações
                    _buildInfoCard(
                      icon: Icons.email,
                      title: 'E-mail',
                      subtitle: user.email,
                    ),
                    _buildInfoCard(
                      icon: Icons.phone,
                      title: 'Telefone',
                      subtitle: user.phone ?? 'Não informado',
                    ),
                    _buildInfoCard(
                      icon: Icons.person,
                      title: 'Usuário',
                      subtitle: user.username,
                    ),
                    const SizedBox(height: 32),

                    // Botão Gerenciar Disponibilidade
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ManageAvailabilityPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.all(16),
                        ),
                        icon: const Icon(Icons.schedule),
                        label: const Text('Gerenciar Disponibilidade'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Botão de Gerenciar Serviços
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ManageBarberServicesPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.all(16),
                        ),
                        icon: const Icon(Icons.content_cut),
                        label: const Text('Gerenciar Meus Serviços'),
                      ),
                    ),
                    const SizedBox(height: 12),

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
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildStatsGrid() {
    if (_isLoadingStats) {
      return Card(
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        ),
      );
    }

    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatCard(
              icon: Icons.check_circle,
              value: _totalAppointments.toString(),
              label: 'Total de\nAtendimentos',
              color: AppColors.gold,
            ),
            _StatCard(
              icon: Icons.today,
              value: _todayAppointments.toString(),
              label: 'Atendimentos\nHoje',
              color: Colors.green,
            ),
            _StatCard(
              icon: Icons.calendar_month,
              value: _monthAppointments.toString(),
              label: 'Atendimentos\nMês',
              color: Colors.blue,
            ),
          ],
        ),
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
        title: Text(
          title,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        subtitle: Text(subtitle, style: AppTextStyles.titleMedium),
      ),
    );
  }
}
