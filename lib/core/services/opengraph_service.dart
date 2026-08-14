import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

class OpenGraphData {
  final String title;
  final String? thumbnailUrl;
  final String socmedSource;
  final String rawUrl;

  OpenGraphData({
    required this.title,
    this.thumbnailUrl,
    required this.socmedSource,
    required this.rawUrl,
  });
}

class OpenGraphService {
  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (iPhone; CPU iPhone OS 16_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Mobile/15E148 Safari/604.1',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
  };

  static String detectSource(String url) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('instagram.com') || lowerUrl.contains('instagr.am')) {
      return 'Instagram';
    } else if (lowerUrl.contains('facebook.com') || lowerUrl.contains('fb.watch') || lowerUrl.contains('fb.com')) {
      return 'Facebook';
    } else if (lowerUrl.contains('threads.net')) {
      return 'Threads';
    } else if (lowerUrl.contains('tiktok.com')) {
      return 'TikTok';
    } else if (lowerUrl.contains('youtube.com') || lowerUrl.contains('youtu.be')) {
      return 'YouTube';
    } else if (lowerUrl.contains('twitter.com') || lowerUrl.contains('x.com')) {
      return 'X';
    }
    return 'Other';
  }

  static String extractUrl(String rawText) {
    final urlRegExp = RegExp(
      r'https?://[^\s<>"]+|www\.[^\s<>"]+',
      caseSensitive: false,
    );
    final match = urlRegExp.firstMatch(rawText);
    if (match != null) {
      return match.group(0)!;
    }
    return rawText.trim();
  }

  static Future<OpenGraphData> fetchMetadata(String inputUrl) async {
    final targetUrl = extractUrl(inputUrl);
    final socmedSource = detectSource(targetUrl);

    String fallbackTitle = targetUrl;
    try {
      final uri = Uri.parse(targetUrl);
      if (uri.host.isNotEmpty) {
        fallbackTitle = '$socmedSource Content (${uri.host})';
      }
    } catch (_) {}

    try {
      final response = await http
          .get(Uri.parse(targetUrl), headers: _headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);

        // Try OpenGraph tags first
        String? title = document
            .querySelector('meta[property="og:title"]')
            ?.attributes['content'];
        title ??= document
            .querySelector('meta[name="title"]')
            ?.attributes['content'];
        title ??= document.querySelector('title')?.text.trim();

        String? image = document
            .querySelector('meta[property="og:image"]')
            ?.attributes['content'];
        image ??= document
            .querySelector('meta[name="image"]')
            ?.attributes['content'];

        return OpenGraphData(
          title: (title != null && title.isNotEmpty) ? title : fallbackTitle,
          thumbnailUrl: image,
          socmedSource: socmedSource,
          rawUrl: targetUrl,
        );
      }
    } catch (e) {
      // Return fallback gracefully on network/timeout error
    }

    return OpenGraphData(
      title: fallbackTitle,
      thumbnailUrl: null,
      socmedSource: socmedSource,
      rawUrl: targetUrl,
    );
  }
}
