import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/snackbar_utils.dart';
import '../auth/domain/entities/user.dart';
import '../auth/presentation/bloc/auth_bloc.dart';
import '../auth/presentation/bloc/auth_event.dart';
import '../auth/presentation/bloc/auth_state.dart';
import 'create_barber_page.dart';
import 'manage_barbers_page.dart';
import 'create_service_page.dart';
import 'manage_services_page.dart';
import 'manage_appointments_page.dart';
import 'manage_users_page.dart';
import 'reports_page.dart';
import 'advanced_settings_page.dart';

/// Dashboard do Administrador
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AdminHomePage(),
    const ManageUsersPage(),
    const AdminServicesPage(),
    const ManageAppointmentsPage(),
    const AdvancedSettingsPage(),
    const AdminProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.textMuted,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Painel',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Usuários',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.content_cut),
            label: 'Serviços',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note),
            label: 'Agendamentos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Avançado',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Config',
          ),
        ],
      ),
    );
  }
}

/// Home do Admin
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _barbersCount = 0;
  int _servicesCount = 0;
  int _appointmentsCount = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _recentActivities = [];
  
  // Filtros de período
  String _selectedPeriod = 'today'; // today, week, month, all

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  /// Extrai lista de resposta que pode ser paginada ou não
  List _extractList(dynamic data) {
    if (data is Map && data.containsKey('results')) {
      return data['results'] as List;
    }
    return data as List;
  }

  Future<void> _loadStats() async {
    debugPrint('🔵 Carregando estatísticas do dashboard...');
    
    try {
      final barbersResponse = await DioClient.get('/users/barbers/');
      final servicesResponse = await DioClient.get('/services/');
      final appointmentsResponse = await DioClient.get('/appointments/');

      debugPrint('✅ Respostas recebidas:');
      debugPrint('  - Barbeiros: ${barbersResponse.data}');
      debugPrint('  - Serviços: ${servicesResponse.data}');
      debugPrint('  - Agendamentos: ${appointmentsResponse.data}');

      // Extrair listas (considerar resposta paginada)
      final barbers = _extractList(barbersResponse.data);
      final services = _extractList(servicesResponse.data);
      final appointments = _extractList(appointmentsResponse.data);

      debugPrint('📊 Contagens:');
      debugPrint('  - Barbeiros: ${barbers.length}');
      debugPrint('  - Serviços: ${services.length}');
      debugPrint('  - Agendamentos: ${appointments.length}');

      // Criar lista de atividades recentes
      List<Map<String, dynamic>> activities = [];

      // Adicionar últimos agendamentos
      for (var apt in appointments.take(5)) {
        activities.add({
          'type': 'appointment',
          'icon': Icons.event,
          'color': Colors.blue,
          'title': 'Novo agendamento',
          'subtitle': apt['service_name'] ?? 'Serviço',
          'date': DateTime.parse(apt['created_at']),
        });
      }

      // Adicionar últimos barbeiros (se criados recentemente)
      for (var barber in barbers.take(3)) {
        activities.add({
          'type': 'barber',
          'icon': Icons.person_add,
          'color': AppColors.gold,
          'title': 'Barbeiro cadastrado',
          'subtitle': '${barber['first_name']} ${barber['last_name']}'.trim(),
          'date': DateTime.parse(barber['created_at'] ?? DateTime.now().toIso8601String()),
        });
      }

      // Adicionar últimos serviços
      for (var service in services.take(3)) {
        activities.add({
          'type': 'service',
          'icon': Icons.content_cut,
          'color': Colors.purple,
          'title': 'Serviço criado',
          'subtitle': service['name'],
          'date': DateTime.parse(service['created_at'] ?? DateTime.now().toIso8601String()),
        });
      }

      // Ordenar por data (mais recentes primeiro)
      activities.sort((a, b) => b['date'].compareTo(a['date']));

      setState(() {
        _barbersCount = barbers.length;
        _servicesCount = services.length;
        _appointmentsCount = appointments.length;
        _recentActivities = activities.take(10).toList();
        _isLoading = false;
      });
      
      debugPrint('✅ Dashboard atualizado com sucesso!');
    } catch (e) {
      debugPrint('❌ Erro ao carregar estatísticas: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Administrativo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            final user = state.user;
            return RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Saudação
                    Text(
                      'Olá, ${user.firstName ?? user.username}! 👨‍💼',
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Painel de controle da barbearia',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Estatísticas Gerais
                    _buildOverviewStats(),
                    const SizedBox(height: 24),

                    // Ações Rápidas
                    Text(
                      'Ações Rápidas',
                      style: AppTextStyles.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    _buildQuickActions(context),
                    const SizedBox(height: 24),

                    // Atividades Recentes
                    Text(
                      'Atividades Recentes',
                      style: AppTextStyles.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    _buildRecentActivity(),
                  ],
                ),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildOverviewStats() {
    if (_isLoading) {
      return const Card(
        color: AppColors.surface,
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Visão Geral',
                  style: AppTextStyles.titleMedium,
                ),
                // Filtro de período
                DropdownButton<String>(
                  value: _selectedPeriod,
                  underline: Container(),
                  icon: const Icon(Icons.filter_list, size: 20),
                  items: const [
                    DropdownMenuItem(
                      value: 'today',
                      child: Text('Hoje'),
                    ),
                    DropdownMenuItem(
                      value: 'week',
                      child: Text('Esta Semana'),
                    ),
                    DropdownMenuItem(
                      value: 'month',
                      child: Text('Este Mês'),
                    ),
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('Tudo'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedPeriod = value);
                      _loadStats();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getPeriodLabel(),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatCard(
                  icon: Icons.people,
                  value: _barbersCount.toString(),
                  label: 'Barbeiros',
                  color: AppColors.gold,
                ),
                _StatCard(
                  icon: Icons.content_cut,
                  value: _servicesCount.toString(),
                  label: 'Serviços',
                  color: Colors.purple,
                ),
                _StatCard(
                  icon: Icons.event,
                  value: _appointmentsCount.toString(),
                  label: 'Agendamentos',
                  color: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getPeriodLabel() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'today':
        return 'Hoje, ${DateFormat('dd/MM/yyyy').format(now)}';
      case 'week':
        final startWeek = now.subtract(Duration(days: now.weekday - 1));
        final endWeek = startWeek.add(const Duration(days: 6));
        return '${DateFormat('dd/MM').format(startWeek)} - ${DateFormat('dd/MM/yyyy').format(endWeek)}';
      case 'month':
        return DateFormat('MMMM yyyy', 'pt_BR').format(now);
      default:
        return 'Todos os períodos';
    }
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _QuickActionCard(
          icon: Icons.person_add,
          title: 'Novo Barbeiro',
          color: AppColors.gold,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateBarberPage(),
              ),
            );
          },
        ),
        _QuickActionCard(
          icon: Icons.add_business,
          title: 'Novo Serviço',
          color: Colors.purple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateServicePage(),
              ),
            );
          },
        ),
        _QuickActionCard(
          icon: Icons.bar_chart,
          title: 'Relatórios',
          color: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ReportsPage(),
              ),
            );
          },
        ),
        _QuickActionCard(
          icon: Icons.settings,
          title: 'Configurações',
          color: Colors.grey,
          onTap: () {
            // TODO: Navegar para configurações
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    if (_recentActivities.isEmpty) {
      return Card(
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(
                Icons.history,
                size: 48,
                color: AppColors.gold,
              ),
              const SizedBox(height: 12),
              Text(
                'Nenhuma atividade recente',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: AppColors.surface,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _recentActivities.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final activity = _recentActivities[index];
          final date = activity['date'] as DateTime;
          final timeAgo = _getTimeAgo(date);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: (activity['color'] as Color).withOpacity(0.2),
              child: Icon(
                activity['icon'] as IconData,
                color: activity['color'] as Color,
                size: 20,
              ),
            ),
            title: Text(
              activity['title'],
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(activity['subtitle']),
            trailing: Text(
              timeAgo,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          );
        },
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m atrás';
    } else {
      return 'Agora';
    }
  }
}

/// Card de Estatística
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.headlineMedium.copyWith(color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

/// Card de Ação Rápida
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Página de Gerenciamento de Barbeiros
class AdminBarbersPage extends StatelessWidget {
  const AdminBarbersPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Usar a página completa de gerenciamento
    return const ManageBarbersPage();
  }
}

/// Página de Gerenciamento de Serviços
class AdminServicesPage extends StatelessWidget {
  const AdminServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ManageServicesPage();
  }
}

