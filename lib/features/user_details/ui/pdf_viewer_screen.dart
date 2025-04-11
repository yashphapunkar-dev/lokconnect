import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

class PDFViewerScreen extends StatelessWidget {
  final String url;

  const PDFViewerScreen({Key? key, required this.url}) : super(key: key);

  Future<void> _openInNewTab() async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAsset = url.startsWith('assets/');

    if (kIsWeb && !isAsset) {
      // On web, open in new tab instead of embedding
      return Scaffold(
        appBar: AppBar(title: const Text("Document Viewer")),
        body: Center(
          child: ElevatedButton.icon(
            onPressed: _openInNewTab,
            icon: const Icon(Icons.open_in_new),
            label: const Text("Open PDF in New Tab"),
          ),
        ),
      );
    }

    // On mobile or if it's an asset on web
    return Scaffold(
      appBar: AppBar(title: const Text("Document Viewer")),
      body: isAsset
          ? SfPdfViewer.asset(url)
          : SfPdfViewer.network(url),
    );
  }
}
