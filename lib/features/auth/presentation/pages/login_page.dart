import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

/// Tela de Login
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            LoginRequested(
              username: _usernameController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            // Roteamento baseado no tipo de usuário
            final userType = state.user.userType;
            if (userType == 'admin') {
              Navigator.pushReplacementNamed(context, '/admin-dashboard');
            } else if (userType == 'barber') {
              Navigator.pushReplacementNamed(context, '/barber-dashboard');
            } else {
              Navigator.pushReplacementNamed(context, '/client-dashboard');
            }
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
                  const SizedBox(height: 40),

                  // Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                    ),
                    child: const Icon(
                      Icons.content_cut,
                      size: 50,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Título
                  Text(
                    'Bem-vindo',
                    style: AppTextStyles.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Faça login para continuar',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Campo Username
                  CustomTextField(
                    controller: _usernameController,
                    label: 'Usuário',
                    hint: 'Digite seu usuário',
                    prefixIcon: Icons.person,
                    validator: Validators.username,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Campo Senha
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Senha',
                    hint: 'Digite sua senha',
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
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                  ),
                  const SizedBox(height: 16),

                  // Manter conectado
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                        activeColor: AppColors.gold,
                      ),
                      Text(
                        'Manter conectado',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Botão de Login
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return CustomButton(
                        text: 'Entrar',
                        onPressed: _handleLogin,
                        isLoading: state is AuthLoading,
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Link para registro
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Não tem uma conta? ',
                        style: AppTextStyles.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: Text(
                          'Cadastre-se',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ],
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
