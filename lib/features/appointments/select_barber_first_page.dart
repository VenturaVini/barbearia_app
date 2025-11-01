import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/snackbar_utils.dart';
import 'select_service_for_barber_page.dart';

class SelectBarberFirstPage extends StatefulWidget {
  const SelectBarberFirstPage({super.key});

  @override
  State<SelectBarberFirstPage> createState() => _SelectBarberFirstPageState();
}

class _SelectBarberFirstPageState extends State<SelectBarberFirstPage> {
  List<dynamic> _barbers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBarbers();
  }

  Future<void> _loadBarbers() async {
    debugPrint('🔵 [SelectBarber] Carregando barbeiros...');
    setState(() => _isLoading = true);
    
    try {
      final response = await DioClient.get('/users/barbers/');
      debugPrint('🔵 [SelectBarber] Resposta recebida: ${response.data}');
      
      // Filtrar apenas usuários com is_barber = true (garantia adicional)
      final allUsers = response.data as List;
      final onlyBarbers = allUsers.where((user) {
        final isBarber = user['is_barber'] == true;
        // is_active pode não estar no serializer, então considera true se não existir
        final isActive = user['is_active'] ?? true;
        return isBarber && isActive == true;
      }).toList();
      
      setState(() {
        _barbers = onlyBarbers;
        _isLoading = false;
      });
      
      debugPrint('✅ [SelectBarber] ${_barbers.length} barbeiros encontrados (de ${allUsers.length} usuários retornados)');
    } catch (e) {
      debugPrint('❌ [SelectBarber] Erro ao carregar barbeiros: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        SnackBarUtils.showError(context, 'Erro ao carregar barbeiros');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: Text('Escolha seu Barbeiro', style: AppTextStyles.headlineMedium),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _barbers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.person_off,
                        size: 64,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum barbeiro disponível',
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _barbers.length,
                  itemBuilder: (context, index) {
                    final barber = _barbers[index];
                    return _buildBarberCard(barber);
                  },
                ),
    );
  }

  Widget _buildBarberCard(Map<String, dynamic> barber) {
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
              builder: (context) => SelectServiceForBarberPage(
                barberId: barber['id'],
                barberName: barber['full_name'] ?? barber['username'],
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.gold.withOpacity(0.2),
                backgroundImage: barber['avatar_url'] != null
                    ? NetworkImage(barber['avatar_url'])
                    : null,
                child: barber['avatar_url'] == null
                    ? Text(
                        (barber['full_name'] ?? barber['username'] ?? 'B')[0].toUpperCase(),
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              
              // Informações
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      barber['full_name'] ?? barber['username'] ?? 'Barbeiro',
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.verified,
                          size: 16,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Barbeiro Profissional',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Ícone
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
