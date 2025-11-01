import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/client/client_dashboard.dart';
import 'features/barber/barber_dashboard.dart';
import 'features/admin/admin_dashboard.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar dados de locale para português
  await initializeDateFormatting('pt_BR', null);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(authRepository: AuthRepository()),
      child: MaterialApp(
        title: 'Barbearia App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [
          Locale('pt', 'BR'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashPage(),
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/client-dashboard': (context) => const ClientDashboard(),
          '/barber-dashboard': (context) => const BarberDashboard(),
          '/admin-dashboard': (context) => const AdminDashboard(),
        },
      ),
    );
  }
}