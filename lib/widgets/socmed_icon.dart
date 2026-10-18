import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/services/opengraph_service.dart';

/// Renders the authentic, original social media platform icon using official vector assets.
/// Never substitutes brand logos with generic Material icons.
class SocmedIcon extends StatelessWidget {
  final String source;
  final String? url;
  final double size;

  const SocmedIcon({
    super.key,
    required this.source,
    this.url,
    this.size = 20,
  });

  static const String _linkedInSvg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
  <rect width="24" height="24" rx="4" fill="#0A66C2"/>
  <path fill="#FFFFFF" d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452z"/>
</svg>''';

  static const String _instagramSvg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
  <defs>
    <linearGradient id="ig-grad" x1="0%" y1="100%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#FFD600"/>
      <stop offset="25%" stop-color="#FF7A00"/>
      <stop offset="50%" stop-color="#FF0069"/>
      <stop offset="75%" stop-color="#D300C5"/>
      <stop offset="100%" stop-color="#7638FA"/>
    </linearGradient>
  </defs>
  <rect width="24" height="24" rx="5" fill="url(#ig-grad)"/>
  <path fill="none" stroke="#FFFFFF" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" d="M16.5 4h-9a3.5 3.5 0 0 0-3.5 3.5v9a3.5 3.5 0 0 0 3.5 3.5h9a3.5 3.5 0 0 0 3.5-3.5v-9A3.5 3.5 0 0 0 16.5 4z"/>
  <circle cx="12" cy="12" r="3.4" fill="none" stroke="#FFFFFF" stroke-width="1.8"/>
  <circle cx="16.8" cy="7.2" r="1" fill="#FFFFFF"/>
</svg>''';

  static const String _facebookSvg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
  <circle cx="12" cy="12" r="12" fill="#1877F2"/>
  <path fill="#FFFFFF" d="M15.117 12.073h-2.125V20h-3.28v-7.927H8.25v-2.79h1.462V7.545c0-1.448.687-3.708 3.708-3.708l2.723.011v2.709h-1.975c-.326 0-.783.163-.783.856v1.942h2.784l-.352 2.718z"/>
</svg>''';

  static const String _xSvg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
  <rect width="24" height="24" rx="4" fill="#000000"/>
  <path fill="#FFFFFF" d="M17.53 4h2.518l-5.5 6.287L21 19.5h-5.067l-3.968-5.188L7.42 19.5H4.9l5.885-6.727L4.5 4h5.196l3.588 4.743L17.53 4zm-.884 14.04h1.395L8.766 5.37H7.269l9.377 12.67z"/>
</svg>''';

  static const String _youtubeSvg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
  <rect width="24" height="24" rx="5" fill="#FF0000"/>
  <path fill="#FFFFFF" d="M9.75 8.25v7.5l6.5-3.75-6.5-3.75z"/>
</svg>''';

  static const String _tikTokSvg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
  <rect width="24" height="24" rx="4" fill="#000000"/>
  <path fill="#25F4EE" d="M15.8 7.3c-.6-.7-.9-1.6-1-2.5h-2.1v9.6c0 1.4-1.1 2.5-2.5 2.5-1.4 0-2.5-1.1-2.5-2.5 0-1.2.9-2.3 2.1-2.5v-2.2c-2.4.2-4.3 2.2-4.3 4.7 0 2.6 2.1 4.7 4.7 4.7 2.6 0 4.7-2.1 4.7-4.7V9.7c1-.7 2.1-1.1 3.4-1.2V6.4c-.9 0-1.8.3-2.5.9z"/>
  <path fill="#FE2C55" d="M16.8 6.3c.7-.6 1.6-.9 2.5-.9V3.2c-1.3.1-2.5.5-3.5 1.2v6.6c0 2.6-2.1 4.7-4.7 4.7-2.6 0-4.7-2.1-4.7-4.7 0-2.4 1.9-4.5 4.3-4.7v2.2c-1.2.2-2.1 1.2-2.1 2.5 0 1.4 1.1 2.5 2.5 2.5 1.4 0 2.5-1.1 2.5-2.5V1.2h2.2c0 .9.3 1.8 1 2.5z"/>
  <path fill="#FFFFFF" d="M16.3 6.8c-.7-.6-1.6-.9-2.5-.9V3.7c1.3.1 2.5.5 3.5 1.2v6.6c0 2.6-2.1 4.7-4.7 4.7-2.6 0-4.7-2.1-4.7-4.7 0-2.4 1.9-4.5 4.3-4.7v2.2c-1.2.2-2.1 1.2-2.1 2.5 0 1.4 1.1 2.5 2.5 2.5 1.4 0 2.5-1.1 2.5-2.5V1.7h2.2c0 .9.3 1.8 1 2.5.7.7 1.6 1 2.5 1v2.2c-1.4-.1-2.6-.6-3.6-1.3-.3.2-.6.5-.9.7z"/>
</svg>''';

