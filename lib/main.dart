import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/injection_container.dart';
import 'core/utils/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/home/presentation/bloc/home_bloc.dart';
import 'features/recycling/presentation/bloc/recycling_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    await initDependencies();
    debugPrint('✅ Dependencies initialized successfully');
  } catch (e, stack) {
    debugPrint('❌ ERROR en initDependencies: $e');
    debugPrint(stack.toString());
    rethrow;
  }

  runApp(const RecySmartApp());
}

class RecySmartApp extends StatelessWidget {
  const RecySmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authBloc = sl<AuthBloc>();
    final homeBloc = sl<HomeBloc>();
    final recyclingBloc = sl<RecyclingBloc>();

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<HomeBloc>.value(value: homeBloc),
        BlocProvider<RecyclingBloc>.value(value: recyclingBloc),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        // Global listener: handle session expiry from anywhere in the app
        listener: (context, state) {
          if (state is AuthSessionExpired) {
            AppRouter.navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/', (route) => false,
            );
            ScaffoldMessenger.of(
                AppRouter.navigatorKey.currentContext!)
                .showSnackBar(
              const SnackBar(
                content: Text(
                    'Tu sesión ha expirado. Por favor inicia sesión nuevamente.'),
                backgroundColor: AppColors.warning,
                duration: Duration(seconds: 4),
              ),
            );
          }
        },
        child: MaterialApp.router(
          title: 'RecySmart',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.router(authBloc),
        ),
      ),
    );
  }
}