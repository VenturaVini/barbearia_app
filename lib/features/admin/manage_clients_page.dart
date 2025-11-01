import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/api_exception.dart';

/// Tela de Gerenciamento de Clientes
class ManageClientsPage extends StatefulWidget {
  const ManageClientsPage({super.key});

  @override
  State<ManageClientsPage> createState() => _ManageClientsPageState();
}

class _ManageClientsPageState extends State<ManageClientsPage> {
  List<dynamic> _clients = [];
  List<dynamic> _filteredClients = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  /// Formata data para o formato brasileiro sem usar intl
  String _formatDate(DateTime date, {bool includeTime = false}) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    
    if (includeTime) {
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$day/$month/$year $hour:$minute';
    }
    
    return '$day/$month/$year';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('🔵 Carregando clientes...');
      
      final response = await DioClient.get('/users/');
      
      // Extrair lista (com suporte a paginação)
      final data = response.data;
      final List users = data is Map && data.containsKey('results') 
          ? data['results'] as List
          : (data as List);
      
      // Filtrar apenas clientes (não barbeiros e não staff)
      final clients = users.where((user) => 
        user['is_barber'] == false && user['is_staff'] == false
      ).toList();
      
      debugPrint('✅ ${clients.length} clientes carregados');
      
      setState(() {
        _clients = clients;
        _filteredClients = clients;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      debugPrint('❌ Erro ao carregar clientes: ${e.message}');
      if (!mounted) return;
      SnackBarUtils.showError(context, e.message);
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('❌ Erro inesperado: $e');
      if (!mounted) return;
      SnackBarUtils.showError(
        context,
        'Erro ao carregar clientes',
      );
      setState(() => _isLoading = false);
    }
  }

  void _filterClients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredClients = _clients;
      } else {
        _filteredClients = _clients.where((client) {
          final name = client['full_name']?.toString().toLowerCase() ?? '';
          final email = client['email']?.toString().toLowerCase() ?? '';
          final username = client['username']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          
          return name.contains(searchLower) ||
                 email.contains(searchLower) ||
                 username.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _deleteClient(int clientId, String clientName) async {
    try {
      await DioClient.delete('/users/$clientId/');
      
      if (!mounted) return;
      
      SnackBarUtils.showSuccess(
        context,
        'Cliente "$clientName" excluído com sucesso',
      );
      
      _loadClients();
    } on ApiException catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(
        context,
        'Erro ao excluir cliente',
      );
    }
  }

  void _showDeleteDialog(int clientId, String clientName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Tem certeza que deseja excluir o cliente "$clientName"?\n\n'
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteClient(clientId, clientName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showClientDetails(Map<String, dynamic> client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(client['full_name'] ?? 'Cliente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('ID', '#${client['id']}'),
              _buildDetailRow('Username', client['username'] ?? 'N/A'),
              _buildDetailRow('Email', client['email'] ?? 'N/A'),
              _buildDetailRow('Telefone', client['phone'] ?? 'Não informado'),
              _buildDetailRow(
                'Cadastro',
                client['created_at'] != null
                    ? _formatDate(DateTime.parse(client['created_at']), includeTime: true)
                    : 'N/A',
              ),
              _buildDetailRow(
                'Última Atualização',
                client['updated_at'] != null
                    ? _formatDate(DateTime.parse(client['updated_at']), includeTime: true)
                    : 'N/A',
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
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Clientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadClients,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de pesquisa
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nome, email ou username...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterClients('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.primaryDark,
              ),
              onChanged: _filterClients,
            ),
          ),
          
          // Contador de resultados
          if (!_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surface,
              child: Row(
                children: [
                  Text(
                    '${_filteredClients.length} cliente(s) encontrado(s)',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          
          // Lista de clientes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredClients.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadClients,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredClients.length,
                          itemBuilder: (context, index) {
                            final client = _filteredClients[index];
                            return _buildClientCard(client);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(Map<String, dynamic> client) {
    final createdAt = client['created_at'] != null
        ? DateTime.parse(client['created_at'])
        : null;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showClientDetails(client),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.gold,
                child: Text(
                  (client['full_name'] ?? 'C')[0].toUpperCase(),
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Informações
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client['full_name'] ?? 'Cliente',
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.email, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            client['email'] ?? 'N/A',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (client['phone'] != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            client['phone'],
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (createdAt != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            'Cadastrado em ${_formatDate(createdAt)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Menu de ações
              PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'details',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 20),
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
                  switch (value) {
                    case 'details':
                      _showClientDetails(client);
                      break;
                    case 'delete':
                      _showDeleteDialog(
                        client['id'],
                        client['full_name'] ?? 'Cliente',
                      );
                      break;
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSearch = _searchController.text.isNotEmpty;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearch ? Icons.search_off : Icons.people_outline,
            size: 80,
            color: AppColors.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch
                ? 'Nenhum cliente encontrado'
                : 'Nenhum cliente cadastrado',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch
                ? 'Tente buscar por outro termo'
                : 'Ainda não há clientes no sistema',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
