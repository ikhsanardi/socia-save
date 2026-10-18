import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:socia_saver/models/category.dart';
import 'package:socia_saver/models/shared_content.dart';
import 'package:socia_saver/providers/category_provider.dart';
import 'package:socia_saver/providers/content_selection_provider.dart';
import 'package:socia_saver/screens/categories_screen.dart';
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
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.bySemanticsLabel('Instagram logo'), findsOneWidget);
    });

    testWidgets('Renders Facebook icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SocmedIcon(source: 'Facebook'))),
      );
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.bySemanticsLabel('Facebook logo'), findsOneWidget);
    });

    testWidgets('Renders Threads icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SocmedIcon(source: 'Threads'))),
      );
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.bySemanticsLabel('Threads logo'), findsOneWidget);
    });

    testWidgets('Renders TikTok icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SocmedIcon(source: 'TikTok'))),
      );
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.bySemanticsLabel('TikTok logo'), findsOneWidget);
    });

    testWidgets('Renders YouTube icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SocmedIcon(source: 'YouTube'))),
      );
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.bySemanticsLabel('YouTube logo'), findsOneWidget);
    });

    testWidgets('Renders X / Twitter icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SocmedIcon(source: 'X'))),
      );
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.bySemanticsLabel('X logo'), findsOneWidget);
    });

    testWidgets('Renders LinkedIn icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SocmedIcon(source: 'LinkedIn'))),
      );
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.bySemanticsLabel('LinkedIn logo'), findsOneWidget);
    });

    testWidgets('Renders fallback link icon for unknown source', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SocmedIcon(source: 'Unknown'))),
      );
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.bySemanticsLabel('Unknown logo'), findsOneWidget);
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

  group('CategoriesScreen Color Picker Tests', () {
    testWidgets('Retains default colors and opens Custom Color Picker dialog',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          categoryNotifierProvider.overrideWith(
            (ref) => MockCategoryNotifier(ref, []),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: CategoriesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 'New Category' FAB
      await tester.tap(find.text('New Category'));
      await tester.pumpAndSettle();

      // Add Master Category dialog should be open
      expect(find.text('Add Master Category'), findsOneWidget);
      expect(find.text('Select Category Color'), findsOneWidget);

      // Color picker icon button should be visible alongside default colors
      final colorizeButton = find.byTooltip('Custom Color Picker');
      expect(colorizeButton, findsOneWidget);

      // Tap the color picker button
      await tester.tap(colorizeButton);
      await tester.pumpAndSettle();

      // Custom Color Picker dialog should appear
      expect(find.text('Custom Color Picker'), findsOneWidget);
      expect(find.text('Hue'), findsOneWidget);
      expect(find.text('Saturation'), findsOneWidget);
      expect(find.text('Brightness'), findsOneWidget);
      expect(find.text('Palette Presets'), findsOneWidget);
      expect(find.text('Select Color'), findsOneWidget);
      expect(find.text('Cancel'), findsNWidgets(2));

      // Select a preset color from palette presets in picker
      await tester.tap(find.text('Select Color'));
      await tester.pumpAndSettle();

      // Custom Color Picker closes, returning to Add Master Category dialog
      expect(find.text('Custom Color Picker'), findsNothing);
      expect(find.text('Add Master Category'), findsOneWidget);
    });

    testWidgets(
        'Custom Color Picker dialog renders without overflow on narrow screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          categoryNotifierProvider.overrideWith(
            (ref) => MockCategoryNotifier(ref, []),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: CategoriesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('New Category'));
      await tester.pumpAndSettle();

      // Check default category swatches are rendered with compact 25x25 size
      final animatedContainers = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      // There should be 18 default colors
      expect(animatedContainers.length, equals(18));
      for (final container in animatedContainers) {
        final boxConstraints = container.constraints;
        expect(boxConstraints?.maxWidth, equals(25));
        expect(boxConstraints?.maxHeight, equals(25));
      }

      // Tap Custom Color Picker button
      await tester.tap(find.byTooltip('Custom Color Picker'));
      await tester.pumpAndSettle();

      // Ensure no overflow errors occurred
      expect(tester.takeException(), isNull);
      expect(find.text('Custom Color Picker'), findsOneWidget);
    });
  });
}
