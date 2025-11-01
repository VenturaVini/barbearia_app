import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../bloc/service_bloc.dart';
import '../bloc/service_event.dart';
import '../bloc/service_state.dart';
import '../widgets/service_card.dart';

/// Página de Listagem de Serviços
class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Serviços'),
        centerTitle: true,
      ),
      body: BlocConsumer<ServiceBloc, ServiceState>(
        listener: (context, state) {
          if (state is ServiceError) {
            SnackBarUtils.showError(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is ServiceInitial) {
            // Carregar serviços na primeira vez
            context.read<ServiceBloc>().add(LoadServices());
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is ServiceLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is ServicesLoaded) {
            if (state.services.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.content_cut,
                      size: 80,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhum serviço disponível',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<ServiceBloc>().add(LoadServices());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.services.length,
                itemBuilder: (context, index) {
                  final service = state.services[index];
                  return ServiceCard(
                    service: service,
                    onTap: () {
                      // TODO: Navegar para detalhes ou seleção
                    },
                  );
                },
              ),
            );
          }

          // Estado de erro
          if (state is ServiceError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar serviços',
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<ServiceBloc>().add(LoadServices());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
