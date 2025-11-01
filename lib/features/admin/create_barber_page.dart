import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/api_exception.dart';

/// Tela de Criação de Barbeiro (Admin)
class CreateBarberPage extends StatefulWidget {
  const CreateBarberPage({super.key});

  @override
  State<CreateBarberPage> createState() => _CreateBarberPageState();
}

class _CreateBarberPageState extends State<CreateBarberPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _avatarUrlController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isCheckingEmail = false;
  bool _isCheckingUsername = false;
  String? _emailError;
  String? _usernameError;

  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    
    // Listener para validação de email em tempo real
    _emailController.addListener(() {
      if (_emailController.text.length > 3 && _emailController.text.contains('@')) {
        _checkEmail(_emailController.text.trim());
      } else {
        setState(() {
          _emailError = null;
        });
      }
    });
    
    // Listener para validação de username em tempo real
    _usernameController.addListener(() {
      if (_usernameController.text.length > 2) {
        _checkUsername(_usernameController.text.trim());
      } else {
        setState(() {
          _usernameError = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _checkEmail(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _emailError = null;
        _isCheckingEmail = false;
      });
      return;
    }

    setState(() {
      _isCheckingEmail = true;
      _emailError = null;
    });

    // Debounce - esperar 500ms antes de fazer a requisição
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Se o email mudou durante o delay, não fazer a requisição
    if (email != _emailController.text.trim()) {
      setState(() => _isCheckingEmail = false);
      return;
    }

    try {
      final response = await DioClient.post(
        '/users/check_email/',
        data: {'email': email},
      );

      if (response.data['exists'] == true) {
        setState(() {
          _emailError = 'Este email já está em uso';
          _isCheckingEmail = false;
        });
      } else {
        setState(() {
          _emailError = null;
          _isCheckingEmail = false;
        });
      }
    } catch (e) {
      setState(() {
        _isCheckingEmail = false;
      });
    }
  }

  Future<void> _checkUsername(String username) async {
    if (username.isEmpty || username.length < 3) {
      setState(() {
        _usernameError = null;
        _isCheckingUsername = false;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    // Debounce - esperar 500ms antes de fazer a requisição
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Se o username mudou durante o delay, não fazer a requisição
    if (username != _usernameController.text.trim()) {
      setState(() => _isCheckingUsername = false);
      return;
    }

    try {
      final response = await DioClient.post(
        '/users/check_username/',
        data: {'username': username},
      );

      if (response.data['exists'] == true) {
        setState(() {
          _usernameError = 'Este usuário já está em uso';
          _isCheckingUsername = false;
        });
      } else {
        setState(() {
          _usernameError = null;
          _isCheckingUsername = false;
        });
      }
    } catch (e) {
      setState(() {
        _isCheckingUsername = false;
      });
    }
  }

  Future<void> _handleCreateBarber() async {
    // Validar se há erros de email/username antes de submeter
    if (_emailError != null || _usernameError != null) {
      SnackBarUtils.showError(
        context,
        _emailError ?? _usernameError ?? 'Corrija os erros antes de continuar',
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Formata telefone: unmask remove (), - e espaços. Ex: (48) 98888-8888 → 48988888888
    String? phoneNumber;
    if (_phoneController.text.isNotEmpty) {
      final unmasked = _phoneMaskFormatter.unmaskText(_phoneController.text);
      phoneNumber = '+55$unmasked';  // +5548988888888 (formato internacional)
    }

    final requestData = {
      'username': _usernameController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      if (phoneNumber != null) 'phone': phoneNumber,
      if (_avatarUrlController.text.trim().isNotEmpty)
        'avatar_url': _avatarUrlController.text.trim(),
    };

    debugPrint('🔵 Criando barbeiro: $requestData');

    try {
      final response = await DioClient.post(
        '/users/create_barber/',
        data: requestData,
      );

      debugPrint('✅ Barbeiro criado com sucesso: ${response.data}');

      if (!mounted) return;

      SnackBarUtils.showSuccess(
        context,
        'Barbeiro criado com sucesso!',
      );

      Navigator.pop(context, true); // Retorna true para indicar sucesso
    } on ApiException catch (e) {
      debugPrint('❌ ApiException ao criar barbeiro: ${e.message}');
      if (!mounted) return;
      SnackBarUtils.showError(context, e.message);
    } catch (e) {
      debugPrint('❌ Erro inesperado ao criar barbeiro: $e');
      if (!mounted) return;
      SnackBarUtils.showError(
        context,
        'Erro ao criar barbeiro. Tente novamente.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Barbeiro'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ícone
                const Icon(
                  Icons.person_add,
                  size: 80,
                  color: AppColors.gold,
                ),
                const SizedBox(height: 16),

                // Título
                Text(
                  'Adicionar Barbeiro',
                  style: AppTextStyles.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Preencha os dados do novo barbeiro',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Nome
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: 'Nome *',
                    hintText: 'Digite o nome',
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
                    hintText: 'Digite o sobrenome',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: Validators.required,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Username
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Usuário *',
                    hintText: 'Digite um nome de usuário',
                    prefixIcon: const Icon(Icons.account_circle),
                    suffixIcon: _isCheckingUsername
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _usernameError != null
                            ? const Icon(Icons.error, color: Colors.red)
                            : _usernameController.text.length > 2 && _usernameError == null
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : null,
                    errorText: _usernameError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Username é obrigatório';
                    }
                    if (value.length < 3) {
                      return 'Username deve ter no mínimo 3 caracteres';
                    }
                    return Validators.username(value);
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email *',
                    hintText: 'Digite o email',
                    prefixIcon: const Icon(Icons.email),
                    suffixIcon: _isCheckingEmail
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _emailError != null
                            ? const Icon(Icons.error, color: Colors.red)
                            : _emailController.text.length > 3 && _emailError == null
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : null,
                    errorText: _emailError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email é obrigatório';
                    }
                    return Validators.email(value);
                  },
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
                    if (value == null || value.isEmpty) return null; // Opcional
                    final unmasked = _phoneMaskFormatter.unmaskText(value);
                    if (unmasked.length != 11) {
                      return 'Telefone deve ter 11 dígitos (DDD + 9 números)';
                    }
                    // Validar formato: primeiro dígito do DDD entre 1-9, segundo entre 0-9
                    if (!RegExp(r'^[1-9][0-9]9[0-9]{8}$').hasMatch(unmasked)) {
                      return 'Formato inválido. Use: (DDD) 9XXXX-XXXX';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Avatar URL
                TextFormField(
                  controller: _avatarUrlController,
                  decoration: InputDecoration(
                    labelText: 'Foto do Perfil (URL)',
                    hintText: 'https://exemplo.com/foto.jpg',
                    prefixIcon: const Icon(Icons.image),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Senha
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Senha *',
                    hintText: 'Digite uma senha (mín. 6 caracteres)',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: Validators.password,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Confirmar Senha
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Senha *',
                    hintText: 'Digite a senha novamente',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: _obscureConfirmPassword,
                  validator: (value) => Validators.confirmPassword(
                    value,
                    _passwordController.text,
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleCreateBarber(),
                ),
                const SizedBox(height: 32),

                // Botão de Criar
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleCreateBarber,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.primaryDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryDark,
                            ),
                          )
                        : const Text(
                            'Criar Barbeiro',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Texto de campos obrigatórios
                Text(
                  '* Campos obrigatórios',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
