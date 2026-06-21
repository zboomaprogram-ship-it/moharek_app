import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:moharek_app/shared/widgets/image_viewer_screen.dart';
import 'package:moharek_app/shared/widgets/pdf_viewer_screen.dart';

Future<void> openFileInApp(BuildContext context, String url, String title) async {
  final cleanUrl = url.trim();
  final lowerUrl = cleanUrl.toLowerCase();

  // 1. PDF
  if (lowerUrl.contains('.pdf') || lowerUrl.endsWith('.pdf')) {
    if (kIsWeb) {
      final uri = Uri.parse(cleanUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(url: cleanUrl, title: title),
      ),
    );
    return;
  }

  // 2. Images
  if (lowerUrl.contains('.png') || lowerUrl.endsWith('.png') ||
      lowerUrl.contains('.jpg') || lowerUrl.endsWith('.jpg') ||
      lowerUrl.contains('.jpeg') || lowerUrl.endsWith('.jpeg') ||
      lowerUrl.contains('.gif') || lowerUrl.endsWith('.gif') ||
      lowerUrl.contains('.webp') || lowerUrl.endsWith('.webp') ||
      lowerUrl.contains('.bmp') || lowerUrl.endsWith('.bmp')) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImageViewerScreen(url: cleanUrl, title: title),
      ),
    );
    return;
  }

  // 3. Office Docs (Word, Excel, PowerPoint, Text, CSV)
  if (lowerUrl.contains('.doc') || lowerUrl.contains('.docx') ||
      lowerUrl.contains('.xls') || lowerUrl.contains('.xlsx') ||
      lowerUrl.contains('.ppt') || lowerUrl.contains('.pptx') ||
      lowerUrl.contains('.txt') || lowerUrl.contains('.csv')) {
    final viewerUrl = 'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(cleanUrl)}';
    final uri = Uri.parse(viewerUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    }
    return;
  }

  // 4. Fallback: Normal links / files opened in-app WebView
  final uri = Uri.parse(cleanUrl);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.inAppWebView);
  }
}
