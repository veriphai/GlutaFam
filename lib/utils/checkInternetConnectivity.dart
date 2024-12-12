import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

Future<bool> checkInternetConnection(BuildContext context) async {
  List<ConnectivityResult> connectivityResults =
      await Connectivity().checkConnectivity();

  // If no connection type is detected, show the modal immediately
  if (connectivityResults.isEmpty ||
      connectivityResults.contains(ConnectivityResult.none)) {
    _showNoInternetModal(context);
    return false;
  }

  bool isConnected = await InternetConnection().hasInternetAccess;

  if (!isConnected) {
    _showNoInternetModal(context);
  }

  return isConnected;
}

// Show a modal dialog if no internet connection
void _showNoInternetModal(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent closing the modal by tapping outside
    builder: (context) => AlertDialog(
      title: const Text("No Internet Connection"),
      content:
          const Text("Please check your internet connection and try again."),
      actions: [
        ElevatedButton(
          onPressed: () async {
            bool isConnected = await checkInternetConnection(context);
            if (isConnected) {
              Navigator.of(context)
                  .pop(); // Close the modal if internet is back
              _reloadCurrentScreen(context); // Reload the current screen
            }
          },
          child: const Text("Retry"),
        ),
      ],
    ),
  );
}

// Function to reload the current screen
void _reloadCurrentScreen(BuildContext context) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => context.widget as Widget),
  );
}
