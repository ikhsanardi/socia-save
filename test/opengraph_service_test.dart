import 'package:flutter_test/flutter_test.dart';
import 'package:socia_saver/core/services/opengraph_service.dart';

void main() {
  group('OpenGraphService Platform Detection Tests', () {
    test('Detect Instagram URL', () {
      const url = 'https://www.instagram.com/p/C123456789/';
      expect(OpenGraphService.detectSource(url), equals('Instagram'));
    });

    test('Detect Facebook URL', () {
      const url = 'https://www.facebook.com/watch/?v=987654321';
      expect(OpenGraphService.detectSource(url), equals('Facebook'));
    });

    test('Detect Threads URL', () {
      const url = 'https://www.threads.net/@user/post/12345';
      expect(OpenGraphService.detectSource(url), equals('Threads'));
    });

    test('Detect TikTok URL', () {
      const url = 'https://www.tiktok.com/@user/video/78910';
      expect(OpenGraphService.detectSource(url), equals('TikTok'));
    });

    test('Detect YouTube URL', () {
      const url = 'https://youtu.be/dQw4w9WgXcQ';
      expect(OpenGraphService.detectSource(url), equals('YouTube'));
    });

    test('Detect LinkedIn URL', () {
      const url = 'https://www.linkedin.com/posts/activity-123456789';
      expect(OpenGraphService.detectSource(url), equals('LinkedIn'));
    });

    test('Detect LinkedIn Short URL (lnkd.in)', () {
      const url = 'https://lnkd.in/gAbCdEf';
      expect(OpenGraphService.detectSource(url), equals('LinkedIn'));
    });

    test('Detects clean domain name for custom websites (never returns Other)', () {
      const url = 'https://example.com/article/1';
      expect(OpenGraphService.detectSource(url), equals('Example'));
    });
  });

  group('OpenGraphService URL Extraction Tests', () {
    test('Extract clean URL from raw text', () {
      const text = 'Check out this awesome recipe! https://www.instagram.com/p/recipe123/ so cool!';
      expect(
        OpenGraphService.extractUrl(text),
        equals('https://www.instagram.com/p/recipe123/'),
      );
    });
  });
}
