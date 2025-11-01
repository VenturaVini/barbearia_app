import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/snackbar_utils.dart';

class ConfirmAppointmentPage extends StatefulWidget {
  final Map<String, dynamic> service;
  final Map<String, dynamic> barber;
  final DateTime date;
  final String time;

  const ConfirmAppointmentPage({
    super.key,
    required this.service,
    required this.barber,
    required this.date,
    required this.time,
  });

  @override
  State<ConfirmAppointmentPage> createState() => _ConfirmAppointmentPageState();
}

class _ConfirmAppointmentPageState extends State<ConfirmAppointmentPage> {
  bool _isLoading = false;
  final _notesController = TextEditingController();

  /// Formata data completa em português
  String _formatFullDate(DateTime date) {
    const weekdays = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
    const months = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
    ];
    
    final weekday = weekdays[date.weekday - 1];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year;
    
    return '$weekday, $day de $month de $year';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _confirmAppointment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Combinar data e hora
      final timeParts = widget.time.split(':');
      final scheduledFor = DateTime(
        widget.date.year,
        widget.date.month,
        widget.date.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      final requestData = {
        'service': widget.service['id'],
        'barber': widget.barber['id'],
        'scheduled_for': scheduledFor.toIso8601String(),
        'notes': _notesController.text.trim(),
      };

      debugPrint('🔵 Criando agendamento: $requestData');

      final response = await DioClient.post(
        '/appointments/',
        data: requestData,
      );

      debugPrint('✅ Agendamento criado: ${response.data}');

      debugPrint('✅ Agendamento criado: ${response.data}');

      if (mounted) {
        SnackBarUtils.showSuccess(
          context,
          'Agendamento realizado com sucesso!',
        );
        // Voltar para o dashboard (remove todas as páginas do fluxo)
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on ApiException catch (e) {
      debugPrint('❌ ApiException: ${e.message}');
      if (mounted) {
        SnackBarUtils.showError(context, e.message);
      }
    } on DioException catch (e) {
      debugPrint('❌ DioException: ${e.type} - ${e.message}');
      if (mounted) {
        String errorMessage = 'Erro ao realizar agendamento';
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Timeout - Verifique sua conexão';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage = 'Erro de conexão com o servidor';
        } else if (e.response?.data != null) {
          errorMessage = e.response?.data.toString() ?? errorMessage;
        }
        SnackBarUtils.showError(context, errorMessage);
      }
    } catch (e) {
      debugPrint('❌ Erro: $e');
      if (mounted) {
        SnackBarUtils.showError(
          context,
          'Erro inesperado ao realizar agendamento',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = _formatFullDate(widget.date);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Confirmar Agendamento'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Success Icon
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.event_available,
                    size: 80,
                    color: AppColors.gold,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Confirme seu Agendamento',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.gold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Appointment Details
            _buildDetailCard(
              title: 'Serviço',
              icon: Icons.content_cut,
              children: [
                _buildDetailRow('Nome', widget.service['name'] ?? ''),
                _buildDetailRow('Preço', 'R\$ ${widget.service['price']}'),
                _buildDetailRow('Duração', '${widget.service['duration_minutes']} minutos'),
                if (widget.service['category'] != null)
                  _buildDetailRow('Categoria', widget.service['category']),
              ],
            ),
            const SizedBox(height: 16),

            _buildDetailCard(
              title: 'Barbeiro',
              icon: Icons.person,
              children: [
                _buildDetailRow(
                  'Nome',
                  widget.barber['full_name'] ?? 
                  '${widget.barber['first_name'] ?? ''} ${widget.barber['last_name'] ?? ''}'.trim(),
                ),
                if (widget.barber['email'] != null)
                  _buildDetailRow('Email', widget.barber['email']),
                if (widget.barber['phone'] != null &&
                    widget.barber['phone'].toString().isNotEmpty)
                  _buildDetailRow('Telefone', widget.barber['phone']),
              ],
            ),
            const SizedBox(height: 16),

            _buildDetailCard(
              title: 'Data e Horário',
              icon: Icons.calendar_today,
              children: [
                _buildDetailRow('Data', dateFormatted),
                _buildDetailRow('Horário', widget.time),
              ],
            ),
            const SizedBox(height: 24),

            // Notes Field
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notes, color: AppColors.gold),
                      const SizedBox(width: 12),
                      Text(
                        'Observações (Opcional)',
                        style: AppTextStyles.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Adicione observações sobre o agendamento...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Confirm Button
            ElevatedButton(
              onPressed: _isLoading ? null : _confirmAppointment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 4,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle),
                        SizedBox(width: 8),
                        Text(
                          'Confirmar Agendamento',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),

            // Cancel Button
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.gold),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
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
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
