import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/snackbar_utils.dart';
import 'select_datetime_page.dart';

class SelectServiceForBarberPage extends StatefulWidget {
  final int barberId;
  final String barberName;

  const SelectServiceForBarberPage({
    super.key,
    required this.barberId,
    required this.barberName,
  });

  @override
  State<SelectServiceForBarberPage> createState() => _SelectServiceForBarberPageState();
}

class _SelectServiceForBarberPageState extends State<SelectServiceForBarberPage> {
  List<dynamic> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    debugPrint('🔵 [SelectServiceForBarber] Carregando serviços do barbeiro ${widget.barberId}...');
    setState(() => _isLoading = true);
    
    try {
      // Buscar serviços que este barbeiro oferece
      final response = await DioClient.get('/services/barber/${widget.barberId}/services/');
      debugPrint('🔵 [SelectServiceForBarber] Resposta recebida: ${response.data}');
      
      final data = response.data;
      final List services;
      if (data is Map && data.containsKey('results')) {
        services = data['results'] as List;
      } else if (data is List) {
        services = data;
      } else {
        services = [];
      }
      
      setState(() {
        _services = services;
        _isLoading = false;
      });
      
      debugPrint('✅ [SelectServiceForBarber] ${_services.length} serviços encontrados');
    } catch (e) {
      debugPrint('❌ [SelectServiceForBarber] Erro ao carregar serviços: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        SnackBarUtils.showError(context, 'Erro ao carregar serviços');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Escolha o Serviço', style: AppTextStyles.titleLarge),
            Text(
              'com ${widget.barberName}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.gold),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _services.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.content_cut_outlined,
                        size: 64,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum serviço disponível',
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Este barbeiro ainda não configurou\nseus serviços',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _services.length,
                  itemBuilder: (context, index) {
                    final service = _services[index];
                    return _buildServiceCard(service);
                  },
                ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SelectDateTimePage(
                service: service,
                barber: {
                  'id': widget.barberId,
                  'full_name': widget.barberName,
                },
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ícone
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: service['image_url'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          service['image_url'],
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(
                        Icons.content_cut,
                        color: AppColors.gold,
                        size: 32,
                      ),
              ),
              const SizedBox(width: 16),
              
              // Informações
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service['name'] ?? '',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (service['description'] != null &&
                        service['description'].toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        service['description'],
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
                          '${service['duration_minutes']} min',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.attach_money,
                          size: 16,
                          color: AppColors.gold,
                        ),
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
              ),
              
              // Seta
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.gold,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
