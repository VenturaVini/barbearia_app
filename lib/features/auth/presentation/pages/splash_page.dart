import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Tela de Splash
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    // Navegar após animação (SEM verificar auth automaticamente)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.darkGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo animado
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  children: [
                    // Ícone de tesoura
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                      ),
                      child: const Icon(
                        Icons.content_cut,
                        size: 60,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Nome do app
                    Text(
                      'BARBEARIA',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: AppColors.gold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Subtítulo
                    Text(
                      'Premium Style',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              
              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
