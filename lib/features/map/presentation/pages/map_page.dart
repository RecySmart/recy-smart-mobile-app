import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/injection_container.dart';
import '../../domain/entities/smart_bin.dart';
import '../bloc/map_bloc.dart';

// Default center: Lima Metropolitana
const _limaCenter = LatLng(-12.0464, -77.0428);

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MapBloc>()..add(MapLoadBinsEvent()),
      child: const _MapView(),
    );
  }
}

class _MapView extends StatefulWidget {
  const _MapView();

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  bool _isListView = false;
  bool _locationDenied = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) setState(() => _locationDenied = true);
    } else {
      if (mounted) setState(() => _locationDenied = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapBloc, MapState>(
      builder: (context, state) {
        return Scaffold(
          body: Stack(
            children: [
              // ── Map or List ──────────────────────────────────────────────
              if (_isListView)
                _buildListView(context, state)
              else
                _buildMap(context, state),

              // ── Search bar & Filters ───────────────────────────────────────────────
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SearchBar(
                      controller: _searchController,
                      onChanged: (query) => _filterBySearch(context, query),
                    ),
                    const SizedBox(height: 10),
                    _FilterChips(
                      selected: state is MapLoaded ? state.selectedFilter : 'Todos',
                      onSelected: (f) => context.read<MapBloc>().add(MapFilterChangedEvent(f)),
                    ),
                    if (_locationDenied)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.location_off, color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Permiso de ubicación denegado. Mostrando vista predeterminada.',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Bottom sheet bin info ─────────────────────────────────────
              if (!_isListView && state is MapLoaded && state.selectedBin != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _BinInfoSheet(
                    bin: state.selectedBin!,
                    userLocation: state.userLocation,
                    onDismiss: () => context.read<MapBloc>().add(MapBinDismissedEvent()),
                  ),
                ),

              // ── Loading overlay ───────────────────────────────────────────
              if (state is MapLoading)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            onPressed: () => setState(() => _isListView = !_isListView),
            tooltip: _isListView ? 'Ver en Mapa' : 'Ver como Lista',
            child: Icon(_isListView ? Icons.map_rounded : Icons.format_list_bulleted_rounded),
          ),
        );
      },
    );
  }

  Widget _buildMap(BuildContext context, MapState state) {
    final bins =
    state is MapLoaded ? state.filteredBins : <SmartBin>[];
    final selectedBin =
    state is MapLoaded ? state.selectedBin : null;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _limaCenter,
        initialZoom: 13,
        onTap: (_, __) {
          if (selectedBin != null) {
            context.read<MapBloc>().add(MapBinDismissedEvent());
          }
        },
      ),
      children: [
        // OSM tiles
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.recysmart.app',
        ),
        // Bin markers
        MarkerLayer(
          markers: bins.map((bin) {
            final isSelected = selectedBin?.id == bin.id;
            return Marker(
              point: LatLng(bin.latitude, bin.longitude),
              width: isSelected ? 48 : 36,
              height: isSelected ? 48 : 36,
              child: GestureDetector(
                onTap: () {
                  context.read<MapBloc>().add(MapBinSelectedEvent(bin));
                  _mapController.move(
                    LatLng(bin.latitude, bin.longitude),
                    15,
                  );
                },
                child: _BinMarker(bin: bin, isSelected: isSelected),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildListView(BuildContext context, MapState state) {
    if (state is! MapLoaded) return const SizedBox.shrink();
    if (state.filteredBins.isEmpty) {
      return const Center(child: Text('No se encontraron contenedores.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 150, bottom: 80, left: 16, right: 16),
      itemCount: state.filteredBins.length,
      itemBuilder: (context, index) {
        final bin = state.filteredBins[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_rounded, color: AppColors.primary, size: 24),
            ),
            title: Text(bin.locationName, style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text('Capacidad: %'),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            onTap: () {
              setState(() => _isListView = false);
              context.read<MapBloc>().add(MapBinSelectedEvent(bin));
              _mapController.move(LatLng(bin.latitude, bin.longitude), 15);
            },
          ),
        );
      },
    );
  }

  void _filterBySearch(BuildContext context, String query) {
    if (state is! MapLoaded) return;
    context.read<MapBloc>().add(MapSearchQueryChangedEvent(query));
  }

  MapState get state => context.read<MapBloc>().state;
}

// ── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Buscar tachos cercanos...',
            hintStyle: Theme.of(context).textTheme.bodyMedium,
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.textMuted, size: 20),
            suffixIcon: const Icon(Icons.my_location_rounded,
                color: AppColors.primary, size: 20),
            border: InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }
}

// ── Filter Chips ─────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _FilterChips({required this.selected, required this.onSelected});

  static const _filters = ['Todos', 'Disponibles'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final filter = _filters[i];
          final isSelected = filter == selected;
          return FilterChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (_) => onSelected(filter),
            backgroundColor: Colors.white,
            selectedColor: AppColors.secondary,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: isSelected ? 0 : 2,
            shadowColor: Colors.black.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          );
        },
      ),
    );
  }
}

