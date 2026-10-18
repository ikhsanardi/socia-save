import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:socia_saver/models/category.dart';
import 'package:socia_saver/models/shared_content.dart';
import 'package:socia_saver/providers/auth_provider.dart';
import 'package:socia_saver/providers/category_provider.dart';
import 'package:socia_saver/providers/shared_content_provider.dart';
import 'package:socia_saver/providers/sync_provider.dart';
import 'package:socia_saver/screens/home_screen.dart';

class MockCategoryNotifier extends CategoryNotifier {
  MockCategoryNotifier(super.ref, List<Category> categories) {
    state = AsyncValue.data(categories);
  }

  @override
  Future<void> loadCategories() async {}
}

class MockSharedContentNotifier extends SharedContentNotifier {
  MockSharedContentNotifier(super.ref, List<SharedContent> items) {
    state = AsyncValue.data(items);
  }

  @override
  Future<void> loadContent() async {}
}

class MockSyncNotifier extends SyncNotifier {
  bool syncCalled = false;
  MockSyncNotifier(super.ref) : super();

  @override
  Future<void> triggerSync({bool silent = false}) async {
    syncCalled = true;
  }
}

class MockUser extends Fake implements User {
  @override
  final String? displayName;
  @override
  final String? email;
  @override
  final String? photoURL;
  @override
  final bool isAnonymous;
  @override
  final List<UserInfo> providerData;
  @override
  final String uid;

  MockUser({
    this.displayName,
    this.email,
    this.photoURL,
    this.isAnonymous = false,
    this.providerData = const [],
    this.uid = 'test-uid',
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('receive_sharing_intent/messages'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getInitialMedia') {
          return '[]';
        }
        return null;
      },
    );
  });

  group('Sync Button & Onboarding Tests', () {
    testWidgets('Guest / unauthenticated user does not see badge count and sees "Sign in to Sync" dialog on tap',
        (WidgetTester tester) async {
      late MockSyncNotifier mockSyncNotifier;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            unsyncedCountProvider.overrideWith((ref) => Future.value(5)),
            categoryNotifierProvider.overrideWith(
              (ref) => MockCategoryNotifier(ref, []),
            ),
            sharedContentNotifierProvider.overrideWith(
              (ref) => MockSharedContentNotifier(ref, []),
            ),
            syncNotifierProvider.overrideWith((ref) {
              mockSyncNotifier = MockSyncNotifier(ref);
              return mockSyncNotifier;
            }),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Badge count should NOT be visible for unauthenticated guest
      expect(find.text('5'), findsNothing);

      // Tooltip should be 'Sign in to Sync'
      final syncButton = find.byTooltip('Sign in to Sync');
      expect(syncButton, findsOneWidget);

      // Tap sync button
      await tester.tap(syncButton);
      await tester.pumpAndSettle();

      // Sign in to Sync dialog should appear
      expect(find.text('Sign in to Sync'), findsOneWidget);
      expect(
        find.text(
          'Sign in with Google to back up and restore your saved bookmarks across all your devices.',
        ),
        findsOneWidget,
      );
      expect(find.text('Sign In with Google'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Cancel -> dialog closes
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Sign in to Sync'), findsNothing);
      expect(mockSyncNotifier.syncCalled, isFalse);
    });

    testWidgets('Authenticated user sees badge count and tapping sync calls triggerSync directly without dialog',
        (WidgetTester tester) async {
      late MockSyncNotifier mockSyncNotifier;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(MockUser(isAnonymous: false)),
            ),
            unsyncedCountProvider.overrideWith((ref) => Future.value(3)),
            categoryNotifierProvider.overrideWith(
              (ref) => MockCategoryNotifier(ref, []),
            ),
            sharedContentNotifierProvider.overrideWith(
              (ref) => MockSharedContentNotifier(ref, []),
            ),
            syncNotifierProvider.overrideWith((ref) {
              mockSyncNotifier = MockSyncNotifier(ref);
              return mockSyncNotifier;
            }),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Badge count '3' SHOULD be visible for authenticated user
      expect(find.text('3'), findsOneWidget);

      // Tooltip should reflect unsynced count
      final syncButton = find.byTooltip('Sync with Cloud (3 unsynced)');
      expect(syncButton, findsOneWidget);

      // Tap sync button
      await tester.tap(syncButton);
      await tester.pumpAndSettle();

      // Dialog does NOT appear
      expect(find.text('Sign in to Sync'), findsNothing);
      // Sync is triggered directly
      expect(mockSyncNotifier.syncCalled, isTrue);
    });
  });
}
