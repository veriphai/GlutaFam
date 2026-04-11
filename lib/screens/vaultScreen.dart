import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({Key? key}) : super(key: key);

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  InAppWebViewController? webViewController;
  double progress = 0;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  final String vaultUrl = 'https://superpadhai.com/lesson/vault';

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        hasError = true;
        errorMessage = 'No internet connection available';
        isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    if (webViewController != null) {
      await webViewController!.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Vault',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF131F24),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!isLoading && !hasError)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _refresh,
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          if (isLoading && progress > 0)
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF131F24)),
            ),

          // Main content
          Expanded(
            child: hasError ? _buildErrorView() : _buildWebView(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load content',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  hasError = false;
                  isLoading = true;
                  errorMessage = '';
                });
                _checkConnectivity();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF131F24),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebView() {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(vaultUrl)),
      initialSettings: InAppWebViewSettings(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        iframeAllow: "camera; microphone",
        iframeAllowFullscreen: true,
        javaScriptEnabled: true,
        domStorageEnabled: true,
        databaseEnabled: true,
        clearCache: false,
        cacheEnabled: true,
        mixedContentMode: MixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE,
        useOnLoadResource: true,
        useOnDownloadStart: true,
        useShouldInterceptAjaxRequest: false,
        useShouldInterceptFetchRequest: false,
        applicationNameForUserAgent: "Tuto App",
        userAgent:
            "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36 TutoApp/1.0",
      ),
      onWebViewCreated: (controller) {
        webViewController = controller;
      },
      onLoadStart: (controller, url) {
        setState(() {
          isLoading = true;
          hasError = false;
        });
      },
      onLoadStop: (controller, url) async {
        setState(() {
          isLoading = false;
        });
      },
      onReceivedError: (controller, request, error) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'Failed to load page: ${error.description}';
        });
      },
      onProgressChanged: (controller, progress) {
        setState(() {
          this.progress = progress / 100;
        });
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final uri = navigationAction.request.url!;

        // Allow navigation within the same domain
        if (uri.host.contains('superpadhai.com')) {
          return NavigationActionPolicy.ALLOW;
        }

        // For external links, you might want to open them in the default browser
        // or handle them differently based on your app's requirements
        return NavigationActionPolicy.ALLOW;
      },
      onConsoleMessage: (controller, consoleMessage) {
        print("Console message: ${consoleMessage.message}");
      },
    );
  }
}