// ── Bin Marker ───────────────────────────────────────────────────────────────

class _BinMarker extends StatelessWidget {
  final SmartBin bin;
  final bool isSelected;

  const _BinMarker({required this.bin, required this.isSelected});

  Color get _color {
    if (bin.status == BinStatus.offline) return AppColors.textMuted;
    if (bin.isFull) return AppColors.error;
    if (bin.status == BinStatus.inUse) return AppColors.warning;
    return AppColors.secondary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? _color : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: _color,
          width: isSelected ? 0 : 3,
        ),
        boxShadow: [
          BoxShadow(
            color: _color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.delete_rounded,
        color: isSelected ? Colors.white : _color,
        size: isSelected ? 26 : 20,
      ),
    );
  }
}

// ── Bin Info Bottom Sheet ─────────────────────────────────────────────────────

class _BinInfoSheet extends StatelessWidget {
  final SmartBin bin;
  final LatLng? userLocation;
  final VoidCallback onDismiss;

  const _BinInfoSheet({
    required this.bin,
    required this.userLocation,
    required this.onDismiss,
  });

  String _distanceLabel() {
    if (userLocation == null) return '';
    const distance = Distance();
    final meters = distance(
      userLocation!,
      LatLng(bin.latitude, bin.longitude),
    ).toInt();
    if (meters < 1000) return 'A $meters metros de ti';
    return 'A ${(meters / 1000).toStringAsFixed(1)} km de ti';
  }

  Color get _capacityColor {
    final pct = bin.capacityPercentage;
    if (pct >= 80) return AppColors.error;
    if (pct >= 50) return AppColors.warning;
    return AppColors.primary;
  }

  Future<void> _openMaps(BuildContext context) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${bin.latitude},${bin.longitude}',
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('No can launch');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir una aplicación de mapas. Verifica si tienes alguna instalada.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final distance = _distanceLabel();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_rounded,
                      color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bin.locationName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (distance.isNotEmpty)
                        Text(
                          distance,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textMuted),
                  onPressed: onDismiss,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Capacity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Estado de Capacidad',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  bin.statusLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _capacityColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: bin.capacityPercentage / 100,
                backgroundColor: AppColors.surfaceGrey,
                color: _capacityColor,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Acepta Plástico PET',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.directions_rounded, size: 18),
                    label: const Text('Cómo llegar'),
                    onPressed: () => _openMaps(context),
                  ),
                ),
                const SizedBox(width: 12),
                if (bin.isAvailable)
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          minimumSize: Size.zero,
                        ),
                        icon: const Icon(Icons.qr_code_scanner_rounded,
                            size: 18),
                        label: const Text('Escanear'),
                        onPressed: () {
                          onDismiss();
                          context.push('/scan');
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}