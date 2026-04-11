import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class HtmlRenderScreen extends StatefulWidget {
  final String htmlContent;
  final String title;
  final bool showAppBar;
  final Color? backgroundColor;

  const HtmlRenderScreen({
    super.key,
    required this.htmlContent,
    this.title = 'HTML Content',
    this.showAppBar = true,
    this.backgroundColor,
  });

  @override
  State<HtmlRenderScreen> createState() => _HtmlRenderScreenState();
}

class _HtmlRenderScreenState extends State<HtmlRenderScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading progress if needed
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _error = null;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _error = 'Failed to load content: ${error.description}';
            });
          },
        ),
      );

    // Load the HTML content
    _loadHtmlContent();
  }

  void _loadHtmlContent() {
    // Create a complete HTML document with proper styling
    final String completeHtml = '''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>${widget.title}</title>
        <style>
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                line-height: 1.6;
                margin: 16px;
                background-color: ${widget.backgroundColor != null ? _colorToHex(widget.backgroundColor!) : '#ffffff'};
            }
            * {
                box-sizing: border-box;
            }
            img {
                max-width: 100%;
                height: auto;
            }
            table {
                width: 100%;
                border-collapse: collapse;
            }
            th, td {
                border: 1px solid #ddd;
                padding: 8px;
                text-align: left;
            }
            th {
                background-color: #f2f2f2;
            }
            code {
                background-color: #f4f4f4;
                padding: 2px 4px;
                border-radius: 4px;
                font-family: 'Courier New', monospace;
            }
            pre {
                background-color: #f4f4f4;
                padding: 12px;
                border-radius: 4px;
                overflow-x: auto;
            }
            blockquote {
                border-left: 4px solid #ccc;
                margin: 0;
                padding-left: 16px;
                font-style: italic;
            }
        </style>
    </head>
    <body>
        ${widget.htmlContent}
    </body>
    </html>
    ''';

    _controller.loadHtmlString(completeHtml);
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor ?? Colors.white,
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(
                widget.title,
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    _loadHtmlContent();
                  },
                ),
              ],
            )
          : null,
      body: Stack(
        children: [
          if (_error != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      color: Colors.red[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      _loadHtmlContent();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(255, 217, 0, 1),
                      foregroundColor: Colors.black,
                    ),
                    child: Text(
                      'Retry',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.fromRGBO(255, 217, 0, 1),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: widget.showAppBar
          ? null
          : FloatingActionButton(
              onPressed: () => Navigator.of(context).pop(),
              backgroundColor: const Color.fromRGBO(255, 217, 0, 1),
              child: const Icon(
                Icons.close,
                color: Colors.black,
              ),
            ),
    );
  }
}

// Extension to make it easier to use the screen
extension HtmlRenderScreenExtension on BuildContext {
  void showHtmlContent({
    required String htmlContent,
    String title = 'HTML Content',
    bool showAppBar = true,
    Color? backgroundColor,
  }) {
    Navigator.push(
      this,
      MaterialPageRoute(
        builder: (context) => HtmlRenderScreen(
          htmlContent: htmlContent,
          title: title,
          showAppBar: showAppBar,
          backgroundColor: backgroundColor,
        ),
      ),
    );
  }
}
