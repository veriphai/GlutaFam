import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class NetworkAlertDialog extends StatefulWidget {
  final bool isOffline;
  final bool isSlowConnection;
  final VoidCallback onRetry;
  final VoidCallback? onContinueOffline;
  final String? speedInfo;

  const NetworkAlertDialog({
    super.key,
    required this.isOffline,
    required this.isSlowConnection,
    required this.onRetry,
    this.onContinueOffline,
    this.speedInfo,
  });

  @override
  State<NetworkAlertDialog> createState() => _NetworkAlertDialogState();
}

class _NetworkAlertDialogState extends State<NetworkAlertDialog>
    with TickerProviderStateMixin {
  late AnimationController _appearanceController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // Main appearance animation
    _appearanceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Pulse animation for the icon
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Glow animation for enhanced visual appeal
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _appearanceController, 
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _appearanceController, 
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _appearanceController, 
        curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animations
    _appearanceController.forward();
    _pulseController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_appearanceController, _pulseController, _glowController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: _buildAlertContent(),
              ),
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
      margin: const EdgeInsets.all(20),
      child: Stack(
        children: [
          // Glow effect
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: config.color.withOpacity(0.3 * _glowAnimation.value),
                      blurRadius: 20 + (10 * _glowAnimation.value),
                      spreadRadius: 2 + (3 * _glowAnimation.value),
                    ),
                  ],
                ),
                child: const SizedBox(),
              );
            },
          ),
          
          // Main content
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
                BoxShadow(
                  color: config.color.withOpacity(0.05),
                  blurRadius: 60,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAnimatedIcon(config),
                const SizedBox(height: 24),
                _buildTitle(config),
                const SizedBox(height: 16),
                _buildDescription(config),
                if (widget.speedInfo != null) ...[
                  const SizedBox(height: 12),
                  _buildSpeedInfo(),
                ],
                const SizedBox(height: 32),
                _buildActionButtons(config),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedIcon(_AlertConfig config) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  config.color.withOpacity(0.1),
                  config.color.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
              border: Border.all(
                color: config.color.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Rotating background element
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _glowController.value * 2 * math.pi,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              Colors.transparent,
                              config.color.withOpacity(0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                // Main icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: config.color.withOpacity(0.1),
                  ),
                  child: Icon(
                    config.icon,
                    size: 32,
                    color: config.color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle(_AlertConfig config) {
    return Text(
      config.title,
      style: GoogleFonts.raleway(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1A202C),
        height: 1.2,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription(_AlertConfig config) {
    return Text(
      config.description,
      style: GoogleFonts.raleway(
        fontSize: 16,
        color: const Color(0xFF718096),
        height: 1.6,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSpeedInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.speed,
            size: 16,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 6),
          Text(
            widget.speedInfo!,
            style: GoogleFonts.raleway(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
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
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              shadowColor: config.color.withOpacity(0.3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, value, child) {
                    return Transform.rotate(
                      angle: value * 2 * math.pi,
                      child: const Icon(Icons.refresh_rounded, size: 22),
                    );
                  },
                ),
                const SizedBox(width: 10),
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onContinueOffline!();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF718096),
                side: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.offline_bolt_outlined, size: 22),
                  const SizedBox(width: 10),
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
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            'Dismiss',
            style: GoogleFonts.raleway(
              fontSize: 15,
              color: const Color(0xFF718096),
              fontWeight: FontWeight.w500,
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
      description: 'Please check your connection and try again. Some features may be limited in offline mode.',
      color: const Color(0xFFE53E3E), // Red
    );
  }

  _AlertConfig _getSlowConfig() {
    return _AlertConfig(
      icon: Icons.signal_wifi_statusbar_1_bar_rounded,
      title: 'Slow Connection Detected',
      description: 'Your internet seems slow. This might affect your learning experience.',
      color: const Color(0xFFED8936), // Orange
    );
  }

  @override
  void dispose() {
    _appearanceController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
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