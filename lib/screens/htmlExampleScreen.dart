import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'htmlRenderScreen.dart';

class HtmlExampleScreen extends StatefulWidget {
  const HtmlExampleScreen({super.key});

  @override
  State<HtmlExampleScreen> createState() => _HtmlExampleScreenState();
}

class _HtmlExampleScreenState extends State<HtmlExampleScreen> {
  String? _physicsHtmlContent;
  bool _isLoadingPhysicsHtml = false;

  @override
  void initState() {
    super.initState();
    _loadPhysicsHtml();
  }

  Future<void> _loadPhysicsHtml() async {
    setState(() {
      _isLoadingPhysicsHtml = true;
    });

    try {
      final String content =
          await rootBundle.loadString('lib/screens/testing.html');
      setState(() {
        _physicsHtmlContent = content;
        _isLoadingPhysicsHtml = false;
      });
    } catch (e) {
      setState(() {
        _physicsHtmlContent = null;
        _isLoadingPhysicsHtml = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load physics simulation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Sample HTML content - replace this with your actual HTML
  static const String sampleHtmlContent = '''
    <h1>Welcome to HTML Rendering!</h1>
    <p>This is a sample HTML content that demonstrates various HTML elements:</p>
    
    <h2>Text Formatting</h2>
    <p>This is <strong>bold text</strong> and this is <em>italic text</em>.</p>
    <p>You can also have <code>inline code</code> snippets.</p>
    
    <h2>Lists</h2>
    <ul>
        <li>First item in unordered list</li>
        <li>Second item with <a href="#" onclick="alert('Link clicked!')">a link</a></li>
        <li>Third item</li>
    </ul>
    
    <ol>
        <li>First item in ordered list</li>
        <li>Second item</li>
        <li>Third item</li>
    </ol>
    
    <h2>Code Block</h2>
    <pre><code>
function greet(name) {
    console.log("Hello, " + name + "!");
}

greet("World");
    </code></pre>
    
    <h2>Table</h2>
    <table>
        <tr>
            <th>Name</th>
            <th>Age</th>
            <th>City</th>
        </tr>
        <tr>
            <td>John Doe</td>
            <td>25</td>
            <td>New York</td>
        </tr>
        <tr>
            <td>Jane Smith</td>
            <td>30</td>
            <td>Los Angeles</td>
        </tr>
    </table>
    
    <h2>Blockquote</h2>
    <blockquote>
        "The best way to predict the future is to create it." - Peter Drucker
    </blockquote>
    
    <h2>Image (placeholder)</h2>
    <p>Images would render here if you include img tags with proper src attributes.</p>
    
    <hr>
    <p><small>This HTML content is rendered using WebView in Flutter.</small></p>
  ''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'HTML Render Example',
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'HTML Content Renderer',
              style: GoogleFonts.raleway(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'This screen demonstrates how to render HTML content in your Flutter app using WebView.',
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Example buttons for different use cases
            _buildExampleButton(
              context,
              title: 'Render Sample HTML',
              subtitle: 'View HTML with various elements',
              onPressed: () {
                context.showHtmlContent(
                  htmlContent: sampleHtmlContent,
                  title: 'Sample HTML Content',
                );
              },
            ),

            const SizedBox(height: 16),

            _buildExampleButton(
              context,
              title: 'Custom Styled HTML',
              subtitle: 'HTML with custom background',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HtmlRenderScreen(
                      htmlContent: '''
                        <div style="text-align: center; padding: 20px;">
                          <h1 style="color: #333;">Custom Styled Content</h1>
                          <p style="color: #666; font-size: 18px;">This HTML has custom background color.</p>
                          <div style="background: linear-gradient(45deg, #ff6b6b, #4ecdc4); padding: 20px; border-radius: 10px; color: white; margin: 20px 0;">
                            <h3>Gradient Background</h3>
                            <p>This demonstrates custom styling capabilities.</p>
                          </div>
                        </div>
                      ''',
                      title: 'Custom Styled HTML',
                      backgroundColor: Colors.grey[100],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            _buildExampleButton(
              context,
              title: 'Fullscreen HTML',
              subtitle: 'HTML without app bar',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HtmlRenderScreen(
                      htmlContent: '''
                        <div style="height: 100vh; display: flex; align-items: center; justify-content: center; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; text-align: center;">
                          <div>
                            <h1 style="font-size: 3em; margin-bottom: 20px;">Fullscreen HTML</h1>
                            <p style="font-size: 1.2em;">This HTML takes up the full screen without an app bar.</p>
                            <p style="margin-top: 30px; opacity: 0.8;">Tap the floating button to close.</p>
                          </div>
                        </div>
                      ''',
                      title: 'Fullscreen Content',
                      showAppBar: false,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            _buildExampleButton(
              context,
              title: _isLoadingPhysicsHtml
                  ? 'Loading Physics Simulation...'
                  : 'Physics Simulation',
              subtitle: _isLoadingPhysicsHtml
                  ? 'Please wait...'
                  : 'Interactive Matter.js momentum demo',
              onPressed: _isLoadingPhysicsHtml
                  ? null
                  : () {
                      if (_physicsHtmlContent != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HtmlRenderScreen(
                              htmlContent: _physicsHtmlContent!,
                              title: 'Physics Simulation',
                              showAppBar: true,
                              backgroundColor: const Color(
                                  0xFF0b1022), // Match the simulation's background
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Physics simulation failed to load. Please try again.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        _loadPhysicsHtml(); // Retry loading
                      }
                    },
            ),

            const Spacer(),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Usage Instructions:',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Replace sampleHtmlContent with your HTML\n'
                    '2. Use context.showHtmlContent() for quick display\n'
                    '3. Use HtmlRenderScreen() for more control\n'
                    '4. Customize title, background, and app bar',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed != null
            ? const Color.fromRGBO(255, 217, 0, 1)
            : Colors.grey[300],
        foregroundColor: onPressed != null ? Colors.black : Colors.grey[600],
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: Colors.black.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
