import 'package:flutter_test/flutter_test.dart';

import 'package:gcmrlogistic/main.dart';

void main() {
  testWidgets('Login screen tampil', (tester) async {
    await tester.pumpWidget(const LogiTrackApp());
    expect(find.text('LogiTrack'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });
}
