import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/snackbar_utils.dart';

class ManageBarberServicesPage extends StatefulWidget {
  const ManageBarberServicesPage({super.key});

  @override
  State<ManageBarberServicesPage> createState() => _ManageBarberServicesPageState();
}

class _ManageBarberServicesPageState extends State<ManageBarberServicesPage> {
  List<Map<String, dynamic>> _allServices = [];
  List<int> _myServiceIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      debugPrint('🔵 Carregando todos os serviços...');
      // Carregar todos os serviços
      final servicesResponse = await DioClient.get('/services/');
      final servicesData = servicesResponse.data;
      final List allServices;
      if (servicesData is Map && servicesData.containsKey('results')) {
        allServices = servicesData['results'] as List;
      } else if (servicesData is List) {
        allServices = servicesData;
      } else {
        allServices = [];
      }

      debugPrint('🔵 Carregando meus serviços...');
      // Carregar serviços do barbeiro
      final myServicesResponse = await DioClient.get('/services/barber/my-services/');
      final myServicesData = myServicesResponse.data;
      
      // Tratar resposta (pode ser List direto ou List dentro de 'results')
      final List myServicesList;
      if (myServicesData is Map && myServicesData.containsKey('results')) {
        myServicesList = myServicesData['results'] as List;
      } else if (myServicesData is List) {
        myServicesList = myServicesData;
      } else {
        myServicesList = [];
      }
      
      final List<int> myServiceIds = myServicesList.map((s) => s['id'] as int).toList();
      
      debugPrint('✅ Serviços carregados - Total: ${allServices.length}, Meus: ${myServiceIds.length}');

      setState(() {
        _allServices = allServices.map((s) => Map<String, dynamic>.from(s)).toList();
        _myServiceIds = myServiceIds;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erro ao carregar serviços: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        SnackBarUtils.showError(context, 'Erro ao carregar serviços');
      }
    }
  }

  Future<void> _toggleService(int serviceId, bool isActive) async {
    try {
      debugPrint('🔵 Alterando serviço $serviceId para ${isActive ? "ativo" : "inativo"}');
      
      if (isActive) {
        // Adicionar serviço
        await DioClient.post('/services/barber/my-services/', data: {'service_id': serviceId});
        
        setState(() {
          _myServiceIds.add(serviceId);
        });
        
        if (mounted) {
          SnackBarUtils.showSuccess(context, 'Serviço adicionado aos seus serviços');
        }
      } else {
        // Remover serviço
        await DioClient.delete('/services/barber/my-services/$serviceId/');
        
        setState(() {
          _myServiceIds.remove(serviceId);
        });
        
        if (mounted) {
          SnackBarUtils.showSuccess(context, 'Serviço removido dos seus serviços');
        }
      }
      
      debugPrint('✅ Serviço alterado com sucesso');
    } on ApiException catch (e) {
      debugPrint('❌ Erro ApiException: ${e.message}');
      if (mounted) {
        SnackBarUtils.showError(context, e.message);
      }
    } catch (e) {
      debugPrint('❌ Erro genérico: $e');
      if (mounted) {
        SnackBarUtils.showError(context, 'Erro ao atualizar serviço');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: Text('Meus Serviços', style: AppTextStyles.headlineMedium),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.gold, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Seus Serviços',
                              style: AppTextStyles.titleLarge.copyWith(
                                color: AppColors.gold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Selecione apenas os serviços que você oferece. Os clientes só poderão agendar com você os serviços marcados.',
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
                
                // Estatísticas
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total de Serviços',
                        _allServices.length.toString(),
                        Icons.content_cut,
                        AppColors.info,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Meus Serviços',
                        _myServiceIds.length.toString(),
                        Icons.check_circle,
                        AppColors.gold,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Lista de serviços
                ..._allServices.map((service) {
                  final serviceId = service['id'] as int;
                  final isActive = _myServiceIds.contains(serviceId);
                  
                  return Card(
                    color: AppColors.surface,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: SwitchListTile(
                      value: isActive,
                      onChanged: (value) => _toggleService(serviceId, value),
                      activeThumbColor: AppColors.gold,
                      secondary: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isActive 
                              ? AppColors.gold.withOpacity(0.2)
                              : AppColors.muted.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.content_cut,
                          color: isActive ? AppColors.gold : AppColors.textMuted,
                        ),
                      ),
                      title: Text(
                        service['name'] ?? '',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (service['description'] != null && 
                              service['description'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                service['description'],
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.access_time, 
                                   size: 16, 
                                   color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                '${service['duration_minutes']} min',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(Icons.attach_money, 
                                   size: 16, 
                                   color: AppColors.gold),
                              Text(
                                'R\$ ${service['price']}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                }),
                
                const SizedBox(height: 80),
              ],
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.displaySmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
