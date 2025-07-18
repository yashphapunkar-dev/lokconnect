// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// // Conditional import for dart:html (will only be used on web)
// import 'dart:html' as html;
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:lokconnect/constants/custom_colors.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

// // Import for platformViewRegistry for web
// import 'dart:ui' as ui;

// class FirebasePdfViewer extends StatefulWidget {
//   final String downloadUrl;

//   const FirebasePdfViewer({required this.downloadUrl, Key? key}) : super(key: key);

//   @override
//   State<FirebasePdfViewer> createState() => _FirebasePdfViewerState();
// }

// class _FirebasePdfViewerState extends State<FirebasePdfViewer> {
//   Uint8List? _pdfData;
//   bool _isLoading = true;
//   String? _errorMessage; // To store and display error messages

//   // Unique view type for HtmlElementView on web
//   late final String _viewId;

//   @override
//   void initState() {
//     super.initState();
//     if (kIsWeb) {
//       _viewId = 'pdf-viewer-${widget.downloadUrl.hashCode}'; // Unique ID for this instance
//       _registerWebViewFactory(); // Register the view factory for web
//     } else {
//       _loadPdf(); // Load PDF data for mobile/desktop
//     }
//   }

//   // Helper method to register the web view factory
//   void _registerWebViewFactory() {
//     try {
//       ui.platformViewRegistry.registerViewFactory(
//         _viewId,
//         (int viewId) {
//           final iframe = html.IFrameElement()
//             ..src = widget.downloadUrl
//             ..style.border = 'none'
//             ..width = '100%'
//             ..height = '100%'
//             ..allowFullscreen = true;
//           return iframe;
//         },
//       );
//     } catch (e) {
//       print('Error registering view factory for $_viewId: $e');
//       setState(() {
//         _errorMessage = 'Failed to load PDF viewer. Please try again.';
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _loadPdf() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null; // Clear previous errors
//     });
//     try {
//       final response = await http.get(Uri.parse(widget.downloadUrl));
//       if (response.statusCode == 200) {
//         if (mounted) {
//           setState(() {
//             _pdfData = response.bodyBytes;
//             _isLoading = false;
//           });
//         }
//       } else {
//         if (mounted) {
//           setState(() {
//             _errorMessage = 'Failed to load PDF. Status code: ${response.statusCode}';
//             _isLoading = false;
//           });
//         }
//         print('Error loading PDF: HTTP status ${response.statusCode}');
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _errorMessage = 'Error loading PDF: ${e.toString()}';
//           _isLoading = false;
//         });
//       }
//       print('Error loading PDF: $e');
//     }
//   }

//   // The _downloadPdf method is no longer called from the UI,
//   // but keeping it here for completeness if you decide to add it back later for mobile.
//   // For non-web platforms, you would typically use packages like `path_provider`
//   // and `open_filex` or `flutter_file_downloader` to save and open the file.
//   void _downloadPdf() {
//     print('Download functionality for non-web platforms is disabled in UI.');
//   }


//   @override
//   Widget build(BuildContext context) {
//     if (kIsWeb) {
//       return Scaffold(
//         appBar: AppBar(
//           title: const Text("PDF Viewer (Web)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
//           backgroundColor: CustomColors.forestBrown,
//         ),
//         body: _errorMessage != null
//             ? Center(
//                 child: Text(
//                   _errorMessage!,
//                   style: const TextStyle(color: Colors.red, fontSize: 16),
//                   textAlign: TextAlign.center,
//                 ),
//               )
//             : HtmlElementView(viewType: _viewId), // Use the unique _viewId here
//       );
//     } else {
//       // Mobile/Desktop implementation using SfPdfViewer.memory
//       return Scaffold(
//         appBar: AppBar(
//         centerTitle: true,
//         leading: IconButton(
//           icon: Icon(
//             Icons.arrow_back_ios,
//             color: Colors.white,
//           ),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//         title: Text(
//           "PDF Viewer (web)",
//           style: CustomTextStyle.headingTextStyle,
//         ),
//         backgroundColor: CustomColors.oceanBlue,
//       ),
       
//         body: _isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : _errorMessage != null
//                 ? Center(
//                     child: Text(
//                       _errorMessage!,
//                       style: const TextStyle(color: Colors.red, fontSize: 16),
//                       textAlign: TextAlign.center,
//                     ),
//                   )
//                 : SfPdfViewer.memory(_pdfData!),
//       );
//     }
//   }
// }