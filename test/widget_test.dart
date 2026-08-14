import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:socia_saver/widgets/socmed_icon.dart';

void main() {
  testWidgets('SocmedIcon renders correct platform icon', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SocmedIcon(source: 'Instagram'),
        ),
      ),
    );

    expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
  });
}
