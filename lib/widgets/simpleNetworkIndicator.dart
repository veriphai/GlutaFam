import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simpleNetworkProvider.dart';

class SimpleNetworkIndicator extends StatelessWidget {
  const SimpleNetworkIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SimpleNetworkProvider>(
      builder: (context, provider, child) {
        if (provider.isOnline && !provider.isSlowConnection) {
          return const SizedBox.shrink(); // Hide when connection is good
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: provider.isOnline
                ? Colors.orange.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: provider.isOnline
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                provider.isOnline ? Icons.signal_wifi_0_bar : Icons.wifi_off,
                size: 14,
                color: provider.isOnline ? Colors.orange : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                provider.isOnline ? 'Slow' : 'Offline',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: provider.isOnline ? Colors.orange : Colors.red,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
