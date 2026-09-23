import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/injection_container.dart';
import 'core/utils/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/home/presentation/bloc/home_bloc.dart';
import 'features/recycling/presentation/bloc/recycling_bloc.dart';
import 'features/notifications/presentation/bloc/app_notifications_bloc.dart';
import 'features/notifications/presentation/widgets/global_notification_overlay.dart';

import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

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
    debugPrint('Dependencies initialized successfully');
    
    // Log the current URLs to the console for debugging
    debugPrint('====================================');
    debugPrint('CURRENT API_URL: ${AppConstants.baseUrl}');
    debugPrint('CURRENT SOCKET_URL: ${AppConstants.socketUrl}');
    debugPrint('====================================');
    
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
                context.read<RecyclingBloc>().add(
                  RecyclingRestoreSessionEvent(state.user.id),
                );
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
            child: BlocListener<RecyclingBloc, RecyclingState>(
              listener: (context, state) {
                if (state is RecyclingSessionActive && state.recovered) {
                  router.go(AppRoutes.activeSession, extra: {
                    'binId': state.session.binId,
                    'locationName': state.session.locationName,
                    'sessionId': state.session.sessionId,
                  });
                } else if (state is RecyclingSessionCompleted) {
                  if (router.routeInformationProvider.value.uri.path !=
                      AppRoutes.activeSession) {
                    router.go(AppRoutes.sessionSummary, extra: {
                      'bottlesDropped': state.session.bottlesDropped,
                      'pointsEarned': state.session.pointsEarned,
                      'sessionId': state.session.sessionId,
                      'autoClosed': state.autoClosed,
                    });
                  }
                } else if (state is RecyclingRecoveryPending) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                      content: Text(state.message),
                      duration: const Duration(seconds: 15),
                      action: SnackBarAction(
                        label: 'Reintentar',
                        onPressed: () => context.read<RecyclingBloc>().add(
                          RecyclingRestoreSessionEvent(state.userId),
                        ),
                      ),
                    ));
                }
              },
              child: GlobalNotificationOverlay(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          );
        },
      ),
    );
  }
}
