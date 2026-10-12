import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stafeed/main.dart';

void main() {
  testWidgets('Shows the discovery home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: StafeedApp()));

    expect(find.text('Stafeed'), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Start Exploring'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
