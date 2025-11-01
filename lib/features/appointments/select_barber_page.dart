import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/snackbar_utils.dart';
import 'select_datetime_page.dart';

class SelectBarberPage extends StatefulWidget {
  final Map<String, dynamic> service;

  const SelectBarberPage({super.key, required this.service});

  @override
  State<SelectBarberPage> createState() => _SelectBarberPageState();
}

class _SelectBarberPageState extends State<SelectBarberPage> {
  List<dynamic> _barbers = [];
  bool _isLoading = true;
  Map<String, dynamic>? _selectedBarber;

  @override
  void initState() {
    super.initState();
    _loadBarbers();
  }

  Future<void> _loadBarbers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await DioClient.get('/users/barbers/');
      
      // Suporte a paginação
      final data = response.data;
      final List barbers = data is Map && data.containsKey('results')
          ? data['results'] as List
          : (data as List);
      
      // Filtrar apenas barbeiros ativos (verificação dupla de segurança)
      final activeBarbers = barbers.where((barber) {
        // is_active pode não estar no serializer, então considera true se não existir
        final isActive = barber['is_active'] ?? true;
        final isBarber = barber['is_barber'] == true;
        return isActive == true && isBarber;
      }).toList();
      
      debugPrint('✅ ${activeBarbers.length} barbeiros ativos encontrados (de ${barbers.length} usuários retornados)');
      
      setState(() {
        _barbers = activeBarbers;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      debugPrint('❌ Erro ao carregar barbeiros: ${e.message}');
      if (mounted) {
        SnackBarUtils.showError(context, e.message);
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erro inesperado: $e');
      if (mounted) {
        SnackBarUtils.showError(context, 'Erro ao carregar barbeiros');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectBarber(Map<String, dynamic> barber) {
    setState(() {
      _selectedBarber = barber;
    });
  }

  void _continue() {
    if (_selectedBarber == null) {
      SnackBarUtils.showWarning(context, 'Selecione um barbeiro');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectDateTimePage(
          service: widget.service,
          barber: _selectedBarber!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Selecione o Barbeiro'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _barbers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person,
                        size: 64,
                        color: Colors.white24,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nenhum barbeiro disponível',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Service Info Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: AppColors.surface,
                      child: Row(
                        children: [
                          Icon(
                            Icons.content_cut,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.service['name'] ?? '',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: AppColors.gold,
                                  ),
                                ),
                                Text(
                                  'R\$ ${widget.service['price']} • ${widget.service['duration']} min',
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
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _barbers.length,
                        itemBuilder: (context, index) {
                          final barber =
                              _barbers[index] as Map<String, dynamic>;
                          final isSelected =
                              _selectedBarber?['id'] == barber['id'];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: isSelected
                                ? AppColors.gold.withOpacity(0.2)
                                : AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.gold
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                radius: 30,
                                backgroundColor: AppColors.gold,
                                backgroundImage: barber['avatar_url'] != null &&
                                        barber['avatar_url']
                                            .toString()
                                            .isNotEmpty
                                    ? NetworkImage(barber['avatar_url'])
                                    : null,
                                child: barber['avatar_url'] == null ||
                                        barber['avatar_url'].toString().isEmpty
                                    ? Text(
                                        barber['first_name'] != null &&
                                                barber['first_name']
                                                    .toString()
                                                    .isNotEmpty
                                            ? barber['first_name'][0]
                                                .toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryDark,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                '${barber['first_name'] ?? ''} ${barber['last_name'] ?? ''}'
                                    .trim(),
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: isSelected
                                      ? AppColors.gold
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  if (barber['email'] != null)
                                    Text(
                                      barber['email'],
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  if (barber['phone'] != null &&
                                      barber['phone'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone,
                                          size: 14,
                                          color: AppColors.textMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          barber['phone'],
                                          style:
                                              AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check_circle,
                                      color: AppColors.gold,
                                      size: 32,
                                    )
                                  : Icon(
                                      Icons.circle_outlined,
                                      color: AppColors.textMuted,
                                      size: 32,
                                    ),
                              onTap: () => _selectBarber(barber),
                            ),
                          );
                        },
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
