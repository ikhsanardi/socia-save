import 'dart:convert';
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

  static String? getOEmbedEndpoint(String url, String source) {
    final encodedUrl = Uri.encodeComponent(url);
    switch (source) {
      case 'YouTube':
        return 'https://www.youtube.com/oembed?url=$encodedUrl&format=json';
      case 'TikTok':
        return 'https://www.tiktok.com/oembed?url=$encodedUrl';
      case 'X':
        return 'https://publish.twitter.com/oembed?url=$encodedUrl&omit_script=true';
      case 'Reddit':
        return 'https://www.reddit.com/oembed?url=$encodedUrl';
      default:
        return null;
    }
  }

  static Future<OpenGraphData?> _fetchFromOEmbed(
    String targetUrl,
    String socmedSource,
  ) async {
    final endpoint = getOEmbedEndpoint(targetUrl, socmedSource);
    if (endpoint == null) return null;

    try {
      final response = await http
          .get(Uri.parse(endpoint), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        String? title = data['title'] as String?;
        String? thumbnail = data['thumbnail_url'] as String?;
        final author = data['author_name'] as String?;

        // Fallback for X/Twitter where title might be empty but author/html exist
        if ((title == null || title.trim().isEmpty) && author != null && author.isNotEmpty) {
          final html = data['html'] as String? ?? '';
          final textMatch = RegExp(r'<p[^>]*>(.*?)</p>').firstMatch(html);
          if (textMatch != null) {
            final rawParagraph = textMatch
                .group(1)!
                .replaceAll(RegExp(r'<[^>]*>'), '')
                .replaceAll('&quot;', '"')
                .replaceAll('&amp;', '&')
                .trim();
            if (rawParagraph.isNotEmpty) {
              title = '$author: $rawParagraph';
            }
          }
          title ??= 'Post by $author on X';
        }

        if (title != null && title.trim().isNotEmpty) {
          return OpenGraphData(
            title: title.trim(),
            thumbnailUrl: thumbnail,
            socmedSource: socmedSource,
            rawUrl: targetUrl,
          );
        }
      }
    } catch (_) {
      // Graceful fallback to HTML scraper on error or timeout
    }
    return null;
  }

  static String detectSource(String url) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('linkedin.com') ||
        lowerUrl.contains('lnkd.in') ||
        lowerUrl.contains('licdn.com') ||
        lowerUrl.contains('linkedin.cn')) {
      return 'LinkedIn';
    } else if (lowerUrl.contains('instagram.com') ||
        lowerUrl.contains('instagr.am')) {
      return 'Instagram';
    } else if (lowerUrl.contains('facebook.com') ||
        lowerUrl.contains('fb.watch') ||
        lowerUrl.contains('fb.com') ||
        lowerUrl.contains('fb.me')) {
      return 'Facebook';
    } else if (lowerUrl.contains('threads.net') ||
        lowerUrl.contains('threads.com')) {
      return 'Threads';
    } else if (lowerUrl.contains('tiktok.com')) {
      return 'TikTok';
    } else if (lowerUrl.contains('youtube.com') ||
        lowerUrl.contains('youtu.be')) {
      return 'YouTube';
    } else if (lowerUrl.contains('twitter.com') ||
        lowerUrl.contains('x.com') ||
        lowerUrl.contains('t.co')) {
      return 'X';
    } else if (lowerUrl.contains('pinterest.com') ||
        lowerUrl.contains('pin.it')) {
      return 'Pinterest';
    } else if (lowerUrl.contains('reddit.com') ||
        lowerUrl.contains('redd.it')) {
      return 'Reddit';
    } else if (lowerUrl.contains('github.com')) {
      return 'GitHub';
    }

    // Extract domain name so we never show "Other" as a text label
    try {
      var cleanUrl = url.trim();
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }
      final uri = Uri.tryParse(cleanUrl);
      if (uri != null && uri.host.isNotEmpty) {
        var host = uri.host.toLowerCase();
        if (host.startsWith('www.')) host = host.substring(4);
        final parts = host.split('.');
        if (parts.isNotEmpty && parts.first.isNotEmpty) {
          final domain = parts.first;
          return domain[0].toUpperCase() + domain.substring(1);
        }
      }
    } catch (_) {}

    return 'Social Media';
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

    // 1. Try fast & high-reliability oEmbed endpoints first (YouTube, TikTok, X, Reddit)
    final oEmbedData = await _fetchFromOEmbed(targetUrl, socmedSource);
    if (oEmbedData != null) {
      return oEmbedData;
    }

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
