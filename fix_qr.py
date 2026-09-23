import sys
import io

def main():
    filepath = 'lib/features/recycling/presentation/pages/qr_scanner_page.dart'
    with io.open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    start = content.find('  void _showManualEntry() {')
    end = content.find('  }\n\nclass _ScanLine')
    if end == -1:
        end = content.find('  }\n\n  class _ScanLine')
        if end == -1:
            end = content.find('\nclass _ScanLine')

    if start != -1 and end != -1:
        replacement = """  void _showManualEntry() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        final formKey = GlobalKey<FormState>();
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ingresar Código del Tacho', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Ingresa el código impreso en el tacho inteligente.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'ej. BIN-001',
                      prefixIcon: Icon(Icons.qr_code_rounded),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'El código es requerido';
                      return null;
                    },
                    onFieldSubmitted: (_) {
                      if (!formKey.currentState!.validate()) return;
                      Navigator.pop(context);
                      _scanned = true;
                      context.read<RecyclingBloc>().add(
                        RecyclingQrScannedEvent(controller.text.trim()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        Navigator.pop(context);
                        _scanned = true;
                        context.read<RecyclingBloc>().add(
                          RecyclingQrScannedEvent(controller.text.trim()),
                        );
                      },
                      child: const Text('Conectar al Tacho'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );"""
        with io.open(filepath, 'w', encoding='utf-8') as f:
            f.write(content[:start] + replacement + content[end:])
        print("Success")
    else:
        print("Could not find bounds")
        print("Start:", start, "End:", end)

if __name__ == '__main__':
    main()
