import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/constants/app_colors.dart';

class CreateServicePage extends StatefulWidget {
  const CreateServicePage({super.key});

  @override
  State<CreateServicePage> createState() => _CreateServicePageState();
}

class _CreateServicePageState extends State<CreateServicePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _categoryController = TextEditingController();

  bool _isLoading = false;
  bool _isActive = true;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateService() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final requestData = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': _priceController.text.trim(),
      'duration_minutes': int.parse(_durationController.text.trim()),
      'category': _categoryController.text.trim().isEmpty 
          ? 'Geral' 
          : _categoryController.text.trim(),
      'is_active': _isActive,
    };

    debugPrint('🔵 Criando serviço: $requestData');

    try {
      final response = await DioClient.post(
        '/services/',
        data: requestData,
      );

      debugPrint('✅ Serviço criado com sucesso: ${response.data}');

      if (mounted) {
        SnackBarUtils.showSuccess(
          context,
          'Serviço criado com sucesso!',
        );
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      debugPrint('❌ ApiException ao criar serviço: ${e.message}');
      if (mounted) {
        SnackBarUtils.showError(context, e.message);
      }
    } catch (e) {
      debugPrint('❌ Erro inesperado ao criar serviço: $e');
      if (mounted) {
        SnackBarUtils.showError(
          context,
          'Erro inesperado ao criar serviço',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Criar Serviço'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon and Title
              Icon(
                Icons.content_cut,
                size: 64,
                color: AppColors.gold,
              ),
              const SizedBox(height: 16),
              Text(
                'Novo Serviço',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Preencha os dados do novo serviço',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nome *',
                  hintText: 'Ex: Corte de Cabelo',
                  prefixIcon: const Icon(Icons.label),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) => Validators.required(value, 'Nome'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Descreva o serviço',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),

              // Price Field
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Preço (R\$) *',
                  hintText: 'Ex: 50.00',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Preço é obrigatório';
                  }
                  final price = double.tryParse(value.trim());
                  if (price == null || price <= 0) {
                    return 'Preço deve ser maior que zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Duration Field
              TextFormField(
                controller: _durationController,
                decoration: InputDecoration(
                  labelText: 'Duração (minutos) *',
                  hintText: 'Ex: 30',
                  prefixIcon: const Icon(Icons.access_time),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Duração é obrigatória';
                  }
                  final duration = int.tryParse(value.trim());
                  if (duration == null || duration <= 0) {
                    return 'Duração deve ser maior que zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Field
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: 'Categoria',
                  hintText: 'Ex: Corte, Barba, Combo',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 24),

              // Active Switch
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.gold.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.toggle_on,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Serviço Ativo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _isActive 
                                  ? 'Disponível para agendamento'
                                  : 'Não aparecerá para clientes',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                      activeThumbColor: AppColors.gold,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Create Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleCreateService,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 4,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : const Text(
                        'Criar Serviço',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Required fields note
              const Text(
                '* Campos obrigatórios',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white60,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
