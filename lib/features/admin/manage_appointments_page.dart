import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/snackbar_utils.dart';

/// Página de Gerenciamento de Agendamentos
class ManageAppointmentsPage extends StatefulWidget {
  const ManageAppointmentsPage({super.key});

  @override
  State<ManageAppointmentsPage> createState() => _ManageAppointmentsPageState();
}

class _ManageAppointmentsPageState extends State<ManageAppointmentsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _filteredAppointments = [];
  
  // Filtros
  String _statusFilter = 'all'; // all, pending, confirmed, completed, cancelled
  String _dateFilter = 'all'; // all, today, week, month, custom
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  int? _selectedBarberId;
  int? _selectedClientId;
  
  // Dados para dropdowns
  List<Map<String, dynamic>> _barbers = [];
  List<Map<String, dynamic>> _clients = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      debugPrint('🔵 Carregando agendamentos e dados auxiliares...');
      
      // Carregar tudo em paralelo
      final results = await Future.wait([
        DioClient.get('/appointments/'),
        DioClient.get('/users/barbers/'),
        DioClient.get('/users/'), // Todos os usuários (clientes)
      ]);
      
      final appointments = _extractList(results[0].data);
      final barbers = _extractList(results[1].data);
      final users = _extractList(results[2].data);
      
      // Filtrar apenas clientes (não barbeiros)
      final clients = users.where((u) => u['is_barber'] == false).toList();
      
      debugPrint('✅ Carregados: ${appointments.length} agendamentos, ${barbers.length} barbeiros, ${clients.length} clientes');
      
      setState(() {
        _appointments = appointments.cast<Map<String, dynamic>>();
        _barbers = barbers.cast<Map<String, dynamic>>();
        _clients = clients.cast<Map<String, dynamic>>();
        _applyFilters();
        _isLoading = false;
      });
    } on ApiException catch (e) {
      debugPrint('❌ Erro ao carregar dados: ${e.message}');
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

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_appointments);
    
    // Filtro de status
    if (_statusFilter != 'all') {
      filtered = filtered.where((apt) => apt['status'] == _statusFilter).toList();
    }
    
    // Filtro de data
    if (_dateFilter != 'all') {
      final now = DateTime.now();
      filtered = filtered.where((apt) {
        final aptDate = DateTime.parse(apt['date']);
        
        switch (_dateFilter) {
          case 'today':
            return aptDate.year == now.year &&
                   aptDate.month == now.month &&
                   aptDate.day == now.day;
          case 'week':
            final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
            final endOfWeek = startOfWeek.add(const Duration(days: 6));
            return aptDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
                   aptDate.isBefore(endOfWeek.add(const Duration(days: 1)));
          case 'month':
            return aptDate.year == now.year && aptDate.month == now.month;
          case 'custom':
            if (_customStartDate != null && _customEndDate != null) {
              return aptDate.isAfter(_customStartDate!.subtract(const Duration(days: 1))) &&
                     aptDate.isBefore(_customEndDate!.add(const Duration(days: 1)));
            }
            return true;
          default:
            return true;
        }
      }).toList();
    }
    
    // Filtro de barbeiro
    if (_selectedBarberId != null) {
      filtered = filtered.where((apt) => apt['barber'] == _selectedBarberId).toList();
    }
    
    // Filtro de cliente
    if (_selectedClientId != null) {
      filtered = filtered.where((apt) => apt['client'] == _selectedClientId).toList();
    }
    
    // Ordenar por data (mais recentes primeiro)
    filtered.sort((a, b) {
      final dateA = DateTime.parse(a['date']);
      final dateB = DateTime.parse(b['date']);
      return dateB.compareTo(dateA);
    });
    
    setState(() => _filteredAppointments = filtered);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Agendamentos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Atualizar',
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _showFiltersDialog,
            tooltip: 'Filtros',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros rápidos
          _buildQuickFilters(),
          
          // Contador de resultados
          if (!_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surface,
              child: Row(
                children: [
                  Text(
                    '${_filteredAppointments.length} agendamento(s) encontrado(s)',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (_hasActiveFilters()) ...[
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('Limpar Filtros'),
                    ),
                  ],
                ],
              ),
            ),
          
          // Lista de agendamentos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAppointments.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredAppointments.length,
                          itemBuilder: (context, index) {
                            final appointment = _filteredAppointments[index];
                            return _buildAppointmentCard(appointment);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtros Rápidos',
            style: AppTextStyles.titleSmall,
          ),
          const SizedBox(height: 12),
          
          // Filtro de Status
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip('Todos', _statusFilter == 'all', () {
                setState(() => _statusFilter = 'all');
                _applyFilters();
              }),
              _buildFilterChip('Pendentes', _statusFilter == 'pending', () {
                setState(() => _statusFilter = 'pending');
                _applyFilters();
              }),
              _buildFilterChip('Confirmados', _statusFilter == 'confirmed', () {
                setState(() => _statusFilter = 'confirmed');
                _applyFilters();
              }),
              _buildFilterChip('Concluídos', _statusFilter == 'completed', () {
                setState(() => _statusFilter = 'completed');
                _applyFilters();
              }),
              _buildFilterChip('Cancelados', _statusFilter == 'cancelled', () {
                setState(() => _statusFilter = 'cancelled');
                _applyFilters();
              }),
            ],
          ),
          const SizedBox(height: 12),
          
          // Filtro de Data
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDateFilterChip('Todos', _dateFilter == 'all', () {
                  setState(() => _dateFilter = 'all');
                  _applyFilters();
                }),
                _buildDateFilterChip('Hoje', _dateFilter == 'today', () {
                  setState(() => _dateFilter = 'today');
                  _applyFilters();
                }),
                _buildDateFilterChip('Esta Semana', _dateFilter == 'week', () {
                  setState(() => _dateFilter = 'week');
                  _applyFilters();
                }),
                _buildDateFilterChip('Este Mês', _dateFilter == 'month', () {
                  setState(() => _dateFilter = 'month');
                  _applyFilters();
                }),
                _buildDateFilterChip('Personalizado', _dateFilter == 'custom', () {
                  _showCustomDatePicker();
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.gold.withOpacity(0.3),
      checkmarkColor: AppColors.gold,
    );
  }

  Widget _buildDateFilterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.gold.withOpacity(0.3),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final date = DateTime.parse(appointment['date']);
    final status = appointment['status'] as String;
    
    // Buscar nomes do barbeiro e cliente
    final barberName = _getBarberName(appointment['barber']);
    final clientName = _getClientName(appointment['client']);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showAppointmentDetails(appointment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho: Data e Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd/MM/yyyy - HH:mm', 'pt_BR').format(date),
                        style: AppTextStyles.titleSmall,
                      ),
                    ],
                  ),
                  _buildStatusBadge(status),
                ],
              ),
              const Divider(height: 24),
              
              // Informações
              _buildInfoRow(Icons.person, 'Cliente', clientName),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.cut, 'Barbeiro', barberName),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.content_cut, 'Serviço', appointment['service_name'] ?? 'N/A'),
              
              if (appointment['notes'] != null && appointment['notes'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow(Icons.note, 'Observações', appointment['notes']),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Pendente';
        break;
      case 'confirmed':
        color = Colors.blue;
        label = 'Confirmado';
        break;
      case 'completed':
        color = Colors.green;
        label = 'Concluído';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Cancelado';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 80,
            color: AppColors.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum agendamento encontrado',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hasActiveFilters()
                ? 'Tente ajustar os filtros'
                : 'Ainda não há agendamentos no sistema',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _getBarberName(dynamic barberId) {
    if (barberId == null) return 'N/A';
    final barber = _barbers.firstWhere(
      (b) => b['id'] == barberId,
      orElse: () => {},
    );
    return barber['full_name'] ?? 'Barbeiro #$barberId';
  }

  String _getClientName(dynamic clientId) {
    if (clientId == null) return 'N/A';
    final client = _clients.firstWhere(
      (c) => c['id'] == clientId,
      orElse: () => {},
    );
    return client['full_name'] ?? 'Cliente #$clientId';
  }

  bool _hasActiveFilters() {
    return _statusFilter != 'all' ||
           _dateFilter != 'all' ||
           _selectedBarberId != null ||
           _selectedClientId != null;
  }

  void _clearFilters() {
    setState(() {
      _statusFilter = 'all';
      _dateFilter = 'all';
      _customStartDate = null;
      _customEndDate = null;
      _selectedBarberId = null;
      _selectedClientId = null;
    });
    _applyFilters();
  }

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtros Avançados'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Barbeiro', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                initialValue: _selectedBarberId,
                decoration: const InputDecoration(
                  hintText: 'Todos os barbeiros',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  ..._barbers.map((barber) {
                    return DropdownMenuItem(
                      value: barber['id'],
                      child: Text(barber['full_name']),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() => _selectedBarberId = value);
                },
              ),
              const SizedBox(height: 16),
              
              const Text('Cliente', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                initialValue: _selectedClientId,
                decoration: const InputDecoration(
                  hintText: 'Todos os clientes',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  ..._clients.map((client) {
                    return DropdownMenuItem(
                      value: client['id'],
                      child: Text(client['full_name']),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() => _selectedClientId = value);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearFilters();
              Navigator.pop(context);
            },
            child: const Text('Limpar'),
          ),
          ElevatedButton(
            onPressed: () {
              _applyFilters();
              Navigator.pop(context);
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  void _showCustomDatePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.gold,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _dateFilter = 'custom';
      });
      _applyFilters();
    }
  }

  void _showAppointmentDetails(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalhes do Agendamento'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('ID', '#${appointment['id']}'),
              _buildDetailRow('Data', DateFormat('dd/MM/yyyy', 'pt_BR').format(DateTime.parse(appointment['date']))),
              _buildDetailRow('Horário', DateFormat('HH:mm', 'pt_BR').format(DateTime.parse(appointment['date']))),
              _buildDetailRow('Cliente', _getClientName(appointment['client'])),
              _buildDetailRow('Barbeiro', _getBarberName(appointment['barber'])),
              _buildDetailRow('Serviço', appointment['service_name'] ?? 'N/A'),
              _buildDetailRow('Status', appointment['status']),
              if (appointment['notes'] != null)
                _buildDetailRow('Observações', appointment['notes']),
              _buildDetailRow('Criado em', DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(appointment['created_at']))),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
