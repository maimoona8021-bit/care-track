import 'package:flutter_test/flutter_test.dart';
import 'package:sehatfile/app.dart';

void main() {
  testWidgets('Care Track app starts successfully',
          (WidgetTester tester) async {

        await tester.pumpWidget(
          const CareTrackApp(),
        );

        expect(
          find.text('Care Track'),
          findsOneWidget,
        );
      });
}