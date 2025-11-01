import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/snackbar_utils.dart';
import 'select_barber_page.dart';

class SelectServicePage extends StatefulWidget {
  const SelectServicePage({super.key});

  @override
  State<SelectServicePage> createState() => _SelectServicePageState();
}

class _SelectServicePageState extends State<SelectServicePage> {
  List<dynamic> _services = [];
  bool _isLoading = true;
  Map<String, dynamic>? _selectedService;

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
      debugPrint('🔵 [SelectService] Carregando serviços...');
      final response = await DioClient.get('/services/');
      debugPrint('🔵 [SelectService] Resposta recebida: ${response.data}');
      
      // Suporte a paginação
      final data = response.data;
      final List services = data is Map && data.containsKey('results')
          ? data['results'] as List
          : (data as List);
      
      debugPrint('🔵 [SelectService] ${services.length} serviços encontrados');
      
      // Filtrar apenas serviços ativos
      final activeServices = services.where((service) => 
        service['is_active'] == true
      ).toList();
      
      debugPrint('✅ [SelectService] ${activeServices.length} serviços ativos');
      
      setState(() {
        _services = activeServices;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      debugPrint('❌ [SelectService] ApiException: ${e.message}');
      if (mounted) {
        SnackBarUtils.showError(context, e.message);
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ [SelectService] Erro inesperado: $e');
      if (mounted) {
        SnackBarUtils.showError(context, 'Erro ao carregar serviços');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectService(Map<String, dynamic> service) {
    setState(() {
      _selectedService = service;
    });
  }

  void _continue() {
    if (_selectedService == null) {
      SnackBarUtils.showWarning(context, 'Selecione um serviço');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectBarberPage(service: _selectedService!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Selecione o Serviço'),
        backgroundColor: AppColors.surface,
        elevation: 0,
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
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _services.length,
                        itemBuilder: (context, index) {
                          final service =
                              _services[index] as Map<String, dynamic>;
                          final isSelected =
                              _selectedService?['id'] == service['id'];

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
                              leading: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.gold
                                      : AppColors.gold.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.content_cut,
                                  color: isSelected
                                      ? AppColors.primaryDark
                                      : AppColors.gold,
                                  size: 32,
                                ),
                              ),
                              title: Text(
                                service['name'] ?? '',
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
                                  const SizedBox(height: 8),
                                  if (service['description'] != null &&
                                      service['description']
                                          .toString()
                                          .isNotEmpty)
                                    Text(
                                      service['description'],
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textMuted,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${service['duration'] ?? 0} min',
                                        style: AppTextStyles.bodySmall,
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(
                                        Icons.attach_money,
                                        size: 16,
                                        color: AppColors.gold,
                                      ),
                                      Text(
                                        'R\$ ${service['price'] ?? '0.00'}',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.gold,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
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
                              onTap: () => _selectService(service),
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
