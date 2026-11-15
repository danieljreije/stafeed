// Shopping Sessions in the whole app (ticket #11), on the Fixtures: the
// Search tab lists them, a session takes over the Feed tab behind its
// banner, ✕ goes back to For You, and an empty session suggests fixes.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stafeed/app/features/feed/data/fixture_data_gateway.dart';
import 'package:stafeed/app/features/feed/models/feed_item.dart';
import 'package:stafeed/app/features/shopping_sessions/session_editor_screen.dart';

import '../../app/app_shell_test.dart' show launchApp, openTab, tapText;
import '../../support/shopper.dart';

Future<String> firstForYouTitle() async {
  final page = await FixtureDataGateway(destinationCountry: 'US').getFeedPage();
  return (page.items.first as AffiliateAd).product.title;
}

Future<void> startSession(
  WidgetTester tester, {
  required String goal,
  String? budget,
}) async {
  await openTab(tester, 'Search');
  await tapText(tester, 'New session');
  await tester.enterText(
    find.widgetWithText(TextField, 'What are you shopping for?'),
    goal,
  );
  if (budget != null) {
    await tester.enterText(
      find.widgetWithText(TextField, 'Budget (optional)'),
      budget,
    );
  }
  await tester.pump(sessionPreviewDebounce);
  await tester.pumpAndSettle();
  await tapText(tester, 'Start session');
}

void main() {
  setUp(() async {
    useEmptyDeviceStorage();
    await storeOnboardedShopper();
  });

  testWidgets('a new session takes over the Feed behind its banner; ✕ goes '
      'back to For You', (tester) async {
    final forYouFirst = await firstForYouTitle();
    await launchApp(tester);
    expect(find.text(forYouFirst), findsOneWidget);

    await startSession(tester, goal: 'watch');

    // Back on the Feed tab, in the session.
    expect(find.text('Session: watch'), findsOneWidget);
    expect(find.text('Search products...'), findsNothing);
    // The session's own feed: watches, not For You's first sneaker.
    expect(find.text(forYouFirst), findsNothing);
    expect(find.text('Sample data · not real products'), findsOneWidget);

    await tester.tap(find.byTooltip('Back to For You'));
    await tester.pumpAndSettle();
    expect(find.text('Session: watch'), findsNothing);
    expect(find.text(forYouFirst), findsOneWidget);
  });

  testWidgets('sessions are listed on the Search tab and can be resumed, '
      'renamed and deleted, also after a restart', (tester) async {
    await launchApp(tester);
    await startSession(tester, goal: 'watch');
    await tester.tap(find.byTooltip('Back to For You'));
    await tester.pumpAndSettle();

    // A restart keeps it.
    await launchApp(tester);
    await openTab(tester, 'Search');
    expect(find.text('watch'), findsOneWidget);

    await tester.tap(find.byTooltip('Session options'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Rename');
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Gift');
    await tapText(tester, 'Rename');
    expect(find.text('Gift'), findsOneWidget);

    // Resuming it shows it in the Feed.
    await tapText(tester, 'Gift');
    expect(find.text('Session: Gift'), findsOneWidget);

    await openTab(tester, 'Search');
    await tester.tap(find.byTooltip('Session options'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Delete');
    expect(find.text('Gift'), findsNothing);

    // Deleting the active session put For You back.
    await openTab(tester, 'Feed');
    expect(find.textContaining('Session:'), findsNothing);
  });

  testWidgets('a session with no results suggests raising the budget', (
    tester,
  ) async {
    await launchApp(tester);
    await startSession(tester, goal: 'watch', budget: '1');

    expect(find.text('Nothing matches this session'), findsOneWidget);
    await tapText(tester, 'Raise budget to \$2.00');

    // Still nothing for $2: the next suggestion raises it again.
    expect(find.text('Raise budget to \$3.00'), findsOneWidget);
    expect(find.text('Drop "watch"'), findsOneWidget);
  });

  testWidgets('the New session form looks up matches only once typing '
      'pauses', (tester) async {
    await launchApp(tester);
    await openTab(tester, 'Search');
    await tapText(tester, 'New session');
    await tester.pump(sessionPreviewDebounce);
    await tester.pumpAndSettle();
    final before = tester.widget<Text>(
      find.byKey(const Key('session-preview')),
    );

    final goal = find.widgetWithText(TextField, 'What are you shopping for?');
    await tester.enterText(goal, 'zzzz');
    await tester.pump(const Duration(milliseconds: 100));
    // Mid-typing: the count hasn't changed yet.
    expect(
      tester.widget<Text>(find.byKey(const Key('session-preview'))).data,
      before.data,
    );

    await tester.pump(sessionPreviewDebounce);
    await tester.pumpAndSettle();
    expect(find.text('Nothing matches yet'), findsOneWidget);
  });
}
