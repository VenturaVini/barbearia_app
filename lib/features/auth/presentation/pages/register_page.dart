import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../data/services/user_validation_service.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

/// Tela de Registro
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // Estados de validação
  bool _checkingEmail = false;
  bool _checkingUsername = false;
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
        _validateEmail();
      } else {
        setState(() {
          _emailError = null;
        });
      }
    });
    
    // Listener para validação de username em tempo real
    _usernameController.addListener(() {
      if (_usernameController.text.length > 2) {
        _validateUsername();
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
    super.dispose();
  }

  /// Validar email em tempo real
  Future<void> _validateEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) return;
    
    setState(() {
      _checkingEmail = true;
      _emailError = null;
    });
    
    // Debounce - esperar 500ms antes de fazer a requisição
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Se o email mudou durante o delay, não fazer a requisição
    if (email != _emailController.text.trim()) {
      setState(() => _checkingEmail = false);
      return;
    }
    
    final exists = await UserValidationService.emailExists(email);
    
    setState(() {
      _checkingEmail = false;
      _emailError = exists ? 'Este e-mail já está cadastrado' : null;
    });
  }
  
  /// Validar username em tempo real
  Future<void> _validateUsername() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty || username.length < 3) return;
    
    setState(() {
      _checkingUsername = true;
      _usernameError = null;
    });
    
    // Debounce - esperar 500ms antes de fazer a requisição
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Se o username mudou durante o delay, não fazer a requisição
    if (username != _usernameController.text.trim()) {
      setState(() => _checkingUsername = false);
      return;
    }
    
    final exists = await UserValidationService.usernameExists(username);
    
    setState(() {
      _checkingUsername = false;
      _usernameError = exists ? 'Este nome de usuário já está em uso' : null;
    });
  }

  void _handleRegister() {
    // Verificar se há erros de validação assíncrona
    if (_emailError != null || _usernameError != null) {
      SnackBarUtils.showError(
        context,
        'Por favor, corrija os erros antes de continuar',
      );
      return;
    }
    
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            RegisterRequested(
              username: _usernameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
              firstName: _firstNameController.text.trim().isEmpty
                  ? null
                  : _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim().isEmpty
                  ? null
                  : _lastNameController.text.trim(),
              phone: _phoneController.text.trim().isEmpty
                  ? null
                  : _phoneMaskFormatter.unmaskText(_phoneController.text),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Conta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            SnackBarUtils.showSuccess(
              context,
              'Conta criada com sucesso!',
            );
            // Voltar para login após sucesso
            Navigator.of(context).pop();
          } else if (state is AuthError) {
            SnackBarUtils.showError(context, state.message);
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Título
                  Text(
                    'Crie sua conta',
                    style: AppTextStyles.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Preencha os dados abaixo',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Nome
                  CustomTextField(
                    controller: _firstNameController,
                    label: 'Nome',
                    hint: 'Digite seu nome',
                    prefixIcon: Icons.person,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Sobrenome
                  CustomTextField(
                    controller: _lastNameController,
                    label: 'Sobrenome',
                    hint: 'Digite seu sobrenome',
                    prefixIcon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Username
                  CustomTextField(
                    controller: _usernameController,
                    label: 'Usuário *',
                    hint: 'Digite um nome de usuário',
                    prefixIcon: Icons.account_circle,
                    validator: (value) {
                      final baseValidation = Validators.username(value);
                      if (baseValidation != null) return baseValidation;
                      if (_usernameError != null) return _usernameError;
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                    suffixIcon: _checkingUsername
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.gold,
                              ),
                            ),
                          )
                        : _usernameError == null && _usernameController.text.length > 2
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                  ),
                  const SizedBox(height: 16),

                  // Email
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email *',
                    hint: 'Digite seu email',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final baseValidation = Validators.email(value);
                      if (baseValidation != null) return baseValidation;
                      if (_emailError != null) return _emailError;
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                    suffixIcon: _checkingEmail
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.gold,
                              ),
                            ),
                          )
                        : _emailError == null && _emailController.text.contains('@')
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                  ),
                  const SizedBox(height: 16),

                  // Telefone
                  CustomTextField(
                    controller: _phoneController,
                    label: 'Telefone',
                    hint: '(11) 98765-4321',
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [_phoneMaskFormatter],
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Senha
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Senha *',
                    hint: 'Digite uma senha (mín. 6 caracteres)',
                    prefixIcon: Icons.lock,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: Validators.password,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Confirmar Senha
                  CustomTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirmar Senha *',
                    hint: 'Digite a senha novamente',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    validator: (value) => Validators.confirmPassword(
                      value,
                      _passwordController.text,
                    ),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleRegister(),
                  ),
                  const SizedBox(height: 32),

                  // Botão de Registro
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return CustomButton(
                        text: 'Criar Conta',
                        onPressed: _handleRegister,
                        isLoading: state is AuthLoading,
                      );
                    },
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
      ),
    );
  }
}
