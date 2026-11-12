import 'package:flutter_test/flutter_test.dart';
import 'package:gcmrlogistic/core/auth/app_services.dart';
import 'package:gcmrlogistic/core/storage/token_storage.dart';
import 'package:gcmrlogistic/main.dart';

void main() {
  testWidgets('Tanpa token tersimpan, layar login tampil', (tester) async {
    AppServices.use(AppServices.create(storage: MemoryTokenStorage()));

    await tester.pumpWidget(const LogiTrackApp());
    await tester.pumpAndSettle();

    expect(find.text('LogiTrack'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });
}
