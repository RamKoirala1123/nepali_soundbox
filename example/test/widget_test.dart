import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';

void main() {
  testWidgets('Nepali Soundbox Demo App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NepaliSoundboxDemoApp());
    expect(find.text('नेपाली Soundbox (TTS)'), findsOneWidget);
    expect(find.text('बोल्नुहोस् (Speak)'), findsOneWidget);
  });
}
