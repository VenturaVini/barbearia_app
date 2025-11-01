import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/dio_client.dart';

class AdvancedSettingsPage extends StatefulWidget {
  const AdvancedSettingsPage({super.key});

  @override
  State<AdvancedSettingsPage> createState() => _AdvancedSettingsPageState();
}

class _AdvancedSettingsPageState extends State<AdvancedSettingsPage> {
  bool _isLoading = false;
  
  // Horários padrão
  List<Map<String, dynamic>> _defaultSchedules = [];
  
  // Feriados
  List<Map<String, dynamic>> _holidays = [];
  
  // Configurações gerais
  Map<String, dynamic> _generalSettings = {
    'appointment_duration': 30,
    'max_appointments_per_day': 20,
    'min_advance_booking_hours': 2,
    'max_advance_booking_days': 30,
    'cancellation_deadline_hours': 24,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      debugPrint('🔵 Carregando configurações globais...');
      
      // Carregar horários globais
      final schedulesResponse = await DioClient.get('/barber/availability/global-schedules/');
      
      List<Map<String, dynamic>> schedules;
      if (schedulesResponse.data is List) {
        schedules = List<Map<String, dynamic>>.from(schedulesResponse.data);
        debugPrint('✅ ${schedules.length} horários globais carregados');
      } else {
        schedules = [];
        debugPrint('⚠️ Nenhum horário global encontrado, usando padrões');
      }
      
      // Se não houver horários configurados, criar padrão localmente
      if (schedules.isEmpty) {
        debugPrint('📅 Criando horários padrão localmente...');
        schedules = _createDefaultSchedules();
      } else {
        // Adicionar nomes dos dias
        for (var schedule in schedules) {
          final weekday = schedule['weekday'] as int;
          schedule['name'] = _getWeekdayName(weekday);
        }
      }
      
      setState(() {
        _defaultSchedules = schedules;
        _isLoading = false;
      });
      
      debugPrint('✅ Configurações carregadas com sucesso');
    } catch (e) {
      debugPrint('❌ Erro ao carregar configurações: $e');
      // Se não existir no backend, criar padrões localmente
      setState(() {
        _defaultSchedules = _createDefaultSchedules();
        _isLoading = false;
      });
    }
  }
  
  String _getWeekdayName(int weekday) {
    const names = {
      1: 'Segunda-feira',
      2: 'Terça-feira',
      3: 'Quarta-feira',
      4: 'Quinta-feira',
      5: 'Sexta-feira',
      6: 'Sábado',
      7: 'Domingo',
    };
    return names[weekday] ?? 'Desconhecido';
  }

  List<Map<String, dynamic>> _createDefaultSchedules() {
    return [
      {'weekday': 1, 'start_time': '09:30', 'end_time': '19:00', 'is_available': false, 'name': 'Segunda-feira'},
      {'weekday': 2, 'start_time': '09:30', 'end_time': '19:00', 'is_available': true, 'name': 'Terça-feira'},
      {'weekday': 3, 'start_time': '09:30', 'end_time': '19:00', 'is_available': true, 'name': 'Quarta-feira'},
      {'weekday': 4, 'start_time': '09:30', 'end_time': '19:00', 'is_available': true, 'name': 'Quinta-feira'},
      {'weekday': 5, 'start_time': '09:30', 'end_time': '19:00', 'is_available': true, 'name': 'Sexta-feira'},
      {'weekday': 6, 'start_time': '09:30', 'end_time': '19:00', 'is_available': true, 'name': 'Sábado'},
      {'weekday': 7, 'start_time': '09:30', 'end_time': '19:00', 'is_available': false, 'name': 'Domingo'},
    ];
  }

  Future<void> _saveDefaultSchedule(Map<String, dynamic> schedule) async {
    try {
      debugPrint('🔵 Salvando horário global: ${schedule['weekday']} - ${schedule['is_available']}');
      
      await DioClient.post('/barber/availability/global-schedules/', data: schedule);
      
      debugPrint('✅ Horário global salvo com sucesso');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Horário padrão atualizado com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Recarregar para pegar os dados atualizados
      await _loadSettings();
    } catch (e) {
      debugPrint('❌ Erro ao salvar horário padrão: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveHoliday(Map<String, dynamic> holiday) async {
    try {
      await DioClient.post('/admin/settings/holidays/', data: holiday);
      await _loadSettings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feriado cadastrado com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erro ao salvar feriado: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteHoliday(int id) async {
    try {
      await DioClient.delete('/admin/settings/holidays/$id/');
      await _loadSettings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feriado removido com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erro ao deletar feriado: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao deletar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveGeneralSettings() async {
    try {
      await DioClient.post('/admin/settings/general/', data: _generalSettings);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configurações gerais atualizadas com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erro ao salvar configurações gerais: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditScheduleDialog(Map<String, dynamic> schedule) {
    String startTime = schedule['start_time'] ?? '09:30';
    String endTime = schedule['end_time'] ?? '19:00';
    bool isAvailable = schedule['is_available'] ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Editar ${schedule['name']}',
            style: AppTextStyles.headlineSmall,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text('Disponível'),
                  subtitle: const Text('A barbearia funciona neste dia'),
                  value: isAvailable,
                  activeThumbColor: AppColors.gold,
                  onChanged: (value) {
                    setDialogState(() => isAvailable = value);
                  },
                ),
                if (isAvailable) ...[
                  const SizedBox(height: 16),
                  const Text('Horário de Abertura', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: startTime,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _generateTimeSlots().map((time) => DropdownMenuItem(
                      value: time,
                      child: Text(time),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => startTime = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Horário de Fechamento', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: endTime,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _generateTimeSlots().map((time) => DropdownMenuItem(
                      value: time,
                      child: Text(time),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => endTime = value);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
              onPressed: () async {
                final updatedSchedule = {
                  'weekday': schedule['weekday'],
                  'start_time': startTime,
                  'end_time': endTime,
                  'is_available': isAvailable,
                };
                
                await _saveDefaultSchedule(updatedSchedule);
                
                // Atualizar localmente
                setState(() {
                  final index = _defaultSchedules.indexWhere((s) => s['weekday'] == schedule['weekday']);
                  if (index != -1) {
                    _defaultSchedules[index] = {...schedule, ...updatedSchedule};
                  }
                });
                
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddHolidayDialog() {
    DateTime selectedDate = DateTime.now();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isRecurring = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Adicionar Feriado', style: AppTextStyles.headlineSmall),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Feriado *',
                    hintText: 'Ex: Natal',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição (opcional)',
                    hintText: 'Informações adicionais',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Data: ${_formatDate(selectedDate)}'),
                  trailing: const Icon(Icons.calendar_today, color: AppColors.gold),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppColors.gold,
                              onPrimary: Colors.black,
                              surface: AppColors.surface,
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Feriado Recorrente'),
                  subtitle: const Text('Repete todos os anos'),
                  value: isRecurring,
                  activeThumbColor: AppColors.gold,
                  onChanged: (value) {
                    setDialogState(() => isRecurring = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor, informe o nome do feriado'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final holiday = {
                  'name': nameController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'date': _formatDateForApi(selectedDate),
                  'is_recurring': isRecurring,
                };

                await _saveHoliday(holiday);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGeneralSettingsDialog() {
    final appointmentDurationController = TextEditingController(
      text: _generalSettings['appointment_duration'].toString(),
    );
    final maxAppointmentsController = TextEditingController(
      text: _generalSettings['max_appointments_per_day'].toString(),
    );
    final minAdvanceController = TextEditingController(
      text: _generalSettings['min_advance_booking_hours'].toString(),
    );
    final maxAdvanceController = TextEditingController(
      text: _generalSettings['max_advance_booking_days'].toString(),
    );
    final cancellationController = TextEditingController(
      text: _generalSettings['cancellation_deadline_hours'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Configurações Gerais', style: AppTextStyles.headlineSmall),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: appointmentDurationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duração Padrão do Agendamento (min)',
                  border: OutlineInputBorder(),
                  suffixText: 'min',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: maxAppointmentsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Máx. Agendamentos por Dia (por barbeiro)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: minAdvanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Antecedência Mínima para Agendar (horas)',
                  border: OutlineInputBorder(),
                  suffixText: 'h',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: maxAdvanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Antecedência Máxima para Agendar (dias)',
                  border: OutlineInputBorder(),
                  suffixText: 'dias',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cancellationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Prazo para Cancelamento (horas)',
                  border: OutlineInputBorder(),
                  suffixText: 'h',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
            onPressed: () async {
              setState(() {
                _generalSettings = {
                  'appointment_duration': int.tryParse(appointmentDurationController.text) ?? 30,
                  'max_appointments_per_day': int.tryParse(maxAppointmentsController.text) ?? 20,
                  'min_advance_booking_hours': int.tryParse(minAdvanceController.text) ?? 2,
                  'max_advance_booking_days': int.tryParse(maxAdvanceController.text) ?? 30,
                  'cancellation_deadline_hours': int.tryParse(cancellationController.text) ?? 24,
                };
              });

              await _saveGeneralSettings();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  List<String> _generateTimeSlots() {
    final slots = <String>[];
    for (int hour = 6; hour <= 23; hour++) {
      for (int minute in [0, 30]) {
        final time = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        slots.add(time);
      }
    }
    return slots;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _formatDateForApi(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.primaryDark,
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: Text('Configurações Avançadas', style: AppTextStyles.headlineMedium),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Horários Padrão
          _buildSectionTitle('Horários Padrão da Barbearia', Icons.schedule),
          const SizedBox(height: 8),
          _buildInfoBox(
            'Estes são os horários padrão que serão aplicados a todos os novos barbeiros. '
            'Cada barbeiro pode ajustar seus próprios horários individualmente.',
          ),
          const SizedBox(height: 16),
          ..._defaultSchedules.map((schedule) => _buildScheduleCard(schedule)),
          
          const SizedBox(height: 32),
          
          // Feriados
          _buildSectionTitle('Feriados e Datas Especiais', Icons.event_busy),
          const SizedBox(height: 8),
          _buildInfoBox(
            'A barbearia não funcionará nos feriados cadastrados. '
            'Feriados recorrentes se repetem automaticamente todos os anos.',
          ),
          const SizedBox(height: 16),
          if (_holidays.isEmpty)
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.event_available, size: 48, color: Colors.white24),
                      const SizedBox(height: 8),
                      Text(
                        'Nenhum feriado cadastrado',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ..._holidays.map((holiday) => _buildHolidayCard(holiday)),
          
          const SizedBox(height: 32),
          
          // Configurações Gerais
          _buildSectionTitle('Configurações Gerais do Sistema', Icons.settings),
          const SizedBox(height: 16),
          _buildGeneralSettingsCard(),
          
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'holiday',
            onPressed: _showAddHolidayDialog,
            backgroundColor: AppColors.gold,
            icon: const Icon(Icons.event_busy, color: Colors.black),
            label: const Text('Adicionar Feriado', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.gold, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.gold),
        ),
      ],
    );
  }

  Widget _buildInfoBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.gold, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule) {
    final isAvailable = schedule['is_available'] ?? false;
    
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isAvailable ? AppColors.gold.withOpacity(0.2) : Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isAvailable ? Icons.check_circle : Icons.cancel,
            color: isAvailable ? AppColors.gold : Colors.red,
          ),
        ),
        title: Text(
          schedule['name'] ?? '',
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          isAvailable 
              ? '${schedule['start_time']} - ${schedule['end_time']}'
              : 'Fechado',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: AppColors.gold),
          onPressed: () => _showEditScheduleDialog(schedule),
        ),
      ),
    );
  }

  Widget _buildHolidayCard(Map<String, dynamic> holiday) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.event_busy, color: Colors.red),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                holiday['name'] ?? '',
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (holiday['is_recurring'] == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'RECORRENTE',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              holiday['date'] ?? '',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
            ),
            if (holiday['description'] != null && holiday['description'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  holiday['description'],
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppColors.surface,
                title: const Text('Confirmar Exclusão'),
                content: Text('Deseja realmente remover o feriado "${holiday['name']}"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Remover'),
                  ),
                ],
              ),
            );
            
            if (confirm == true && holiday['id'] != null) {
              await _deleteHoliday(holiday['id']);
            }
          },
        ),
        isThreeLine: holiday['description'] != null && holiday['description'].toString().isNotEmpty,
      ),
    );
  }

  Widget _buildGeneralSettingsCard() {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingRow(
              'Duração Padrão do Agendamento',
              '${_generalSettings['appointment_duration']} minutos',
              Icons.timer,
            ),
            const Divider(height: 24),
            _buildSettingRow(
              'Máx. Agendamentos por Dia',
              '${_generalSettings['max_appointments_per_day']} por barbeiro',
              Icons.event_note,
            ),
            const Divider(height: 24),
            _buildSettingRow(
              'Antecedência Mínima para Agendar',
              '${_generalSettings['min_advance_booking_hours']} horas',
              Icons.schedule,
            ),
            const Divider(height: 24),
            _buildSettingRow(
              'Antecedência Máxima para Agendar',
              '${_generalSettings['max_advance_booking_days']} dias',
              Icons.calendar_today,
            ),
            const Divider(height: 24),
            _buildSettingRow(
              'Prazo para Cancelamento',
              '${_generalSettings['cancellation_deadline_hours']} horas antes',
              Icons.cancel_schedule_send,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showGeneralSettingsDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.edit, color: Colors.black),
                label: const Text(
                  'Editar Configurações',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.gold, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
