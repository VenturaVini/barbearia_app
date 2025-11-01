import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/snackbar_utils.dart';
import '../auth/presentation/bloc/auth_bloc.dart';
import '../auth/presentation/bloc/auth_event.dart';
import '../auth/presentation/bloc/auth_state.dart';

/// Página de Edição de Perfil do Barbeiro
class EditBarberProfilePage extends StatefulWidget {
  const EditBarberProfilePage({super.key});

  @override
  State<EditBarberProfilePage> createState() => _EditBarberProfilePageState();
}

class _EditBarberProfilePageState extends State<EditBarberProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _avatarUrlController = TextEditingController();

  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  String? _selectedImagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final state = context.read<AuthBloc>().state;
    if (state is Authenticated) {
      final user = state.user;
      _firstNameController.text = user.firstName ?? '';
      _lastNameController.text = user.lastName ?? '';
      _phoneController.text = user.phone ?? '';
      _avatarUrlController.text = user.avatarUrl ?? '';
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
        SnackBarUtils.showSuccess(context, 'Foto selecionada com sucesso!');
      }
    } catch (e) {
      SnackBarUtils.showError(context, 'Erro ao selecionar imagem');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.gold),
              title: const Text('Câmera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.gold),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link, color: AppColors.gold),
              title: const Text('URL da Imagem'),
              onTap: () {
                Navigator.pop(context);
                _showUrlDialog();
              },
            ),
            if (_selectedImagePath != null || _avatarUrlController.text.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remover Foto'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImagePath = null;
                    _avatarUrlController.clear();
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showUrlDialog() {
    final urlController = TextEditingController(text: _avatarUrlController.text);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('URL da Imagem'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            hintText: 'https://exemplo.com/foto.jpg',
            labelText: 'URL',
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _avatarUrlController.text = urlController.text;
                _selectedImagePath = null;
              });
              Navigator.pop(context);
              SnackBarUtils.showSuccess(context, 'URL da foto atualizada!');
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(UpdateProfileRequested(
        firstName: _firstNameController.text.isNotEmpty ? _firstNameController.text : null,
        lastName: _lastNameController.text.isNotEmpty ? _lastNameController.text : null,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        avatarUrl: _avatarUrlController.text.isNotEmpty ? _avatarUrlController.text : null,
      ));
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: AppColors.surface,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is ProfileUpdated) {
            SnackBarUtils.showSuccess(context, 'Perfil atualizado com sucesso!');
            Navigator.pop(context);
          } else if (state is AuthError) {
            SnackBarUtils.showError(context, state.message);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          final user = state is Authenticated ? state.user : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar com botão de editar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.gold,
                        backgroundImage: _avatarUrlController.text.isNotEmpty
                            ? NetworkImage(_avatarUrlController.text)
                            : null,
                        child: _avatarUrlController.text.isEmpty
                            ? Text(
                                (user?.fullName ?? 'B')[0].toUpperCase(),
                                style: AppTextStyles.displayLarge.copyWith(
                                  color: AppColors.primaryDark,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primaryDark,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: AppColors.primaryDark,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Dados permanentes (não editáveis)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.gold.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lock, color: AppColors.gold, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Dados permanentes',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.gold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildReadOnlyField(
                          label: 'Usuário',
                          value: user?.username ?? '',
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 12),
                        _buildReadOnlyField(
                          label: 'E-mail',
                          value: user?.email ?? '',
                          icon: Icons.email,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Campos editáveis
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, informe seu nome';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Sobrenome',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, informe seu sobrenome';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Telefone',
                      prefixIcon: Icon(Icons.phone),
                      hintText: '(00) 00000-0000',
                    ),
                    inputFormatters: [_phoneMask],
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final unmasked = _phoneMask.getUnmaskedText();
                        if (unmasked.length != 11) {
                          return 'Telefone inválido';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Botão Salvar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.primaryDark,
                        padding: const EdgeInsets.all(16),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryDark,
                              ),
                            )
                          : const Text('Salvar Alterações'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 20),
        const SizedBox(width: 12),
        Expanded(
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
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
