import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/utils/date_utils.dart' as app_date_utils;
import '../appointments/select_barber_first_page.dart';

class AppointmentsHistoryPage extends StatefulWidget {
  const AppointmentsHistoryPage({super.key});

  @override
  State<AppointmentsHistoryPage> createState() =>
      _AppointmentsHistoryPageState();
}

class _AppointmentsHistoryPageState extends State<AppointmentsHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _allAppointments = [];
  bool _isLoading = true;
  
  // Filtros para a aba de histórico
  DateTimeRange? _dateFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    try {
      final response = await DioClient.get('/appointments/');
      
      // Extrair lista (pode vir direto ou paginado)
      final data = response.data;
      final List appointments;
      if (data is Map && data.containsKey('results')) {
        appointments = data['results'] as List;
      } else if (data is List) {
        appointments = data;
      } else {
        appointments = [];
      }
      
      setState(() {
        _allAppointments = appointments;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        SnackBarUtils.showError(context, e.message);
      }
    }
  }

  // Filtrar agendamentos ativos (futuros, pending ou confirmed)
  List<dynamic> get _activeAppointments {
    final now = DateTime.now();
    return _allAppointments.where((apt) {
      final scheduledFor = app_date_utils.AppDateUtils.parseFromBackend(apt['scheduled_for']);
      final status = apt['status'];
      return scheduledFor.isAfter(now) && 
             (status == 'pending' || status == 'confirmed');
    }).toList()
      ..sort((a, b) {
        final dateA = app_date_utils.AppDateUtils.parseFromBackend(a['scheduled_for']);
        final dateB = app_date_utils.AppDateUtils.parseFromBackend(b['scheduled_for']);
        return dateA.compareTo(dateB);
      });
  }

  // Filtrar histórico (passados ou cancelados/completados)
  List<dynamic> get _historyAppointments {
    final now = DateTime.now();
    var history = _allAppointments.where((apt) {
      final scheduledFor = app_date_utils.AppDateUtils.parseFromBackend(apt['scheduled_for']);
      final status = apt['status'];
      return scheduledFor.isBefore(now) || 
             status == 'cancelled' || 
             status == 'completed';
    }).toList();

    // Aplicar filtro de data se existir
    if (_dateFilter != null) {
      history = history.where((apt) {
        final scheduledFor = app_date_utils.AppDateUtils.parseFromBackend(apt['scheduled_for']);
        return scheduledFor.isAfter(_dateFilter!.start.subtract(const Duration(days: 1))) &&
               scheduledFor.isBefore(_dateFilter!.end.add(const Duration(days: 1)));
      }).toList();
    }

    return history
      ..sort((a, b) {
        final dateA = app_date_utils.AppDateUtils.parseFromBackend(a['scheduled_for']);
        final dateB = app_date_utils.AppDateUtils.parseFromBackend(b['scheduled_for']);
        return dateB.compareTo(dateA); // Mais recente primeiro
      });
  }

  Future<void> _cancelAppointment(int appointmentId) async {
    try {
      await DioClient.patch('/appointments/$appointmentId/cancel/');
      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Agendamento cancelado com sucesso');
        _loadAppointments();
      }
    } on ApiException catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, e.message);
      }
    }
  }

  Future<void> _rescheduleAppointment(int appointmentId, String serviceName) async {
    // Mostrar diálogo de confirmação
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reagendar Atendimento'),
        content: Text(
          'Deseja cancelar o agendamento atual de $serviceName e fazer um novo agendamento?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sim, Reagendar',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Cancelar agendamento atual
    try {
      await DioClient.patch('/appointments/$appointmentId/cancel/');
      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Agendamento cancelado. Escolha um novo barbeiro.');
        
        // Navegar direto para tela de seleção de barbeiro
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SelectBarberFirstPage(),
          ),
        ).then((_) {
          // Recarregar lista quando voltar
          _loadAppointments();
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, e.message);
      }
    }
  }

  void _showCancelConfirmation(int appointmentId, String serviceName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Agendamento'),
        content: Text(
          'Tem certeza que deseja cancelar o agendamento de $serviceName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelAppointment(appointmentId);
            },
            child: const Text(
              'Sim, Cancelar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
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

  Widget _buildAppointmentCard(Map<String, dynamic> appointment, {required bool isActive}) {
    final scheduledFor = app_date_utils.AppDateUtils.parseFromBackend(appointment['scheduled_for']);
    final status = appointment['status'];
    final canCancel = isActive && (status == 'pending' || status == 'confirmed');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showAppointmentDetails(appointment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com data e status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd/MM/yyyy', 'pt_BR').format(scheduledFor),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
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
                ],
              ),
              const SizedBox(height: 12),

              // Horário
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('HH:mm', 'pt_BR').format(scheduledFor),
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Serviço
              Row(
                children: [
                  Icon(
                    Icons.content_cut,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appointment['service_name'],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Barbeiro
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    appointment['barber_name'],
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),

              // Preço e Duração
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'R\$ ${appointment['service_price']}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.timer,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${appointment['service_duration']} min',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),

              // Botões de ação (se permitido)
              if (canCancel) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showCancelConfirmation(
                          appointment['id'],
                          appointment['service_name'],
                        ),
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('Cancelar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _rescheduleAppointment(
                          appointment['id'],
                          appointment['service_name'],
                        ),
                        icon: const Icon(Icons.event_repeat, size: 18),
                        label: const Text('Reagendar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAppointmentDetails(Map<String, dynamic> appointment) {
    final scheduledFor = app_date_utils.AppDateUtils.parseFromBackend(appointment['scheduled_for']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalhes do Agendamento'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Data', DateFormat('dd/MM/yyyy', 'pt_BR').format(scheduledFor)),
              _buildDetailRow('Horário', DateFormat('HH:mm', 'pt_BR').format(scheduledFor)),
              _buildDetailRow('Serviço', appointment['service_name']),
              _buildDetailRow('Barbeiro', appointment['barber_name']),
              _buildDetailRow('Valor', 'R\$ ${appointment['service_price']}'),
              _buildDetailRow('Duração', '${appointment['service_duration']} minutos'),
              _buildDetailRow('Status', _getStatusLabel(appointment['status'])),
              if (appointment['notes'] != null && appointment['notes'].toString().isNotEmpty)
                _buildDetailRow('Observações', appointment['notes']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendamentos'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(
              icon: Icon(Icons.event_available),
              text: 'Ativos',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'Histórico',
            ),
          ],
        ),
        actions: [
          // Botão de filtro de data apenas na aba de histórico
          IconButton(
            icon: Icon(
              _dateFilter != null ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _dateFilter != null ? AppColors.gold : null,
            ),
            tooltip: 'Filtrar por data',
            onPressed: _showDateRangeFilter,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Aba de Agendamentos Ativos
                _buildActiveAppointmentsTab(),
                // Aba de Histórico
                _buildHistoryTab(),
              ],
            ),
    );
  }

  Widget _buildActiveAppointmentsTab() {
    if (_activeAppointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 80,
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
              'Seus próximos agendamentos aparecerão aqui',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Novo Agendamento'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        itemCount: _activeAppointments.length,
        itemBuilder: (context, index) =>
            _buildAppointmentCard(_activeAppointments[index], isActive: true),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_historyAppointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _dateFilter != null ? Icons.filter_alt_off : Icons.history,
              size: 80,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              _dateFilter != null
                  ? 'Nenhum agendamento no período'
                  : 'Nenhum histórico ainda',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _dateFilter != null
                  ? 'Tente outro período'
                  : 'Seus agendamentos anteriores aparecerão aqui',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            if (_dateFilter != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _dateFilter = null;
                  });
                },
                icon: const Icon(Icons.clear),
                label: const Text('Limpar Filtro'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: Column(
        children: [
          if (_dateFilter != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.gold.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt, color: AppColors.gold, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Período: ${DateFormat('dd/MM/yyyy').format(_dateFilter!.start)} - ${DateFormat('dd/MM/yyyy').format(_dateFilter!.end)}',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.gold, size: 20),
                    onPressed: () {
                      setState(() {
                        _dateFilter = null;
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _historyAppointments.length,
              itemBuilder: (context, index) =>
                  _buildAppointmentCard(_historyAppointments[index], isActive: false),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDateRangeFilter() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateFilter,
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.gold,
              onPrimary: AppColors.primaryDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateFilter = picked;
      });
    }
  }
}
