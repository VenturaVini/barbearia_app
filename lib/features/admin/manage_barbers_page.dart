import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/api_exception.dart';
import 'create_barber_page.dart';

/// Tela de Gerenciamento de Barbeiros
class ManageBarbersPage extends StatefulWidget {
  const ManageBarbersPage({super.key});

  @override
  State<ManageBarbersPage> createState() => _ManageBarbersPageState();
}

class _ManageBarbersPageState extends State<ManageBarbersPage> {
  List<dynamic> _barbers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBarbers();
  }

  Future<void> _loadBarbers() async {
    setState(() => _isLoading = true);

    try {
      final response = await DioClient.get('/users/barbers/');
      setState(() {
        _barbers = response.data as List;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, e.message);
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(
        context,
        'Erro ao carregar barbeiros',
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBarberStatus(int barberId, bool currentStatus) async {
    try {
      await DioClient.patch('/users/$barberId/toggle_barber/');
      
      if (!mounted) return;
      
      SnackBarUtils.showSuccess(
        context,
        currentStatus
            ? 'Barbeiro desativado com sucesso'
            : 'Barbeiro ativado com sucesso',
      );
      
      _loadBarbers(); // Recarregar lista
    } on ApiException catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(
        context,
        'Erro ao alterar status do barbeiro',
      );
    }
  }

  Future<void> _deleteBarber(int barberId, String barberName) async {
    try {
      await DioClient.delete('/users/$barberId/');
      
      if (!mounted) return;
      
      SnackBarUtils.showSuccess(
        context,
        'Barbeiro "$barberName" excluído com sucesso',
      );
      
      _loadBarbers(); // Recarregar lista
    } on ApiException catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(
        context,
        'Erro ao excluir barbeiro',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Barbeiros'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _barbers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.people_outline,
                        size: 80,
                        color: AppColors.gold,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum barbeiro cadastrado',
                        style: AppTextStyles.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Adicione barbeiros à sua equipe',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadBarbers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _barbers.length,
                    itemBuilder: (context, index) {
                      final barber = _barbers[index];
                      final fullName = '${barber['first_name'] ?? ''} ${barber['last_name'] ?? ''}'.trim();
                      final displayName = fullName.isEmpty ? barber['username'] : fullName;
                      
                      return Card(
                        color: AppColors.surface,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.gold,
                            backgroundImage: barber['avatar_url'] != null
                                ? NetworkImage(barber['avatar_url'])
                                : null,
                            child: barber['avatar_url'] == null
                                ? Text(
                                    displayName[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            displayName,
                            style: AppTextStyles.titleMedium,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                barber['email'],
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              if (barber['phone'] != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  barber['phone'],
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: barber['is_barber']
                                      ? AppColors.gold.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  barber['is_barber'] ? 'ATIVO' : 'INATIVO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: barber['is_barber']
                                        ? AppColors.gold
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            icon: const Icon(Icons.more_vert),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'toggle',
                                child: Row(
                                  children: [
                                    Icon(
                                      barber['is_barber']
                                          ? Icons.block
                                          : Icons.check_circle,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      barber['is_barber']
                                          ? 'Desativar'
                                          : 'Ativar',
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'view',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility, size: 20),
                                    SizedBox(width: 8),
                                    Text('Ver Detalhes'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Excluir', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'toggle') {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(
                                      barber['is_barber']
                                          ? 'Desativar Barbeiro?'
                                          : 'Ativar Barbeiro?',
                                    ),
                                    content: Text(
                                      barber['is_barber']
                                          ? 'O barbeiro não poderá mais realizar atendimentos.'
                                          : 'O barbeiro poderá realizar atendimentos novamente.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancelar'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _toggleBarberStatus(
                                            barber['id'],
                                            barber['is_barber'],
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: barber['is_barber']
                                              ? Colors.red
                                              : AppColors.gold,
                                          foregroundColor:
                                              AppColors.primaryDark,
                                        ),
                                        child: Text(
                                          barber['is_barber']
                                              ? 'Desativar'
                                              : 'Ativar',
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              } else if (value == 'view') {
                                _showBarberDetails(barber);
                              } else if (value == 'delete') {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Excluir Barbeiro?'),
                                    content: Text(
                                      'Tem certeza que deseja excluir "${barber['full_name'] ?? barber['username']}"? Esta ação não pode ser desfeita.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancelar'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _deleteBarber(
                                            barber['id'],
                                            barber['full_name'] ?? barber['username'],
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Excluir'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateBarberPage(),
            ),
          );
          
          if (result == true) {
            _loadBarbers(); // Recarregar lista se barbeiro foi criado
          }
        },
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.primaryDark,
        icon: const Icon(Icons.person_add),
        label: const Text('Novo Barbeiro'),
      ),
    );
  }

  void _showBarberDetails(Map<String, dynamic> barber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(barber['full_name'] ?? barber['username']),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (barber['avatar_url'] != null)
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(barber['avatar_url']),
                  ),
                ),
              if (barber['avatar_url'] != null) const SizedBox(height: 16),
              
              _buildDetailRow('Usuário', barber['username']),
              _buildDetailRow('Email', barber['email']),
              if (barber['phone'] != null)
                _buildDetailRow('Telefone', barber['phone']),
              _buildDetailRow(
                'Status',
                barber['is_barber'] ? 'Ativo' : 'Inativo',
              ),
              _buildDetailRow(
                'Tipo',
                barber['user_type'] ?? 'barber',
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.titleMedium,
          ),
        ],
      ),
    );
  }
}
