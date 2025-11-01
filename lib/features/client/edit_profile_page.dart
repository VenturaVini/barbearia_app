import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/snackbar_utils.dart';
import '../auth/presentation/bloc/auth_bloc.dart';
import '../auth/presentation/bloc/auth_event.dart';
import '../auth/presentation/bloc/auth_state.dart';
import '../auth/domain/entities/user.dart';

/// Tela de Edição de Perfil do Cliente
class EditProfilePage extends StatefulWidget {
  final User user;

  const EditProfilePage({
    super.key,
    required this.user,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _avatarUrlController = TextEditingController();

  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    
    // Preencher com dados atuais
    _firstNameController.text = widget.user.firstName ?? '';
    _lastNameController.text = widget.user.lastName ?? '';
    
    // Formatar telefone se existir
    if (widget.user.phone != null && widget.user.phone!.isNotEmpty) {
      final phone = widget.user.phone!;
      // Remove +55 se presente
      final phoneNumbers = phone.replaceAll('+55', '').replaceAll(RegExp(r'[^0-9]'), '');
      if (phoneNumbers.length == 11) {
        _phoneController.text = _phoneMaskFormatter.maskText(phoneNumbers);
      }
    }
    
    if (widget.user.avatarUrl != null) {
      _avatarUrlController.text = widget.user.avatarUrl!;
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.gold),
              title: const Text('Câmera'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 85,
                );
                if (image != null) {
                  _avatarUrlController.text = image.path;
                  SnackBarUtils.showInfo(context, 'Foto selecionada! (Upload ao salvar)');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.gold),
              title: const Text('Galeria'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 85,
                );
                if (image != null) {
                  _avatarUrlController.text = image.path;
                  SnackBarUtils.showInfo(context, 'Foto selecionada! (Upload ao salvar)');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.link, color: AppColors.gold),
              title: const Text('Informar URL'),
              onTap: () {
                Navigator.pop(context);
                _showUrlDialog();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showUrlDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('URL da Foto'),
        content: TextField(
          controller: _avatarUrlController,
          decoration: const InputDecoration(
            labelText: 'URL',
            hintText: 'https://exemplo.com/foto.jpg',
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
              setState(() {});
              Navigator.pop(context);
              SnackBarUtils.showInfo(context, 'URL atualizada!');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    // Formatar telefone
    String? phoneNumber;
    if (_phoneController.text.isNotEmpty) {
      final unmasked = _phoneMaskFormatter.unmaskText(_phoneController.text);
      phoneNumber = '+55$unmasked';
    }

    // Verificar se houve mudanças
    bool hasChanges = false;
    
    if (_firstNameController.text.trim() != widget.user.firstName) hasChanges = true;
    if (_lastNameController.text.trim() != widget.user.lastName) hasChanges = true;
    if (phoneNumber != widget.user.phone) hasChanges = true;
    if (_avatarUrlController.text.trim() != (widget.user.avatarUrl ?? '')) hasChanges = true;
    
    if (!hasChanges) {
      SnackBarUtils.showInfo(context, 'Nenhuma alteração foi feita');
      return;
    }

    // Disparar evento de atualização
    context.read<AuthBloc>().add(
      UpdateProfileRequested(
        firstName: _firstNameController.text.trim() != widget.user.firstName 
            ? _firstNameController.text.trim() 
            : null,
        lastName: _lastNameController.text.trim() != widget.user.lastName 
            ? _lastNameController.text.trim() 
            : null,
        phone: phoneNumber != widget.user.phone ? phoneNumber : null,
        avatarUrl: _avatarUrlController.text.trim() != (widget.user.avatarUrl ?? '') 
            ? _avatarUrlController.text.trim() 
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is ProfileUpdated) {
            SnackBarUtils.showSuccess(context, 'Perfil atualizado com sucesso!');
            Navigator.pop(context);
          } else if (state is AuthError) {
            SnackBarUtils.showError(context, state.message);
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Avatar com opção de alterar
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: AppColors.gold,
                            backgroundImage: _avatarUrlController.text.isNotEmpty
                                ? NetworkImage(_avatarUrlController.text)
                                : null,
                            child: _avatarUrlController.text.isEmpty
                                ? Text(
                                    widget.user.fullName[0].toUpperCase(),
                                    style: AppTextStyles.displayLarge.copyWith(
                                      color: AppColors.primaryDark,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.gold,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: AppColors.primaryDark,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toque para alterar a foto',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Informações fixas (não editáveis)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline, color: AppColors.gold, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Dados permanentes',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.gold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.account_circle, color: AppColors.textMuted, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Usuário: ',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              Text(
                                widget.user.username,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.email, color: AppColors.textMuted, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Email: ',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  widget.user.email,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Nome
                    TextFormField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        labelText: 'Nome *',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: Validators.required,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Sobrenome
                    TextFormField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        labelText: 'Sobrenome *',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: Validators.required,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Telefone
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Telefone',
                        hintText: '(48) 98888-8888',
                        prefixIcon: const Icon(Icons.phone),
                        helperText: 'Formato: (DDD) 9XXXX-XXXX (celular)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [_phoneMaskFormatter],
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        final unmasked = _phoneMaskFormatter.unmaskText(value);
                        if (unmasked.length != 11) {
                          return 'Telefone deve ter 11 dígitos';
                        }
                        if (!RegExp(r'^[1-9][0-9]9[0-9]{8}$').hasMatch(unmasked)) {
                          return 'Formato inválido. Use: (DDD) 9XXXX-XXXX';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 32),

                    // Botão Salvar
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.primaryDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryDark,
                                ),
                              )
                            : const Text(
                                'Salvar Alterações',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
