import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/entities/smart_bin.dart';
import '../../domain/usecases/get_all_bins_usecase.dart';

// ── Events ───────────────────────────────────────────────────────────────────
abstract class MapEvent extends Equatable {
  const MapEvent();
  @override
  List<Object?> get props => [];
}

class MapLoadBinsEvent extends MapEvent {}

class MapFilterChangedEvent extends MapEvent {
  final String filter; // 'Todos' | 'Disponibles' | 'Aceptan Latas'
  const MapFilterChangedEvent(this.filter);
  @override
  List<Object> get props => [filter];
}

class MapBinSelectedEvent extends MapEvent {
  final SmartBin bin;
  const MapBinSelectedEvent(this.bin);
  @override
  List<Object> get props => [bin];
}

class MapBinDismissedEvent extends MapEvent {}

class MapSearchQueryChangedEvent extends MapEvent {
  final String query;
  const MapSearchQueryChangedEvent(this.query);
  @override
  List<Object> get props => [query];
}

class MapUserLocationUpdatedEvent extends MapEvent {
  final LatLng location;
  const MapUserLocationUpdatedEvent(this.location);
  @override
  List<Object> get props => [location];
}

// ── States ───────────────────────────────────────────────────────────────────
abstract class MapState extends Equatable {
  const MapState();
  @override
  List<Object?> get props => [];
}

class MapInitial extends MapState {}
class MapLoading extends MapState {}

class MapLoaded extends MapState {
  final List<SmartBin> allBins;
  final List<SmartBin> filteredBins;
  final String selectedFilter;
  final String searchQuery;
  final SmartBin? selectedBin;
  final LatLng? userLocation;

  const MapLoaded({
    required this.allBins,
    required this.filteredBins,
    this.selectedFilter = 'Todos',
    this.searchQuery = '',
    this.selectedBin,
    this.userLocation,
  });

  MapLoaded copyWith({
    List<SmartBin>? allBins,
    List<SmartBin>? filteredBins,
    String? selectedFilter,
    String? searchQuery,
    SmartBin? selectedBin,
    bool clearSelected = false,
    LatLng? userLocation,
  }) =>
      MapLoaded(
        allBins: allBins ?? this.allBins,
        filteredBins: filteredBins ?? this.filteredBins,
        selectedFilter: selectedFilter ?? this.selectedFilter,
        searchQuery: searchQuery ?? this.searchQuery,
        selectedBin: clearSelected ? null : (selectedBin ?? this.selectedBin),
        userLocation: userLocation ?? this.userLocation,
      );

  @override
  List<Object?> get props =>
      [allBins, filteredBins, selectedFilter, searchQuery, selectedBin, userLocation];
}

class MapError extends MapState {
  final String message;
  const MapError(this.message);
  @override
  List<Object> get props => [message];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────
class MapBloc extends Bloc<MapEvent, MapState> {
  final GetAllBinsUseCase _getAllBins;

  MapBloc(this._getAllBins) : super(MapInitial()) {
    on<MapLoadBinsEvent>(_onLoad);
    on<MapFilterChangedEvent>(_onFilter);
    on<MapSearchQueryChangedEvent>(_onSearch);
    on<MapBinSelectedEvent>(_onBinSelected);
    on<MapBinDismissedEvent>(_onBinDismissed);
    on<MapUserLocationUpdatedEvent>(_onLocationUpdated);
  }

  Future<void> _onLoad(MapLoadBinsEvent event, Emitter<MapState> emit) async {
    emit(MapLoading());
    final result = await _getAllBins();
    result.fold(
          (f) => emit(MapError(f.message)),
          (bins) => emit(MapLoaded(allBins: bins, filteredBins: bins)),
    );
  }

  List<SmartBin> _applyFilters(List<SmartBin> bins, String filter, String query) {
    var result = bins;
    if (filter == 'Disponibles') {
      result = result.where((b) => b.isAvailable).toList();
    } else if (filter == 'Aceptan Latas') {
      result = result.where((b) => b.status != BinStatus.offline).toList();
    }
    
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      result = result.where((b) => b.locationName.toLowerCase().contains(q) ).toList();
    }
    return result;
  }

  void _onFilter(MapFilterChangedEvent event, Emitter<MapState> emit) {
    if (state is! MapLoaded) return;
    final current = state as MapLoaded;
    final filtered = _applyFilters(current.allBins, event.filter, current.searchQuery);
    emit(current.copyWith(
      filteredBins: filtered,
      selectedFilter: event.filter,
      clearSelected: true,
    ));
  }

  void _onSearch(MapSearchQueryChangedEvent event, Emitter<MapState> emit) {
    if (state is! MapLoaded) return;
    final current = state as MapLoaded;
    final filtered = _applyFilters(current.allBins, current.selectedFilter, event.query);
    emit(current.copyWith(
      filteredBins: filtered,
      searchQuery: event.query,
      clearSelected: true,
    ));
  }

  void _onBinSelected(MapBinSelectedEvent event, Emitter<MapState> emit) {
    if (state is! MapLoaded) return;
    emit((state as MapLoaded).copyWith(selectedBin: event.bin));
  }

  void _onBinDismissed(MapBinDismissedEvent event, Emitter<MapState> emit) {
    if (state is! MapLoaded) return;
    emit((state as MapLoaded).copyWith(clearSelected: true));
  }

  void _onLocationUpdated(
      MapUserLocationUpdatedEvent event, Emitter<MapState> emit) {
    if (state is! MapLoaded) return;
    emit((state as MapLoaded).copyWith(userLocation: event.location));
  }
}