  static const String _threadsSvg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
  <rect width="24" height="24" rx="4" fill="#101010"/>
  <path fill="#FFFFFF" d="M12.186 19.2c-3.9 0-7.05-3.15-7.05-7.05s3.15-7.05 7.05-7.05c3.85 0 6.94 3.06 6.98 6.9h-1.5c-.04-3.03-2.46-5.4-5.48-5.4-3.07 0-5.55 2.48-5.55 5.55s2.48 5.55 5.55 5.55c2.72 0 4.96-1.95 5.43-4.55h-4.33c-1.45 0-2.63-1.18-2.63-2.63s1.18-2.63 2.63-2.63c1.35 0 2.47.98 2.6 2.3h1.52c-.15-2.14-1.93-3.8-4.12-3.8-2.28 0-4.13 1.85-4.13 4.13s1.85 4.13 4.13 4.13c1.9 0 3.52-1.23 3.99-2.95h1.56c-.5 2.55-2.73 4.45-5.38 4.45z"/>
</svg>''';

  static const String _pinterestSvg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
  <circle cx="12" cy="12" r="12" fill="#E60023"/>
  <path fill="#FFFFFF" d="M12 4a8 8 0 0 0-2.8 15.5c-.05-.66-.1-1.68.02-2.4l.84-3.56s-.21-.43-.21-1.07c0-1 .58-1.75 1.3-1.75.61 0 .91.46.91 1.01 0 .62-.39 1.54-.6 2.4-.17.72.36 1.3 1.07 1.3 1.28 0 2.26-1.35 2.26-3.3 0-1.72-1.24-2.93-3.01-2.93-2.05 0-3.25 1.54-3.25 3.12 0 .62.24 1.28.54 1.64.06.07.07.14.05.21l-.2.81c-.03.14-.11.17-.26.1-1-.46-1.6-1.9-1.6-3.06 0-2.5 1.81-4.78 5.22-4.78 2.74 0 4.88 1.95 4.88 4.57 0 2.72-1.72 4.92-4.1 4.92-.8 0-1.55-.42-1.81-.91l-.49 1.89c-.18.69-.66 1.55-.99 2.07A8 8 0 1 0 12 4z"/>
</svg>''';

  static const String _redditSvg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
  <circle cx="12" cy="12" r="12" fill="#FF4500"/>
  <path fill="#FFFFFF" d="M17.7 11.2c-.3 0-.6.1-.8.3-1-.7-2.4-1.2-4-1.2l.7-3.3 2.3.5c0 .7.6 1.2 1.3 1.2.7 0 1.3-.6 1.3-1.3s-.6-1.3-1.3-1.3c-.5 0-1 .3-1.2.8l-2.6-.5c-.1 0-.3.1-.3.2l-.8 3.8c-1.6 0-3 .5-4 1.2-.2-.2-.5-.3-.8-.3-.8 0-1.5.7-1.5 1.5 0 .6.3 1.1.8 1.3 0 .2 0 .3 0 .5 0 2.5 2.8 4.5 6.3 4.5s6.3-2 6.3-4.5c0-.2 0-.3 0-.5.5-.2.8-.7.8-1.3 0-.8-.6-1.4-1.5-1.4zm-8.2 1.5c.5 0 .9.4.9.9s-.4.9-.9.9-.9-.4-.9-.9.4-.9.9-.9zm5.5 3.8c-.8.8-2.2.8-3 0-.1-.1-.1-.3 0-.4.1-.1.3-.1.4 0 .6.6 1.6.6 2.2 0 .1-.1.3-.1.4 0 .1.1.1.3 0 .4zm-.5-2c-.5 0-.9-.4-.9-.9s.4-.9.9-.9.9.4.9.9-.4.9-.9.9z"/>
</svg>''';

  static const String _defaultGlobeSvg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
  <circle cx="12" cy="12" r="12" fill="#64748B"/>
  <path fill="none" stroke="#FFFFFF" stroke-width="1.8" stroke-linecap="round" d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zM2 12h20M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/>
</svg>''';

  @override
  Widget build(BuildContext context) {
    String resolvedSource = source.trim();
    if ((resolvedSource.isEmpty || resolvedSource.toLowerCase() == 'other') &&
        url != null &&
        url!.trim().isNotEmpty) {
      resolvedSource = OpenGraphService.detectSource(url!);
    }

    String svgContent;
    switch (resolvedSource.toLowerCase()) {
      case 'linkedin':
        svgContent = _linkedInSvg;
        break;
      case 'instagram':
        svgContent = _instagramSvg;
        break;
      case 'facebook':
        svgContent = _facebookSvg;
        break;
      case 'threads':
        svgContent = _threadsSvg;
        break;
      case 'tiktok':
        svgContent = _tikTokSvg;
        break;
      case 'youtube':
        svgContent = _youtubeSvg;
        break;
      case 'x' || 'twitter':
        svgContent = _xSvg;
        break;
      case 'pinterest':
        svgContent = _pinterestSvg;
        break;
      case 'reddit':
        svgContent = _redditSvg;
        break;
      default:
        svgContent = _defaultGlobeSvg;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: SvgPicture.string(
        svgContent,
        width: size,
        height: size,
        fit: BoxFit.contain,
        semanticsLabel: '$resolvedSource logo',
      ),
    );
  }
}