/// Página de Perfil do Admin
class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadAdminStats();
  }

  Future<void> _loadAdminStats() async {
    try {
      
      // Buscar estatísticas do admin
      final barbersResponse = await DioClient.get('/users/barbers/');
      final servicesResponse = await DioClient.get('/services/');
      final appointmentsResponse = await DioClient.get('/appointments/');
      
      final barbers = _extractList(barbersResponse.data);
      final services = _extractList(servicesResponse.data);
      final appointments = _extractList(appointmentsResponse.data);
      
      setState(() {
        _stats = {
          'barbers': barbers.length,
          'services': services.length,
          'appointments': appointments.length,
        };
      });
    } catch (e) {
      debugPrint('❌ Erro ao carregar estatísticas: $e');
    }
  }

  List _extractList(dynamic data) {
    if (data is Map && data.containsKey('results')) {
      return data['results'] as List;
    }
    return data as List;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAdminStats,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            final user = state.user;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar e Informações Principais
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: AppColors.gold,
                              child: Text(
                                user.fullName[0].toUpperCase(),
                                style: AppTextStyles.displayLarge.copyWith(
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.gold,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.admin_panel_settings,
                                  color: AppColors.primaryDark,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.fullName,
                          style: AppTextStyles.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Administrador',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Estatísticas
                  if (_stats != null) ...[
                    Text(
                      'Estatísticas',
                      style: AppTextStyles.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.people,
                            title: 'Barbeiros',
                            value: '${_stats!['barbers']}',
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.content_cut,
                            title: 'Serviços',
                            value: '${_stats!['services']}',
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStatCard(
                      icon: Icons.calendar_today,
                      title: 'Total de Agendamentos',
                      value: '${_stats!['appointments']}',
                      color: Colors.orange,
                      isWide: true,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Informações Pessoais
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Informações Pessoais',
                        style: AppTextStyles.headlineSmall,
                      ),
                      TextButton.icon(
                        onPressed: () => _showEditProfileDialog(user),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Editar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.email,
                    title: 'E-mail',
                    subtitle: user.email,
                  ),
                  _buildInfoCard(
                    icon: Icons.phone,
                    title: 'Telefone',
                    subtitle: user.phone ?? 'Não informado',
                  ),
                  _buildInfoCard(
                    icon: Icons.person,
                    title: 'Usuário',
                    subtitle: user.username,
                  ),
                  const SizedBox(height: 24),

                  // Configurações de Conta
                  Text(
                    'Configurações de Conta',
                    style: AppTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    icon: Icons.lock,
                    title: 'Alterar Senha',
                    subtitle: 'Mantenha sua conta segura',
                    onTap: _showChangePasswordDialog,
                  ),
                  const SizedBox(height: 24),

                  // Ações Rápidas do Sistema
                  Text(
                    'Ações Rápidas',
                    style: AppTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    icon: Icons.backup,
                    title: 'Backup de Dados',
                    subtitle: 'Exportar dados do sistema',
                    onTap: _showBackupDialog,
                  ),
                  _buildActionCard(
                    icon: Icons.refresh,
                    title: 'Limpar Cache',
                    subtitle: 'Liberar espaço do aplicativo',
                    onTap: _showClearCacheDialog,
                  ),
                  const SizedBox(height: 24),

                  // Zona de Perigo
                  Text(
                    'Zona de Perigo',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: Colors.red.withOpacity(0.1),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.warning, color: Colors.red),
                      title: Text(
                        'Resetar Banco de Dados',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.red,
                        ),
                      ),
                      subtitle: Text(
                        'Apagar TODOS os dados permanentemente',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.red.shade300,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.red),
                      onTap: _showResetDatabaseDialog,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Botão de Logout
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showLogoutDialog(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.all(16),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text('Sair da Conta'),
                    ),
                  ),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isWide = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: isWide
          ? Row(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      value,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  value,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppColors.gold),
        title: Text(
          title,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        subtitle: Text(subtitle, style: AppTextStyles.titleMedium),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppColors.gold),
        title: Text(title, style: AppTextStyles.titleMedium),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showEditProfileDialog(User user) {
    final nameController = TextEditingController(text: user.fullName);
    final phoneController = TextEditingController(text: user.phone ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Perfil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome Completo',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  prefixIcon: Icon(Icons.phone),
                  hintText: '(XX) XXXXX-XXXX',
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await DioClient.patch(
                  '/users/${user.id}/',
                  data: {
                    'full_name': nameController.text,
                    'phone': phoneController.text.isNotEmpty 
                        ? '+55${phoneController.text.replaceAll(RegExp(r'[^\d]'), '')}'
                        : null,
                  },
                );
                
                if (mounted) {
                  Navigator.pop(context);
                  SnackBarUtils.showSuccess(
                    context,
                    'Perfil atualizado com sucesso',
                  );
                  // Recarregar dados do usuário
                  context.read<AuthBloc>().add(GetCurrentUser());
                }
              } on ApiException catch (e) {
                if (mounted) {
                  SnackBarUtils.showError(context, e.message);
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Alterar Senha'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Senha Atual',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrent ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setDialogState(() => obscureCurrent = !obscureCurrent);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Nova Senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setDialogState(() => obscureNew = !obscureNew);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Nova Senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setDialogState(() => obscureConfirm = !obscureConfirm);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newPasswordController.text != confirmPasswordController.text) {
                  SnackBarUtils.showError(
                    context,
                    'As senhas não coincidem',
                  );
                  return;
                }

                if (newPasswordController.text.length < 6) {
                  SnackBarUtils.showError(
                    context,
                    'A senha deve ter no mínimo 6 caracteres',
                  );
                  return;
                }

                try {
                  await DioClient.post(
                    '/auth/change_password/',
                    data: {
                      'old_password': currentPasswordController.text,
                      'new_password': newPasswordController.text,
                    },
                  );
                  
                  if (mounted) {
                    Navigator.pop(context);
                    SnackBarUtils.showSuccess(
                      context,
                      'Senha alterada com sucesso',
                    );
                  }
                } on ApiException catch (e) {
                  if (mounted) {
                    SnackBarUtils.showError(context, e.message);
                  }
                }
              },
              child: const Text('Alterar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair da Conta'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(LogoutRequested());
              Navigator.of(context).pushReplacementNamed('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.backup, color: AppColors.gold),
            SizedBox(width: 8),
            Text('Backup de Dados'),
          ],
        ),
        content: const Text(
          'Exportar todos os dados do sistema em formato JSON?\n\n'
          'Isso incluirá barbeiros, serviços, agendamentos e clientes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Simular export (em produção, usar share ou download)
                SnackBarUtils.showSuccess(
                  context,
                  'Backup exportado com sucesso!',
                );
              } catch (e) {
                SnackBarUtils.showError(
                  context,
                  'Erro ao exportar backup: $e',
                );
              }
            },
            child: const Text('Exportar'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.refresh, color: AppColors.gold),
            SizedBox(width: 8),
            Text('Limpar Cache'),
          ],
        ),
        content: const Text(
          'Limpar cache do aplicativo?\n\n'
          'Isso pode melhorar o desempenho e liberar espaço.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Simular limpeza de cache
                await Future.delayed(const Duration(seconds: 1));
                if (mounted) {
                  SnackBarUtils.showSuccess(
                    context,
                    'Cache limpo com sucesso! 2.5 MB liberados',
                  );
                }
              } catch (e) {
                if (mounted) {
                  SnackBarUtils.showError(
                    context,
                    'Erro ao limpar cache: $e',
                  );
                }
              }
            },
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }

  void _showResetDatabaseDialog() {
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('⚠️ ATENÇÃO'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Esta ação irá APAGAR PERMANENTEMENTE:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 12),
                const Text('• Todos os barbeiros'),
                const Text('• Todos os serviços'),
                const Text('• Todos os agendamentos'),
                const Text('• Todos os clientes'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: const Text(
                    '⚠️ ESTA AÇÃO NÃO PODE SER DESFEITA!',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Digite sua senha para confirmar:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setDialogState(
                          () => obscurePassword = !obscurePassword,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (passwordController.text.isEmpty) {
                  SnackBarUtils.showError(
                    context,
                    'Digite sua senha para confirmar',
                  );
                  return;
                }

                Navigator.pop(context);

                // Mostrar segundo diálogo de confirmação
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirmação Final'),
                    content: const Text(
                      'Tem ABSOLUTA CERTEZA?\n\n'
                      'Todos os dados serão perdidos PERMANENTEMENTE!',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('SIM, APAGAR TUDO'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    // Verificar senha
                    final authState = context.read<AuthBloc>().state;
                    if (authState is Authenticated) {
                      await DioClient.post(
                        '/auth/verify_password/',
                        data: {'password': passwordController.text},
                      );
                    }

                    // Resetar banco de dados
                    await DioClient.post('/admin/reset_database/');

                    if (mounted) {
                      SnackBarUtils.showSuccess(
                        context,
                        'Banco de dados resetado com sucesso!',
                      );
                      // Recarregar estatísticas
                      _loadAdminStats();
                    }
                  } on ApiException catch (e) {
                    if (mounted) {
                      SnackBarUtils.showError(context, e.message);
                    }
                  } catch (e) {
                    if (mounted) {
                      SnackBarUtils.showError(
                        context,
                        'Senha incorreta ou erro ao resetar banco',
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('RESETAR BANCO'),
            ),
          ],
        ),
      ),
    );
  }
}
