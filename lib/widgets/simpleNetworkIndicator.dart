import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/simpleNetworkProvider.dart';
import '../services/simpleNetworkService.dart';

class SimpleNetworkIndicator extends StatefulWidget {
  final bool showWhenGood;
  final bool showSpeed;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const SimpleNetworkIndicator({
    super.key,
    this.showWhenGood = false,
    this.showSpeed = true,
    this.margin,
    this.padding,
  });

  @override
  State<SimpleNetworkIndicator> createState() => _SimpleNetworkIndicatorState();
}

class _SimpleNetworkIndicatorState extends State<SimpleNetworkIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SimpleNetworkProvider>(
      builder: (context, provider, child) {
        // Hide when connection is good (unless showWhenGood is true)
        if (provider.hasGoodConnection && !widget.showWhenGood) {
          return const SizedBox.shrink();
        }

        final config = _getNetworkConfig(provider);

        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: provider.isOffline ? _pulseAnimation.value : 1.0,
              child: Container(
                margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      config.color.withOpacity(0.1),
                      config.color.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: config.color.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: config.color.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildNetworkIcon(config, provider),
                    const SizedBox(width: 6),
                    _buildNetworkText(config, provider),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNetworkIcon(_NetworkConfig config, SimpleNetworkProvider provider) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background pulse for offline state
        if (provider.isOffline)
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 20 + (4 * _pulseAnimation.value),
                height: 20 + (4 * _pulseAnimation.value),
                decoration: BoxDecoration(
                  color: config.color.withOpacity(0.1 * _pulseAnimation.value),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
        
        Icon(
          config.icon,
          size: 16,
          color: config.color,
        ),
      ],
    );
  }

  Widget _buildNetworkText(_NetworkConfig config, SimpleNetworkProvider provider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          config.label,
          style: GoogleFonts.raleway(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: config.color,
            height: 1,
          ),
        ),
        if (widget.showSpeed && provider.isOnline) ...[
          const SizedBox(height: 1),
          Text(
            '${provider.lastSpeedMbps.toStringAsFixed(1)} Mbps',
            style: GoogleFonts.raleway(
              fontSize: 10,
              color: config.color.withOpacity(0.7),
              height: 1,
            ),
          ),
        ],
      ],
    );
  }

  _NetworkConfig _getNetworkConfig(SimpleNetworkProvider provider) {
    switch (provider.networkQuality) {
      case NetworkQuality.excellent:
        return _NetworkConfig(
          icon: Icons.signal_wifi_4_bar,
          label: 'Excellent',
          color: const Color(0xFF38A169), // Green
        );
      case NetworkQuality.good:
        return _NetworkConfig(
          icon: Icons.signal_wifi_4_bar,
          label: 'Good',
          color: const Color(0xFF48BB78), // Light green
        );
      case NetworkQuality.poor:
        return _NetworkConfig(
          icon: Icons.signal_wifi_1_bar,
          label: 'Slow',
          color: const Color(0xFFED8936), // Orange
        );
      case NetworkQuality.offline:
        return _NetworkConfig(
          icon: Icons.wifi_off,
          label: 'Offline',
          color: const Color(0xFFE53E3E), // Red
        );
    }
  }
}

// Compact version for small spaces (e.g., bottom navigation)
class CompactNetworkIndicator extends StatefulWidget {
  final VoidCallback? onTap;

  const CompactNetworkIndicator({super.key, this.onTap});

  @override
  State<CompactNetworkIndicator> createState() => _CompactNetworkIndicatorState();
}

class _CompactNetworkIndicatorState extends State<CompactNetworkIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _blinkController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SimpleNetworkProvider>(
      builder: (context, provider, child) {
        // Hide when connection is good
        if (provider.hasGoodConnection) {
          return const SizedBox.shrink();
        }

        final config = _getCompactConfig(provider);

        return GestureDetector(
          onTap: widget.onTap ?? () => _showNetworkDetails(context, provider),
          child: AnimatedBuilder(
            animation: _blinkController,
            builder: (context, child) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: config.color.withOpacity(
                    provider.isOffline ? (0.3 + 0.7 * _blinkController.value) : 1.0,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: config.color.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: provider.isOffline ? _blinkController.value * 2 : 0,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  _NetworkConfig _getCompactConfig(SimpleNetworkProvider provider) {
    if (provider.isOffline) {
      return _NetworkConfig(
        icon: Icons.wifi_off,
        label: 'Offline',
        color: const Color(0xFFE53E3E),
      );
    } else {
      return _NetworkConfig(
        icon: Icons.signal_wifi_1_bar,
        label: 'Slow',
        color: const Color(0xFFED8936),
      );
    }
  }

  void _showNetworkDetails(BuildContext context, SimpleNetworkProvider provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              provider.isOffline ? Icons.wifi_off : Icons.signal_wifi_1_bar,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              provider.networkDescription,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        backgroundColor: provider.isOffline
            ? const Color(0xFFE53E3E)
            : const Color(0xFFED8936),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _NetworkConfig {
  final IconData icon;
  final String label;
  final Color color;

  const _NetworkConfig({
    required this.icon,
    required this.label,
    required this.color,
  });
}