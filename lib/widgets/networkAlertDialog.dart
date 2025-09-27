import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NetworkAlertDialog extends StatefulWidget {
  final bool isOffline;
  final bool isSlowConnection;
  final VoidCallback onRetry;
  final VoidCallback? onContinueOffline;

  const NetworkAlertDialog({
    super.key,
    required this.isOffline,
    required this.isSlowConnection,
    required this.onRetry,
    this.onContinueOffline,
  });

  @override
  State<NetworkAlertDialog> createState() => _NetworkAlertDialogState();
}

class _NetworkAlertDialogState extends State<NetworkAlertDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: _buildAlertContent(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlertContent() {
    final isOffline = widget.isOffline;
    final config = isOffline ? _getOfflineConfig() : _getSlowConfig();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: config.color.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated Icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: config.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    config.icon,
                    size: 40,
                    color: config.color,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Title
          Text(
            config.title,
            style: GoogleFonts.raleway(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Description
          Text(
            config.description,
            style: GoogleFonts.raleway(
              fontSize: 16,
              color: const Color(0xFF718096),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Action Buttons
          _buildActionButtons(config),
        ],
      ),
    );
  }

  Widget _buildActionButtons(_AlertConfig config) {
    return Column(
      children: [
        // Primary Action (Retry)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onRetry();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: config.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.refresh, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Try Again',
                  style: GoogleFonts.raleway(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Secondary Action (Continue Offline) - only for offline
        if (widget.isOffline && widget.onContinueOffline != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onContinueOffline!();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF718096),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.offline_bolt, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Continue Offline',
                    style: GoogleFonts.raleway(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Dismiss button
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Dismiss',
            style: GoogleFonts.raleway(
              fontSize: 14,
              color: const Color(0xFF718096),
            ),
          ),
        ),
      ],
    );
  }

  _AlertConfig _getOfflineConfig() {
    return _AlertConfig(
      icon: Icons.wifi_off_rounded,
      title: 'No Internet Connection',
      description:
          'Please check your connection and try again. Some features may be limited in offline mode.',
      color: const Color(0xFFE53E3E), // Red
    );
  }

  _AlertConfig _getSlowConfig() {
    return _AlertConfig(
      icon: Icons.signal_wifi_0_bar_rounded,
      title: 'Slow Connection Detected',
      description:
          'Your internet seems slow. This might affect your learning experience.',
      color: const Color(0xFFED8936), // Orange
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class _AlertConfig {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _AlertConfig({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
