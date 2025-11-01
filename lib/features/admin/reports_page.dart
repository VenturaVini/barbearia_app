import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/snackbar_utils.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool _isLoading = true;
  int _totalAppointments = 0;
  int _totalRevenue = 0;
  Map<String, int> _appointmentsByStatus = {};
  List<Map<String, dynamic>> _topServices = [];
  List<Map<String, dynamic>> _topBarbers = [];
  Map<String, int> _appointmentsByMonth = {};

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('🔵 Carregando relatórios...');
      
      final appointmentsResponse = await DioClient.get('/appointments/');
      final servicesResponse = await DioClient.get('/services/');
      final barbersResponse = await DioClient.get('/users/barbers/');

      // Extrair listas de respostas paginadas ou não
      final appointments = _extractList(appointmentsResponse.data);
      final services = _extractList(servicesResponse.data);
      final barbers = _extractList(barbersResponse.data);
      
      debugPrint('✅ Dados carregados: ${appointments.length} agendamentos, ${services.length} serviços, ${barbers.length} barbeiros');

      // Calcular estatísticas
      _calculateStats(appointments, services, barbers);

      setState(() => _isLoading = false);
    } on ApiException catch (e) {
      debugPrint('❌ Erro ao carregar relatórios: ${e.message}');
      setState(() => _isLoading = false);
      if (mounted) {
        SnackBarUtils.showError(context, e.message);
      }
    }
  }

  List _extractList(dynamic data) {
    if (data is Map && data.containsKey('results')) {
      return data['results'] as List;
    }
    return data as List;
  }

  void _calculateStats(List appointments, List services, List barbers) {
    // Total de agendamentos
    _totalAppointments = appointments.length;

    // Agendamentos por status
    _appointmentsByStatus = {
      'pending': 0,
      'confirmed': 0,
      'completed': 0,
      'cancelled': 0,
    };
    
    int totalRevenue = 0;
    Map<int, int> serviceCount = {};
    Map<int, int> barberCount = {};
    Map<String, int> monthCount = {};

    for (var apt in appointments) {
      // Contar por status
      final status = apt['status'];
      _appointmentsByStatus[status] = (_appointmentsByStatus[status] ?? 0) + 1;

      // Calcular receita (apenas completados)
      if (status == 'completed') {
        final price = double.tryParse(apt['service_price'].toString()) ?? 0;
        totalRevenue += price.toInt();
      }

      // Contar serviços mais solicitados
      final serviceId = apt['service'];
      serviceCount[serviceId] = (serviceCount[serviceId] ?? 0) + 1;

      // Contar agendamentos por barbeiro
      final barberId = apt['barber'];
      barberCount[barberId] = (barberCount[barberId] ?? 0) + 1;

      // Agendamentos por mês
      final scheduledFor = DateTime.parse(apt['scheduled_for']);
      final monthKey = DateFormat('yyyy-MM').format(scheduledFor);
      monthCount[monthKey] = (monthCount[monthKey] ?? 0) + 1;
    }

    _totalRevenue = totalRevenue;

    // Top 5 serviços
    final sortedServices = serviceCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    _topServices = sortedServices.take(5).map((entry) {
      final service = services.firstWhere(
        (s) => s['id'] == entry.key,
        orElse: () => {'name': 'Desconhecido', 'price': '0'},
      );
      return {
        'name': service['name'],
        'count': entry.value,
        'price': service['price'],
      };
    }).toList();

    // Top 5 barbeiros
    final sortedBarbers = barberCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    _topBarbers = sortedBarbers.take(5).map((entry) {
      final barber = barbers.firstWhere(
        (b) => b['id'] == entry.key,
        orElse: () => {'first_name': 'Desconhecido', 'last_name': ''},
      );
      return {
        'name': '${barber['first_name']} ${barber['last_name']}'.trim(),
        'count': entry.value,
      };
    }).toList();

    // Últimos 6 meses
    _appointmentsByMonth = monthCount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReports,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resumo Geral
                    Text(
                      'Resumo Geral',
                      style: AppTextStyles.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryCards(),
                    const SizedBox(height: 24),

                    // Agendamentos por Status
                    Text(
                      'Agendamentos por Status',
                      style: AppTextStyles.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    _buildStatusChart(),
                    const SizedBox(height: 24),

                    // Serviços Mais Solicitados
                    Text(
                      'Top 5 Serviços',
                      style: AppTextStyles.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    _buildTopServices(),
                    const SizedBox(height: 24),

                    // Barbeiros Mais Produtivos
                    Text(
                      'Top 5 Barbeiros',
                      style: AppTextStyles.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    _buildTopBarbers(),
                    const SizedBox(height: 24),

                    // Agendamentos por Mês
                    Text(
                      'Últimos Meses',
                      style: AppTextStyles.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    _buildMonthlyChart(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.event,
            title: 'Total',
            value: _totalAppointments.toString(),
            color: AppColors.gold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            icon: Icons.attach_money,
            title: 'Receita',
            value: 'R\$ $_totalRevenue',
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChart() {
    final total = _totalAppointments > 0 ? _totalAppointments : 1;
    
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatusBar(
              'Pendentes',
              _appointmentsByStatus['pending'] ?? 0,
              total,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildStatusBar(
              'Confirmados',
              _appointmentsByStatus['confirmed'] ?? 0,
              total,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildStatusBar(
              'Concluídos',
              _appointmentsByStatus['completed'] ?? 0,
              total,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildStatusBar(
              'Cancelados',
              _appointmentsByStatus['cancelled'] ?? 0,
              total,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(String label, int count, int total, Color color) {
    final percentage = (count / total * 100).toStringAsFixed(1);
    final width = (count / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.bodyMedium),
            Text(
              '$count ($percentage%)',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: width,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildTopServices() {
    if (_topServices.isEmpty) {
      return Card(
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'Nenhum serviço solicitado ainda',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      color: AppColors.surface,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _topServices.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final service = _topServices[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.gold.withOpacity(0.2),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(service['name']),
            subtitle: Text('R\$ ${service['price']}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${service['count']} agendamentos',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBarbers() {
    if (_topBarbers.isEmpty) {
      return Card(
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'Nenhum barbeiro cadastrado ainda',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      color: AppColors.surface,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _topBarbers.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final barber = _topBarbers[index];
          final medal = index == 0
              ? '🥇'
              : index == 1
                  ? '🥈'
                  : index == 2
                      ? '🥉'
                      : '';
          
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.gold.withOpacity(0.2),
              child: Text(
                medal.isNotEmpty ? medal : '${index + 1}',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            title: Text(barber['name']),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${barber['count']} atendimentos',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthlyChart() {
    if (_appointmentsByMonth.isEmpty) {
      return Card(
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'Nenhum agendamento registrado ainda',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
      );
    }

    // Ordenar por mês
    final sortedMonths = _appointmentsByMonth.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Pegar últimos 6 meses
    final lastSixMonths = sortedMonths.length > 6
        ? sortedMonths.sublist(sortedMonths.length - 6)
        : sortedMonths;

    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: lastSixMonths.map((entry) {
            final monthDate = DateTime.parse('${entry.key}-01');
            final monthName = DateFormat('MMMM yyyy', 'pt_BR').format(monthDate);
            final count = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        monthName,
                        style: AppTextStyles.bodyMedium,
                      ),
                      Text(
                        count.toString(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (count / _totalAppointments).clamp(0.0, 1.0),
                      backgroundColor: Colors.grey[800],
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.headlineMedium.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
