import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:socia_saver/models/category.dart';
import 'package:socia_saver/models/shared_content.dart';
import 'package:socia_saver/providers/category_provider.dart';
import 'package:socia_saver/providers/content_selection_provider.dart';
import 'package:socia_saver/widgets/content_card.dart';
import 'package:socia_saver/widgets/socmed_icon.dart';

class MockCategoryNotifier extends CategoryNotifier {
  MockCategoryNotifier(super.ref, List<Category> categories) {
    state = AsyncValue.data(categories);
  }

  @override
  Future<void> loadCategories() async {
    // No-op for test to avoid database calls
  }
}

void main() {
  group('SocmedIcon Platform Icons Tests', () {
    testWidgets('Renders Instagram icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SocmedIcon(source: 'Instagram'))),
      );
      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
    });

    testWidgets('Renders Facebook icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SocmedIcon(source: 'Facebook'))),
      );
      expect(find.byIcon(Icons.facebook_rounded), findsOneWidget);
    });

    testWidgets('Renders Threads icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SocmedIcon(source: 'Threads'))),
      );
      expect(find.byIcon(Icons.alternate_email_rounded), findsOneWidget);
    });

    testWidgets('Renders TikTok icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SocmedIcon(source: 'TikTok'))),
      );
      expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
    });

    testWidgets('Renders YouTube icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SocmedIcon(source: 'YouTube'))),
      );
      expect(find.byIcon(Icons.play_circle_fill_rounded), findsOneWidget);
    });

    testWidgets('Renders X / Twitter icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SocmedIcon(source: 'X'))),
      );
      expect(find.byIcon(Icons.tag_rounded), findsOneWidget);
    });

    testWidgets('Renders fallback link icon for unknown source', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SocmedIcon(source: 'Unknown'))),
      );
      expect(find.byIcon(Icons.link_rounded), findsOneWidget);
    });
  });

  group('ContentSelectionNotifier Unit Tests', () {
    late ContentSelectionNotifier notifier;

    setUp(() {
      notifier = ContentSelectionNotifier();
    });

    test('Initial state is empty', () {
      expect(notifier.state, isEmpty);
    });

    test('toggle adds and removes content ID', () {
      notifier.toggle(10);
      expect(notifier.state, contains(10));
      expect(notifier.state.length, equals(1));

      notifier.toggle(20);
      expect(notifier.state, containsAll([10, 20]));
      expect(notifier.state.length, equals(2));

      notifier.toggle(10);
      expect(notifier.state, isNot(contains(10)));
      expect(notifier.state, contains(20));
      expect(notifier.state.length, equals(1));
    });

    test('selectAll selects all visible IDs when partially selected or empty', () {
      notifier.toggle(1);
      notifier.selectAll([1, 2, 3]);
      expect(notifier.state, containsAll([1, 2, 3]));
      expect(notifier.state.length, equals(3));
    });

    test('selectAll deselects all when all visible IDs are already selected', () {
      notifier.selectAll([1, 2, 3]);
      expect(notifier.state.length, equals(3));

      // Tapping selectAll again when all are selected clears selection
      notifier.selectAll([1, 2, 3]);
      expect(notifier.state, isEmpty);
    });

    test('clear resets selection to empty', () {
      notifier.selectAll([1, 2, 3]);
      notifier.clear();
      expect(notifier.state, isEmpty);
    });
  });

  group('ContentCard Widget Tests', () {
    final testItem = SharedContent.create(
      userId: 'test_user',
      rawUrl: 'https://instagram.com/p/test123',
      title: 'Amazing Landscape Photo',
      socmedSource: 'Instagram',
      categoryId: 1,
    )..id = 42;

    final testCategory = Category.create(
      userId: 'test_user',
      name: 'Photography',
      colorHex: '3B82F6',
    )..id = 1;

    testWidgets('Renders card details in normal mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoryNotifierProvider.overrideWith(
              (ref) => MockCategoryNotifier(ref, [testCategory]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ContentCard(item: testItem),
            ),
          ),
        ),
      );

      // Verify Title and Source
      expect(find.text('Amazing Landscape Photo'), findsOneWidget);
      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('Photography'), findsOneWidget);

      // Verify Buttons
      expect(find.text('Copy Link'), findsOneWidget);
      expect(find.text('Open App'), findsOneWidget);

      // Verify PopupMenu is visible in normal mode
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);

      // Verify Checkbox is NOT rendered in normal mode
      expect(find.byIcon(Icons.check_rounded), findsNothing);
    });

    testWidgets('Renders checkbox on top-left when in selection mode', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          categoryNotifierProvider.overrideWith(
            (ref) => MockCategoryNotifier(ref, [testCategory]),
          ),
        ],
      );

      // Set selection mode active with a different item
      container.read(contentSelectionProvider.notifier).toggle(999);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: ContentCard(item: testItem),
            ),
          ),
        ),
      );

      // In selection mode, popup menu is hidden
      expect(find.byIcon(Icons.more_vert_rounded), findsNothing);

      // Card 42 is not selected yet, so no check icon
      expect(find.byIcon(Icons.check_rounded), findsNothing);

      // Select card 42
      container.read(contentSelectionProvider.notifier).toggle(42);
      await tester.pumpAndSettle();

      // Check icon now appears on the card
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('Tapping card in selection mode toggles selection state', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          categoryNotifierProvider.overrideWith(
            (ref) => MockCategoryNotifier(ref, [testCategory]),
          ),
        ],
      );

      // Activate selection mode
      container.read(contentSelectionProvider.notifier).toggle(100);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: ContentCard(item: testItem),
            ),
          ),
        ),
      );

      expect(container.read(contentSelectionProvider), isNot(contains(42)));

      // Tap card 42
      await tester.tap(find.byType(ContentCard));
      await tester.pumpAndSettle();

      // Card 42 is now selected
      expect(container.read(contentSelectionProvider), contains(42));

      // Tap card 42 again
      await tester.tap(find.byType(ContentCard));
      await tester.pumpAndSettle();

      // Card 42 is deselected
      expect(container.read(contentSelectionProvider), isNot(contains(42)));
    });
  });
}
