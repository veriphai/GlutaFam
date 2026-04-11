import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// Flutter screen that embeds Manim Web animations using WebView
///
/// To use this:
/// 1. First, build your manim_web animation to a static HTML file
/// 2. Place the output in assets/manim_animations/
/// 3. Load it in the WebView
class ManimWebFlutterScreen extends StatefulWidget {
  final String? animationUrl;
  final String? localAssetPath;

  const ManimWebFlutterScreen({
    Key? key,
    this.animationUrl,
    this.localAssetPath,
  }) : super(key: key);

  @override
  State<ManimWebFlutterScreen> createState() => _ManimWebFlutterScreenState();
}

class _ManimWebFlutterScreenState extends State<ManimWebFlutterScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    late final PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
          },
        ),
      );

    // Load URL or local asset
    if (widget.animationUrl != null) {
      _controller.loadRequest(Uri.parse(widget.animationUrl!));
    } else if (widget.localAssetPath != null) {
      _controller.loadFlutterAsset(widget.localAssetPath!);
    } else {
      // Load inline HTML with a simple example
      _loadInlineExample();
    }
  }

  void _loadInlineExample() {
    const htmlContent = '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            body {
                margin: 0;
                padding: 20px;
                background-color: #1a1a1a;
                color: white;
                font-family: Arial, sans-serif;
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
                min-height: 100vh;
            }
            .container {
                text-align: center;
                max-width: 600px;
            }
            h1 {
                color: #4CAF50;
                margin-bottom: 20px;
            }
            .instructions {
                background-color: rgba(255, 255, 255, 0.1);
                padding: 20px;
                border-radius: 10px;
                margin-top: 20px;
                text-align: left;
            }
            .code {
                background-color: rgba(0, 0, 0, 0.5);
                padding: 10px;
                border-radius: 5px;
                font-family: monospace;
                margin: 10px 0;
                overflow-x: auto;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🎬 Manim Web in Flutter</h1>
            <p>To embed your Manim Web animations here:</p>
            
            <div class="instructions">
                <h3>Steps:</h3>
                <ol>
                    <li>Build your animation to HTML:
                        <div class="code">manimweb build --file src/scene.dart --html output.html</div>
                    </li>
                    <li>Host it locally or on a server</li>
                    <li>Pass the URL to this widget:
                        <div class="code">ManimWebFlutterScreen(animationUrl: 'http://localhost:8080')</div>
                    </li>
                </ol>
                
                <h3>Or use a local asset:</h3>
                <ol>
                    <li>Place your built HTML in assets/</li>
                    <li>Add to pubspec.yaml assets section</li>
                    <li>Use:
                        <div class="code">ManimWebFlutterScreen(localAssetPath: 'assets/animation.html')</div>
                    </li>
                </ol>
            </div>
        </div>
    </body>
    </html>
    ''';

    _controller.loadHtmlString(htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manim Web Animation'),
        backgroundColor: Colors.blueGrey[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

/// Example usage screen with different loading options
class ManimWebExampleScreen extends StatelessWidget {
  const ManimWebExampleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manim Web Examples'),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Choose how to load Manim Web:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Option 1: Local dev server
          _buildOptionCard(
            context,
            icon: Icons.developer_mode,
            title: 'Local Dev Server',
            description:
                'Load from localhost:8080 (dev server must be running)',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManimWebFlutterScreen(
                    animationUrl: 'http://localhost:8080',
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Option 2: Local asset
          _buildOptionCard(
            context,
            icon: Icons.folder,
            title: 'Local Asset',
            description: 'Load from app assets (must be built first)',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManimWebFlutterScreen(
                    localAssetPath: 'lib/screens/manim_web_test.html',
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Option 3: Instructions
          _buildOptionCard(
            context,
            icon: Icons.info,
            title: 'Instructions',
            description: 'View setup instructions',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManimWebFlutterScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // Info section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.lightbulb, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'How it works',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '1. Manim Web animations run as web content\n'
                  '2. WebView displays them in your Flutter app\n'
                  '3. JavaScript and Canvas APIs handle rendering\n'
                  '4. LaTeX is rendered via MathJax',
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.blue[700], size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
