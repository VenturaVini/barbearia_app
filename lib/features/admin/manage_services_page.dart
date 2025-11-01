import 'package:flutter/material.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/constants/app_colors.dart';
import 'create_service_page.dart';
import 'edit_service_page.dart';

class ManageServicesPage extends StatefulWidget {
  const ManageServicesPage({super.key});

  @override
  State<ManageServicesPage> createState() => _ManageServicesPageState();
}

class _ManageServicesPageState extends State<ManageServicesPage> {
  List<dynamic> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
    });

    debugPrint('🔵 Carregando serviços...');

    try {
      final response = await DioClient.get('/services/');
      debugPrint('✅ Serviços carregados: ${response.data}');
      
      // A resposta é paginada: {count, next, previous, results}
      final data = response.data;
      final List services = data is Map && data.containsKey('results') 
          ? data['results'] as List
          : (data as List); // Fallback para resposta sem paginação
      
      setState(() {
        _services = services;
        _isLoading = false;
      });
      
      debugPrint('📊 Total de serviços: ${_services.length}');
    } on ApiException catch (e) {
      debugPrint('❌ ApiException ao carregar serviços: ${e.message}');
      if (mounted) {
        SnackBarUtils.showError(context, e.message);
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erro inesperado ao carregar serviços: $e');
      if (mounted) {
        SnackBarUtils.showError(
          context,
          'Erro ao carregar serviços',
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleServiceStatus(int id, bool currentStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentStatus ? 'Desativar Serviço?' : 'Ativar Serviço?'),
        content: Text(
          currentStatus
              ? 'Este serviço não aparecerá mais para agendamento.'
              : 'Este serviço voltará a aparecer para agendamento.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await DioClient.patch('/services/$id/toggle/');
      
      if (mounted) {
        SnackBarUtils.showSuccess(
          context,
          currentStatus ? 'Serviço desativado!' : 'Serviço ativado!',
        );
        _loadServices();
      }
    } on ApiException catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          'Erro ao atualizar serviço',
        );
      }
    }
  }

  Future<void> _deleteService(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Serviço?'),
        content: Text(
          'Tem certeza que deseja excluir "$name"? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await DioClient.delete('/services/$id/');
      
      if (mounted) {
        SnackBarUtils.showSuccess(
          context,
          'Serviço excluído com sucesso!',
        );
        _loadServices();
      }
    } on ApiException catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          'Erro ao excluir serviço',
        );
      }
    }
  }

  void _showServiceDetails(Map<String, dynamic> service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(service['name'] ?? ''),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (service['description'] != null &&
                  service['description'].toString().isNotEmpty) ...[
                const Text(
                  'Descrição',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(service['description']),
                const SizedBox(height: 16),
              ],
              _buildDetailRow('Preço', 'R\$ ${service['price'] ?? '0.00'}'),
              _buildDetailRow(
                  'Duração', '${service['duration_minutes'] ?? 0} minutos'),
              _buildDetailRow('Categoria', service['category'] ?? 'Geral'),
              _buildDetailRow(
                'Status',
                (service['is_active'] == true) ? 'Ativo' : 'Inativo',
              ),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Gerenciar Serviços'),
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
                        'Nenhum serviço encontrado',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadServices,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _services.length,
                    itemBuilder: (context, index) {
                      final service = _services[index] as Map<String, dynamic>;
                      final isActive = service['is_active'] == true;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: AppColors.surface,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.gold.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.content_cut,
                              color: AppColors.gold,
                            ),
                          ),
                          title: Text(
                            service['name'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'R\$ ${service['price']} • ${service['duration_minutes'] ?? 0}min',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                service['category'] ?? 'Geral',
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.success.withOpacity(0.2)
                                      : AppColors.error.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isActive ? 'ATIVO' : 'INATIVO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isActive
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                onTap: () {
                                  Future.delayed(
                                    const Duration(milliseconds: 100),
                                    () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EditServicePage(service: service),
                                        ),
                                      );
                                      if (result == true) {
                                        _loadServices();
                                      }
                                    },
                                  );
                                },
                                child: const Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  Future.delayed(
                                    const Duration(milliseconds: 100),
                                    () => _toggleServiceStatus(
                                      service['id'],
                                      isActive,
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Icon(isActive
                                        ? Icons.block
                                        : Icons.check_circle),
                                    const SizedBox(width: 8),
                                    Text(isActive ? 'Desativar' : 'Ativar'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  Future.delayed(
                                    const Duration(milliseconds: 100),
                                    () => _showServiceDetails(service),
                                  );
                                },
                                child: const Row(
                                  children: [
                                    Icon(Icons.info),
                                    SizedBox(width: 8),
                                    Text('Ver Detalhes'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  Future.delayed(
                                    const Duration(milliseconds: 100),
                                    () => _deleteService(
                                      service['id'],
                                      service['name'] ?? '',
                                    ),
                                  );
                                },
                                child: const Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text(
                                      'Excluir',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateServicePage(),
            ),
          );
          if (result == true) {
            _loadServices();
          }
        },
        backgroundColor: AppColors.gold,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
