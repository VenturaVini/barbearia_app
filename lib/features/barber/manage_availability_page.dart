import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/snackbar_utils.dart';

/// Página de Gerenciamento de Disponibilidade do Barbeiro
class ManageAvailabilityPage extends StatefulWidget {
  const ManageAvailabilityPage({super.key});

  @override
  State<ManageAvailabilityPage> createState() => _ManageAvailabilityPageState();
}

class _ManageAvailabilityPageState extends State<ManageAvailabilityPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> _offDays = [];

  // Horários padrão disponíveis (a cada 30 minutos)
  // Gera horários com intervalos de 5 minutos (terminando em 0 ou 5)
  List<String> _generateTimeSlots() {
    final List<String> slots = [];
    for (int hour = 8; hour <= 21; hour++) {
      for (int minute in [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55]) {
        final timeStr = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        slots.add(timeStr);
      }
    }
    return slots;
  }

  late final List<String> _timeSlots = _generateTimeSlots();

  final Map<int, String> _weekdayNames = {
    1: 'Segunda-feira',
    2: 'Terça-feira',
    3: 'Quarta-feira',
    4: 'Quinta-feira',
    5: 'Sexta-feira',
    6: 'Sábado',
    7: 'Domingo',
  };

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('🔵 Carregando disponibilidade...');
      
      // Carregar horários padrão da semana
      final schedulesResponse = await DioClient.get('/barber/availability/schedules/');
      
      // Carregar dias de folga
      final offDaysResponse = await DioClient.get('/barber/availability/off-days/');
      
      // Tratar resposta da API (pode ser List ou Map com 'results')
      List<Map<String, dynamic>> schedules;
      if (schedulesResponse.data is List) {
        schedules = List<Map<String, dynamic>>.from(schedulesResponse.data);
      } else if (schedulesResponse.data is Map && schedulesResponse.data['results'] != null) {
        schedules = List<Map<String, dynamic>>.from(schedulesResponse.data['results']);
      } else {
        schedules = [];
      }
      
      List<Map<String, dynamic>> offDays;
      if (offDaysResponse.data is List) {
        offDays = List<Map<String, dynamic>>.from(offDaysResponse.data);
      } else if (offDaysResponse.data is Map && offDaysResponse.data['results'] != null) {
        offDays = List<Map<String, dynamic>>.from(offDaysResponse.data['results']);
      } else {
        offDays = [];
      }
      
      // Se não houver horários configurados, criar padrão (Ter-Sáb, 9:30-19:00)
      if (schedules.isEmpty) {
        debugPrint('📅 Criando horários padrão...');
        schedules = _createDefaultSchedules();
        await _saveDefaultSchedules();
      }
      
      setState(() {
        _schedules = schedules;
        _offDays = offDays;
        _isLoading = false;
      });
      
      debugPrint('✅ Disponibilidade carregada');
    } on ApiException catch (e) {
      debugPrint('❌ Erro: ${e.message}');
      if (mounted) {
        SnackBarUtils.showError(context, e.message);
      }
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('❌ Erro inesperado: $e');
      if (mounted) {
        SnackBarUtils.showError(context, 'Erro ao carregar disponibilidade');
      }
      setState(() => _isLoading = false);
    }
  }
  
  /// Cria horários padrão: Terça a Sábado, 9:30 às 19:00
  List<Map<String, dynamic>> _createDefaultSchedules() {
    return [
      // Segunda - Indisponível
      {'weekday': 1, 'start_time': '09:30', 'end_time': '19:00', 'is_available': false},
      // Terça - Disponível
      {'weekday': 2, 'start_time': '09:30', 'end_time': '19:00', 'is_available': true},
      // Quarta - Disponível
      {'weekday': 3, 'start_time': '09:30', 'end_time': '19:00', 'is_available': true},
      // Quinta - Disponível
      {'weekday': 4, 'start_time': '09:30', 'end_time': '19:00', 'is_available': true},
      // Sexta - Disponível
      {'weekday': 5, 'start_time': '09:30', 'end_time': '19:00', 'is_available': true},
      // Sábado - Disponível
      {'weekday': 6, 'start_time': '09:30', 'end_time': '19:00', 'is_available': true},
      // Domingo - Indisponível
      {'weekday': 7, 'start_time': '09:30', 'end_time': '19:00', 'is_available': false},
    ];
  }
  
  /// Salva os horários padrão no backend
  Future<void> _saveDefaultSchedules() async {
    try {
      final defaultSchedules = _createDefaultSchedules();
      
      for (var schedule in defaultSchedules) {
        await DioClient.post(
          '/barber/availability/schedules/',
          data: schedule,
        );
      }
      
      debugPrint('✅ Horários padrão criados com sucesso');
    } catch (e) {
      debugPrint('❌ Erro ao criar horários padrão: $e');
    }
  }

  /// Normaliza horários no formato HH:MM (remove segundos se existir)
  String _normalizeTime(String time) {
    if (time.isEmpty) return '09:30';
    // Remove segundos se existir (ex: "09:30:00" -> "09:30")
    final parts = time.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return time;
  }

  void _showWeekdayScheduleDialog(int weekday) {
    // Buscar horário existente para esse dia
    final existing = _schedules.firstWhere(
      (s) => s['weekday'] == weekday,
      orElse: () => {},
    );

    // Normalizar horários removendo segundos se existir
    String startTime = _normalizeTime(existing['start_time'] ?? '09:30');
    String endTime = _normalizeTime(existing['end_time'] ?? '19:00');
    bool isAvailable = existing['is_available'] ?? (weekday >= 2 && weekday <= 6); // Ter-Sáb padrão
    
    // Validar se os horários estão na lista de slots disponíveis
    if (!_timeSlots.contains(startTime)) {
      debugPrint('⚠️ Horário inicial "$startTime" não encontrado nos slots, usando 09:30');
      startTime = '09:30';
    }
    if (!_timeSlots.contains(endTime)) {
      debugPrint('⚠️ Horário final "$endTime" não encontrado nos slots, usando 19:00');
      endTime = '19:00';
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            _weekdayNames[weekday]!,
            style: AppTextStyles.titleLarge.copyWith(color: AppColors.gold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Disponível'),
                value: isAvailable,
                activeThumbColor: AppColors.gold,
                onChanged: (value) {
                  setDialogState(() => isAvailable = value);
                },
              ),
              if (isAvailable) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: startTime,
                  decoration: const InputDecoration(
                    labelText: 'Horário de Início',
                    prefixIcon: Icon(Icons.schedule),
                  ),
                  items: _timeSlots.map((time) {
                    return DropdownMenuItem(
                      value: time,
                      child: Text(time),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => startTime = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: endTime,
                  decoration: const InputDecoration(
                    labelText: 'Horário de Término',
                    prefixIcon: Icon(Icons.schedule),
                  ),
                  items: _timeSlots.map((time) {
                    return DropdownMenuItem(
                      value: time,
                      child: Text(time),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => endTime = value);
                    }
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                _saveWeekdaySchedule(weekday, startTime, endTime, isAvailable);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
              ),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveWeekdaySchedule(
    int weekday,
    String startTime,
    String endTime,
    bool isAvailable,
  ) async {
    try {
      debugPrint('🔵 Salvando horário: $weekday, $startTime-$endTime, disponível: $isAvailable');
      
      // Buscar se já existe um horário para esse dia
      final existing = _schedules.firstWhere(
        (s) => s['weekday'] == weekday,
        orElse: () => {},
      );
      
      if (existing.isNotEmpty && existing['id'] != null) {
        // Atualizar horário existente (PUT/PATCH)
        debugPrint('📝 Atualizando horário existente ID: ${existing['id']}');
        await DioClient.put(
          '/barber/availability/schedules/${existing['id']}/',
          data: {
            'weekday': weekday,
            'start_time': startTime,
            'end_time': endTime,
            'is_available': isAvailable,
          },
        );
      } else {
        // Criar novo horário (POST)
        debugPrint('➕ Criando novo horário');
        await DioClient.post(
          '/barber/availability/schedules/',
          data: {
            'weekday': weekday,
            'start_time': startTime,
            'end_time': endTime,
            'is_available': isAvailable,
          },
        );
      }
      
      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Horário atualizado com sucesso!');
      }
      
      await _loadAvailability();
    } on ApiException catch (e) {
      debugPrint('❌ Erro ApiException: ${e.message}');
      if (mounted) {
        SnackBarUtils.showError(context, e.message);
      }
    } catch (e) {
      debugPrint('❌ Erro genérico: $e');
      if (mounted) {
        SnackBarUtils.showError(context, 'Erro ao salvar horário');
      }
    }
  }

  void _showAddOffDayDialog() {
    DateTime selectedDate = DateTime.now();
    bool isAllDay = true;
    String startTime = '09:30';
    String endTime = '19:00';
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Marcar Indisponibilidade',
            style: TextStyle(color: AppColors.gold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Seletor de data
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: AppColors.gold),
                  title: const Text('Data'),
                  subtitle: Text(
                    '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}',
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppColors.gold,
                              surface: AppColors.surface,
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
                const SizedBox(height: 16),
                
                // Dia todo ou período
                SwitchListTile(
                  title: const Text('Dia Todo'),
                  value: isAllDay,
                  activeThumbColor: AppColors.gold,
                  onChanged: (value) {
                    setDialogState(() => isAllDay = value);
                  },
                ),
                
                if (!isAllDay) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: startTime,
                    decoration: const InputDecoration(
                      labelText: 'Início',
                      prefixIcon: Icon(Icons.schedule),
                    ),
                    items: _timeSlots.map((time) {
                      return DropdownMenuItem(value: time, child: Text(time));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => startTime = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: endTime,
                    decoration: const InputDecoration(
                      labelText: 'Término',
                      prefixIcon: Icon(Icons.schedule),
                    ),
                    items: _timeSlots.map((time) {
                      return DropdownMenuItem(value: time, child: Text(time));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => endTime = value);
                      }
                    },
                  ),
                ],
                
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Motivo (opcional)',
                    hintText: 'Ex: Férias, Compromisso pessoal',
                    prefixIcon: Icon(Icons.notes),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                _saveOffDay(
                  selectedDate,
                  isAllDay,
                  startTime,
                  endTime,
                  reasonController.text,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
              ),
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveOffDay(
    DateTime date,
    bool isAllDay,
    String startTime,
    String endTime,
    String reason,
  ) async {
    try {
      await DioClient.post(
        '/barber/availability/off-days/',
        data: {
          'date': date.toIso8601String().split('T')[0],
          'is_all_day': isAllDay,
          if (!isAllDay) 'start_time': startTime,
          if (!isAllDay) 'end_time': endTime,
          if (reason.isNotEmpty) 'reason': reason,
        },
      );
      
      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Folga adicionada com sucesso!');
      }
      
      _loadAvailability();
    } on ApiException catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, e.message);
      }
    }
  }

  Future<void> _deleteOffDay(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Confirmar Exclusão'),
        content: const Text('Deseja remover este período de folga?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DioClient.delete('/barber/availability/off-days/$id/');
        if (mounted) {
          SnackBarUtils.showSuccess(context, 'Folga removida!');
        }
        _loadAvailability();
      } on ApiException catch (e) {
        if (mounted) {
          SnackBarUtils.showError(context, e.message);
        }
      }
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Minha Disponibilidade'),
        backgroundColor: AppColors.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAvailability,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informação sobre disponibilidade padrão
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.gold.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppColors.gold,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Disponibilidade Padrão',
                                  style: AppTextStyles.titleSmall.copyWith(
                                    color: AppColors.gold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Você está disponível de Terça a Sábado, das 9:30 às 19:00. Para cancelar algum dia ou horário, use as opções abaixo.',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Horários da Semana
                    _buildSectionTitle('Horários Padrão da Semana'),
                    const SizedBox(height: 12),
                    _buildWeekdaySchedules(),
                    
                    const SizedBox(height: 32),
                    
                    // Dias de Folga
                    _buildSectionTitle('Dias/Períodos de Folga'),
                    const SizedBox(height: 12),
                    _buildOffDays(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOffDayDialog,
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.event_busy),
        label: const Text('Marcar Indisponibilidade'),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.titleLarge.copyWith(
        color: AppColors.gold,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildWeekdaySchedules() {
    return Column(
      children: List.generate(7, (index) {
        final weekday = index + 1;
        final schedule = _schedules.firstWhere(
          (s) => s['weekday'] == weekday,
          orElse: () => {'is_available': false},
        );
        
        final isAvailable = schedule['is_available'] ?? false;
        final startTime = schedule['start_time'] ?? '--:--';
        final endTime = schedule['end_time'] ?? '--:--';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: AppColors.surface,
          child: ListTile(
            leading: Icon(
              isAvailable ? Icons.check_circle : Icons.cancel,
              color: isAvailable ? Colors.green : Colors.red,
            ),
            title: Text(_weekdayNames[weekday]!),
            subtitle: Text(
              isAvailable ? '$startTime - $endTime' : 'Indisponível',
              style: TextStyle(
                color: isAvailable ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: AppColors.gold),
              onPressed: () => _showWeekdayScheduleDialog(weekday),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildOffDays() {
    if (_offDays.isEmpty) {
      return Card(
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.event_available, size: 48, color: Colors.white24),
                const SizedBox(height: 8),
                Text(
                  'Nenhuma indisponibilidade agendada',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Você está disponível em todos os horários configurados',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: _offDays.map((offDay) {
        final isAllDay = offDay['is_all_day'] ?? true;
        final date = _formatDate(offDay['date']);
        final reason = offDay['reason'] ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: AppColors.surface,
          child: ListTile(
            leading: const Icon(Icons.event_busy, color: Colors.orange),
            title: Text(date),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAllDay
                      ? 'Dia Todo'
                      : '${offDay['start_time']} - ${offDay['end_time']}',
                ),
                if (reason.isNotEmpty)
                  Text(
                    reason,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteOffDay(offDay['id']),
            ),
          ),
        );
      }).toList(),
    );
  }
}
