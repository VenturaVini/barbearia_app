import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/network/dio_client.dart';
import 'confirm_appointment_page.dart';

class SelectDateTimePage extends StatefulWidget {
  final Map<String, dynamic> service;
  final Map<String, dynamic> barber;

  const SelectDateTimePage({
    super.key,
    required this.service,
    required this.barber,
  });

  @override
  State<SelectDateTimePage> createState() => _SelectDateTimePageState();
}

class _SelectDateTimePageState extends State<SelectDateTimePage> {
  DateTime? _selectedDate;
  String? _selectedTime;
  List<String> _availableTimes = [];
  bool _isLoadingTimes = false;

  /// Retorna o nome do dia da semana em português
  String _getWeekdayName(int weekday) {
    const weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return weekdays[weekday - 1];
  }

  /// Retorna o nome do mês em português
  String _getMonthName(int month) {
    const months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return months[month - 1];
  }
  
  /// Carrega horários disponíveis do barbeiro para a data selecionada
  Future<void> _loadAvailableTimes(DateTime date) async {
    setState(() {
      _isLoadingTimes = true;
      _selectedTime = null;
    });
    
    try {
      final barberId = widget.barber['id'];
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      debugPrint('🔵 Carregando horários disponíveis para barbeiro $barberId na data $dateStr');
      
      final response = await DioClient.get(
        '/appointments/available_times/',
        queryParameters: {
          'barber_id': barberId,
          'date': dateStr,
          'service_id': widget.service['id'], // Adicionar service_id para cálculo correto
        },
      );
      
      final data = response.data;
      List<String> times = [];
      
      if (data is Map && data.containsKey('available_times')) {
        times = List<String>.from(data['available_times']);
      } else if (data is List) {
        times = List<String>.from(data);
      }
      
      debugPrint('✅ ${times.length} horários disponíveis encontrados');
      
      setState(() {
        _availableTimes = times;
        _isLoadingTimes = false;
      });
    } catch (e) {
      debugPrint('❌ Erro ao carregar horários: $e');
      
      // Fallback: horários padrão se houver erro (intervalos de 5 minutos)
      setState(() {
        _availableTimes = [
          '09:00', '09:05', '09:10', '09:15', '09:20', '09:25', '09:30', '09:35', '09:40', '09:45', '09:50', '09:55',
          '10:00', '10:05', '10:10', '10:15', '10:20', '10:25', '10:30', '10:35', '10:40', '10:45', '10:50', '10:55',
          '11:00', '11:05', '11:10', '11:15', '11:20', '11:25', '11:30', '11:35', '11:40', '11:45', '11:50', '11:55',
          '14:00', '14:05', '14:10', '14:15', '14:20', '14:25', '14:30', '14:35', '14:40', '14:45', '14:50', '14:55',
          '15:00', '15:05', '15:10', '15:15', '15:20', '15:25', '15:30', '15:35', '15:40', '15:45', '15:50', '15:55',
          '16:00', '16:05', '16:10', '16:15', '16:20', '16:25', '16:30', '16:35', '16:40', '16:45', '16:50', '16:55',
          '17:00', '17:05', '17:10', '17:15', '17:20', '17:25', '17:30', '17:35', '17:40', '17:45', '17:50', '17:55',
          '18:00', '18:05', '18:10', '18:15', '18:20', '18:25', '18:30', '18:35', '18:40', '18:45', '18:50', '18:55',
        ];
        _isLoadingTimes = false;
      });
    }
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedTime = null; // Reset time when date changes
    });
    
    // Carregar horários disponíveis para esta data
    _loadAvailableTimes(date);
  }

  void _selectTime(String time) {
    setState(() {
      _selectedTime = time;
    });
  }

  void _continue() {
    if (_selectedDate == null) {
      SnackBarUtils.showWarning(context, 'Selecione uma data');
      return;
    }
    if (_selectedTime == null) {
      SnackBarUtils.showWarning(context, 'Selecione um horário');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmAppointmentPage(
          service: widget.service,
          barber: widget.barber,
          date: _selectedDate!,
          time: _selectedTime!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Selecione Data e Horário'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Service and Barber Info
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.content_cut, color: AppColors.gold),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.service['name'] ?? '',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person, color: AppColors.gold),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.barber['full_name'] ?? 
                        '${widget.barber['first_name'] ?? ''} ${widget.barber['last_name'] ?? ''}'.trim(),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Selection
                  Text(
                    'Selecione a Data',
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 14, // Next 14 days
                      itemBuilder: (context, index) {
                        final date =
                            DateTime.now().add(Duration(days: index));
                        final isSelected = _selectedDate != null &&
                            _selectedDate!.year == date.year &&
                            _selectedDate!.month == date.month &&
                            _selectedDate!.day == date.day;

                        return GestureDetector(
                          onTap: () => _selectDate(date),
                          child: Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.gold
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.gold
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _getWeekdayName(date.weekday),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: isSelected
                                        ? AppColors.primaryDark
                                        : AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  date.day.toString(),
                                  style: AppTextStyles.headlineMedium.copyWith(
                                    color: isSelected
                                        ? AppColors.primaryDark
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getMonthName(date.month),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: isSelected
                                        ? AppColors.primaryDark
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Time Selection
                  Text(
                    'Selecione o Horário',
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  if (_selectedDate == null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Selecione uma data primeiro',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    )
                  else if (_isLoadingTimes)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_availableTimes.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.event_busy,
                              size: 48,
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhum horário disponível\nnesté dia',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 2,
                      ),
                      itemCount: _availableTimes.length,
                      itemBuilder: (context, index) {
                        final time = _availableTimes[index];
                        final isSelected = _selectedTime == time;

                        return GestureDetector(
                          onTap: () => _selectTime(time),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.gold
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.gold
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                time,
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: isSelected
                                      ? AppColors.primaryDark
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: _continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 4,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Continuar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
