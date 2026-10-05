import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the RecySmart brand asset is bundled and decodes at 1024 square', () async {
    final data = await rootBundle.load('assets/branding/recysmart-symbol.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    ));
    final frame = await codec.getNextFrame();
    expect(frame.image.width, 1024);
    expect(frame.image.height, 1024);
    frame.image.dispose();
    codec.dispose();
  });
}
