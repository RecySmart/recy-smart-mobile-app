import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/injection_container.dart';
import 'core/utils/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/home/presentation/bloc/home_bloc.dart';
import 'features/recycling/presentation/bloc/recycling_bloc.dart';
import 'features/notifications/presentation/bloc/app_notifications_bloc.dart';
import 'features/notifications/presentation/widgets/global_notification_overlay.dart';

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
    final authBloc          = sl<AuthBloc>();
    final homeBloc          = sl<HomeBloc>();
    final recyclingBloc     = sl<RecyclingBloc>();
    final notificationsBloc = sl<AppNotificationsBloc>();
    final router            = AppRouter.router(authBloc);

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<HomeBloc>.value(value: homeBloc),
        BlocProvider<RecyclingBloc>.value(value: recyclingBloc),
        BlocProvider<AppNotificationsBloc>.value(value: notificationsBloc),
      ],
      child: MaterialApp.router(
        title: 'RecySmart',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: router,
        builder: (context, child) {
          return BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              // Connect the persistent global socket as soon as we're authenticated
              if (state is AuthAuthenticated) {
                context
                    .read<AppNotificationsBloc>()
                    .add(AppNotificationsConnectEvent());
              }

              // Handle session expiry / logout — disconnect global socket too
              if (state is AuthSessionExpired || state is AuthUnauthenticated) {
                context
                    .read<AppNotificationsBloc>()
                    .add(AppNotificationsDisconnectEvent());
                router.go(AppRoutes.login);

                if (state is AuthSessionExpired) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final ctx = AppRouter.navigatorKey.currentContext;
                    if (ctx != null && ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Tu sesión expiró. Por favor inicia sesión nuevamente.',
                          ),
                          backgroundColor: AppColors.warning,
                          duration: Duration(seconds: 4),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  });
                }
              }
            },
            // Wrap the whole navigable app with the global notification overlay
            child: GlobalNotificationOverlay(
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}