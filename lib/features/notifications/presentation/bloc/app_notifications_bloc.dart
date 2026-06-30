import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/global_notification_service.dart';
import '../../../../core/utils/storage_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../home/presentation/bloc/home_bloc.dart';

// ── Models ───────────────────────────────────────────────────────────────────

class AchievementNotification extends Equatable {
  final String id;
  final String name;
  final String description;
  final String? iconEmoji;

  const AchievementNotification({
    required this.id,
    required this.name,
    required this.description,
    this.iconEmoji,
  });

  factory AchievementNotification.fromJson(Map<String, dynamic> json) {
    return AchievementNotification(
      id: json['id'] as String? ?? json['achievementId'] as String? ?? '',
      name: json['name'] as String? ?? 'Logro desbloqueado',
      description: json['description'] as String? ??
          '¡Has desbloqueado un nuevo logro!',
      iconEmoji: json['icon'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, description];
}

class CouponValidatedNotification extends Equatable {
  final String couponCode;
  final String rewardTitle;
  final String companyName;

  const CouponValidatedNotification({
    required this.couponCode,
    required this.rewardTitle,
    required this.companyName,
  });

  factory CouponValidatedNotification.fromJson(Map<String, dynamic> json) {
    return CouponValidatedNotification(
      couponCode: json['couponCode'] as String? ??
          json['code'] as String? ?? '',
      rewardTitle: json['rewardTitle'] as String? ??
          json['rewardName'] as String? ?? 'Cupón',
      companyName: json['companyName'] as String? ??
          json['partnerName'] as String? ?? 'Tienda asociada',
    );
  }

  @override
  List<Object> get props => [couponCode, rewardTitle, companyName];
}

// ── Events ───────────────────────────────────────────────────────────────────

abstract class AppNotificationsEvent extends Equatable {
  const AppNotificationsEvent();
  @override
  List<Object?> get props => [];
}

/// Called once after login/app start to open the persistent socket
class AppNotificationsConnectEvent extends AppNotificationsEvent {}

class AppNotificationsAchievementReceivedEvent extends AppNotificationsEvent {
  final Map<String, dynamic> data;
  const AppNotificationsAchievementReceivedEvent(this.data);
  @override
  List<Object> get props => [data];
}

class AppNotificationsCouponValidatedReceivedEvent
    extends AppNotificationsEvent {
  final Map<String, dynamic> data;
  const AppNotificationsCouponValidatedReceivedEvent(this.data);
  @override
  List<Object> get props => [data];
}

/// Dismiss the currently shown overlay (advances the queue)
class AppNotificationsDismissEvent extends AppNotificationsEvent {}

class AppNotificationsDisconnectEvent extends AppNotificationsEvent {}

// ── States ───────────────────────────────────────────────────────────────────

class AppNotificationsState extends Equatable {
  // Pending queue of overlays to show, one at a time
  final List<Object> queue; // AchievementNotification | CouponValidatedNotification

  const AppNotificationsState({this.queue = const []});

  Object? get current => queue.isNotEmpty ? queue.first : null;

  AppNotificationsState copyWith({List<Object>? queue}) =>
      AppNotificationsState(queue: queue ?? this.queue);

  @override
  List<Object> get props => [queue];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────

class AppNotificationsBloc
    extends Bloc<AppNotificationsEvent, AppNotificationsState> {
  final GlobalNotificationService _service;
  final StorageService _storage;
  final HomeBloc _homeBloc;

  AppNotificationsBloc({
    required GlobalNotificationService service,
    required StorageService storage,
    required HomeBloc homeBloc,
  })  : _service = service,
        _storage = storage,
        _homeBloc = homeBloc,
        super(const AppNotificationsState()) {
    on<AppNotificationsConnectEvent>(_onConnect);
    on<AppNotificationsAchievementReceivedEvent>(_onAchievementReceived);
    on<AppNotificationsCouponValidatedReceivedEvent>(_onCouponReceived);
    on<AppNotificationsDismissEvent>(_onDismiss);
    on<AppNotificationsDisconnectEvent>(_onDisconnect);
  }

  Future<void> _onConnect(
      AppNotificationsConnectEvent event,
      Emitter<AppNotificationsState> emit) async {
    final userId = await _storage.read(key: AppConstants.userIdKey);
    if (userId == null || userId.isEmpty) return;

    _service.connect(
      userId: userId,
      onAchievementUnlocked: (data) {
        if (!isClosed) add(AppNotificationsAchievementReceivedEvent(data));
      },
      onCouponValidated: (data) {
        if (!isClosed) add(AppNotificationsCouponValidatedReceivedEvent(data));
      },
      onPointsUpdate: (_) {
        // Keep home balance fresh whenever points change anywhere in the app
        _homeBloc.add(HomeRefreshEvent());
      },
    );
  }

  void _onAchievementReceived(
      AppNotificationsAchievementReceivedEvent event,
      Emitter<AppNotificationsState> emit) {
    final achievement = AchievementNotification.fromJson(event.data);
    emit(state.copyWith(queue: [...state.queue, achievement]));
  }

  void _onCouponReceived(
      AppNotificationsCouponValidatedReceivedEvent event,
      Emitter<AppNotificationsState> emit) {
    final coupon = CouponValidatedNotification.fromJson(event.data);
    emit(state.copyWith(queue: [...state.queue, coupon]));
    // A redeemed coupon means the partner just scanned it — refresh coupons/wallet
    _homeBloc.add(HomeRefreshEvent());
  }

  void _onDismiss(
      AppNotificationsDismissEvent event,
      Emitter<AppNotificationsState> emit) {
    if (state.queue.isEmpty) return;
    final newQueue = List<Object>.from(state.queue)..removeAt(0);
    emit(state.copyWith(queue: newQueue));
  }

  void _onDisconnect(
      AppNotificationsDisconnectEvent event,
      Emitter<AppNotificationsState> emit) {
    _service.disconnect();
  }

  @override
  Future<void> close() {
    _service.disconnect();
    return super.close();
  }
}