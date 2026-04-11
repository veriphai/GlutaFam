import 'package:flutter/material.dart';
import 'package:eureka_app/screens/vaultScreen.dart';

/// Demo screen showing how to navigate to the VaultScreen
/// This is just for demonstration purposes
class VaultScreenDemo extends StatelessWidget {
  const VaultScreenDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault Screen Demo'),
        backgroundColor: const Color(0xFF131F24),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Demo: Navigate to Vault Screen',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),

            // Method 1: Using Navigator.pushNamed (recommended)
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/vault');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF131F24),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Open Vault (Named Route)'),
            ),

            const SizedBox(height: 16),

            // Method 2: Using Navigator.push with MaterialPageRoute
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VaultScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Open Vault (Direct Navigation)'),
            ),

            const SizedBox(height: 32),

            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'The VaultScreen will load https://superpadhai.com/lesson/vault using flutter_inappwebview',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
