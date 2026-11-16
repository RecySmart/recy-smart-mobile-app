import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_router.dart';
import '../bloc/recycling_bloc.dart';

class ManualCodeSheet extends StatefulWidget {
  const ManualCodeSheet({super.key});

  @override
  State<ManualCodeSheet> createState() => _ManualCodeSheetState();
}

class _ManualCodeSheetState extends State<ManualCodeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    if (_submitting || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });
    context.read<RecyclingBloc>().add(RecyclingManualCodeSubmitted(_code.text));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RecyclingBloc, RecyclingState>(
      listener: (context, state) {
        if (!_submitting) return;
        if (state is RecyclingSessionActive) {
          _submitting = false;
          Navigator.of(context).pop(true);
        } else if (state is RecyclingManualStartFailed || state is RecyclingIdle) {
          setState(() {
            _submitting = false;
            _error = state is RecyclingManualStartFailed ? state.message : null;
          });
        }
      },
      builder: (context, state) {
        return PopScope(
          canPop: !_submitting,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Ingresar código del punto',
                      style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    const Text('Escribe el código del punto de reciclaje.'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _code,
                      autofocus: true,
                      enabled: !_submitting,
                      autocorrect: false,
                      enableSuggestions: false,
                      textCapitalization: TextCapitalization.none,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        hintText: 'recysmart-6ce50024',
                        prefixIcon: Icon(Icons.qr_code_rounded),
                      ),
                      validator: (input) {
                        final code = input?.trim() ?? '';
                        if (code.isEmpty) return 'Ingresa el código.';
                        if (code.length > 128) return 'El código es demasiado largo.';
                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Semantics(
                        liveRegion: true,
                        child: Text(_error!,
                          style: const TextStyle(color: AppColors.error)),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: Text(_submitting
                          ? 'Conectando con el punto…'
                          : 'Conectar al punto'),
                    ),
                    TextButton(
                      onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _scanned = false;
  bool _manualEntryOpen = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned || _manualEntryOpen) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    _scanned = true;
    final binId = barcode!.rawValue!;
    context.read<RecyclingBloc>().add(RecyclingQrScannedEvent(binId));
  }

  Future<void> _showManualEntry() async {
    if (_scanned || _manualEntryOpen) return;
    _manualEntryOpen = true;
    final bloc = context.read<RecyclingBloc>();
    final started = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const ManualCodeSheet(),
      ),
    );
    if (!mounted) return;
    _manualEntryOpen = false;
    final state = bloc.state;
    if (started == true && state is RecyclingSessionActive) {
      _openSession(state);
    }
  }

  void _openSession(RecyclingSessionActive state) {
    context.pushReplacement(
      AppRoutes.activeSession,
      extra: {
        'binId': state.session.binId,
        'locationName': state.session.locationName,
        'sessionId': state.session.sessionId,
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return BlocListener<RecyclingBloc, RecyclingState>(
      listener: (context, state) {
        if (state is RecyclingSessionActive && !_manualEntryOpen) {
          _openSession(state);
        }
        if (state is RecyclingError) {
          _scanned = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Camera
            MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
              errorBuilder: (context, error, child) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.camera_alt_outlined, color: Colors.white70, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'No se pudo iniciar la cámara o no hay permisos.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showManualEntry,
                          icon: const Icon(Icons.keyboard),
                          label: const Text('Ingresar código manual'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Top bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Conectar punto de reciclaje',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),

            // Scanner overlay
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Apunta la cámara al código QR del punto de reciclaje',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // QR frame
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        // Scanning line animation
                        _ScanLine(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      BlocBuilder<RecyclingBloc, RecyclingState>(
                        builder: (context, state) {
                          if (state is RecyclingConnecting) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Conectando con el punto...',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: AppColors.primary),
                                  ),
                                ],
                              ),
                            );
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Buscando el código...',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: AppColors.primary),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.keyboard_rounded),
                          label: const Text('Ingresar código manualmente'),
                          onPressed: _showManualEntry,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanLine extends StatefulWidget {
  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    final disableAnimations = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (!disableAnimations) _controller.repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Positioned(
        top: _animation.value * 220,
        left: 0,
        right: 0,
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0),
                AppColors.primary,
                AppColors.primary.withOpacity(0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
