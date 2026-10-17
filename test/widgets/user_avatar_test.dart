import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:socia_saver/widgets/user_avatar.dart';

class MockUserInfo extends Fake implements UserInfo {
  @override
  final String? displayName;
  @override
  final String? email;
  @override
  final String? photoURL;
  @override
  final String providerId;

  MockUserInfo({
    this.displayName,
    this.email,
    this.photoURL,
    required this.providerId,
  });
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
  group('UserAvatar Widget Tests', () {
    testWidgets('renders guest icon when anonymous and no photo',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              isAnonymous: true,
              radius: 20,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
      expect(find.byType(Text), findsNothing);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('renders initial letter when authenticated without photo (from displayName)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              isAnonymous: false,
              displayName: 'John Doe',
              email: 'john@example.com',
              radius: 20,
            ),
          ),
        ),
      );

      expect(find.text('J'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline_rounded), findsNothing);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('renders initial letter from email when displayName is empty',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              isAnonymous: false,
              displayName: '',
              email: 'alice@example.com',
              radius: 20,
            ),
          ),
        ),
      );

      expect(find.text('A'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline_rounded), findsNothing);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('renders Image.network when photoUrl is provided',
        (tester) async {
      const testUrl = 'https://example.com/avatar.png';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              isAnonymous: false,
              displayName: 'Jane Doe',
              photoUrl: testUrl,
              radius: 20,
            ),
          ),
        ),
      );

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final Image imageWidget = tester.widget(imageFinder);
      expect(imageWidget.image, isA<NetworkImage>());
      final networkImage = imageWidget.image as NetworkImage;
      expect(networkImage.url, equals(testUrl));
    });

    testWidgets('renders border decoration when border is provided',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              isAnonymous: true,
              radius: 28,
              border: Border.all(color: Colors.blue, width: 2),
            ),
          ),
        ),
      );

      final containerFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final box = widget.decoration as BoxDecoration;
          return box.border != null;
        }
        return false;
      });

      expect(containerFinder, findsOneWidget);
    });

    testWidgets(
        'UserAvatar.fromUser extracts photoUrl from providerData when root photoURL is null',
        (tester) async {
      const googlePhoto = 'https://lh3.googleusercontent.com/a/google_avatar.png';

      final user = MockUser(
        photoURL: null,
        displayName: null,
        isAnonymous: false,
        providerData: [
          MockUserInfo(
            providerId: 'google.com',
            photoURL: googlePhoto,
            displayName: 'Google Account',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserAvatar.fromUser(
              user: user,
              radius: 20,
            ),
          ),
        ),
      );

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final Image imageWidget = tester.widget(imageFinder);
      expect(imageWidget.image, isA<NetworkImage>());
      final networkImage = imageWidget.image as NetworkImage;
      expect(networkImage.url, equals(googlePhoto));
    });

    testWidgets(
        'UserAvatar.fromUser upgrades http URL to https for Android security',
        (tester) async {
      const httpPhoto = 'http://lh3.googleusercontent.com/avatar.png';
      const httpsPhoto = 'https://lh3.googleusercontent.com/avatar.png';

      final user = MockUser(
        photoURL: httpPhoto,
        isAnonymous: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserAvatar.fromUser(
              user: user,
              radius: 20,
            ),
          ),
        ),
      );

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final Image imageWidget = tester.widget(imageFinder);
      final networkImage = imageWidget.image as NetworkImage;
      expect(networkImage.url, equals(httpsPhoto));
    });
  });
}
