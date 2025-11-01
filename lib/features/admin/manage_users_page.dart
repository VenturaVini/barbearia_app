import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'manage_barbers_page.dart';
import 'manage_clients_page.dart';

/// Página de Gerenciamento de Usuários (Barbeiros e Clientes)
class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Usuários'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(
              icon: Icon(Icons.cut),
              text: 'Barbeiros',
            ),
            Tab(
              icon: Icon(Icons.people),
              text: 'Clientes',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ManageBarbersPage(),
          ManageClientsPage(),
        ],
      ),
    );
  }
}
