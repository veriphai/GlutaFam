import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:eureka_app/events/genericEvents.dart';
import 'package:eureka_app/utils/appHelperService.dart';
import 'package:provider/provider.dart';
import 'package:eureka_app/services/audioProvider.dart';
import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'navigation_utils.dart'; // Import the navigatorKey

class LifecycleEventHandler extends WidgetsBindingObserver {
  final BuildContext context;
  final bool firstLaunch;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  LifecycleEventHandler({required this.context, required this.firstLaunch}) {
    _listenForConnectivityChanges();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      logAppMinimize();
    } else if (state == AppLifecycleState.detached) {
      logAppClose();
      _connectivitySubscription
          .cancel(); // Cancel the listener when the app is closed
    }
  }

  // Listen for connectivity changes continuously

  void _listenForConnectivityChanges() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((connectivityResults) async {
      bool isConnected = await InternetConnection().hasInternetAccess;
      if (connectivityResults.contains(ConnectivityResult.none) ||
          !isConnected) {
        _showNoInternetModal();
      }
    });
  }

  void _showNoInternetModal() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (navigatorKey.currentContext != null) {
        logNoInternetNodalViewEvent();
        showDialog(
          context: navigatorKey.currentContext!,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(
              "No Internet Connection",
              style: GoogleFonts.raleway(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white, // White text for better contrast
              ),
            ),
            content: Text(
              "Please check your internet connection and try again.",
              style: GoogleFonts.raleway(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.white, // White text for better contrast
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  bool isConnected =
                      await InternetConnection().hasInternetAccess;
                  if (isConnected) {
                    logNoInternetNodalRetryEvent(true);

                    Navigator.of(context)
                        .pop(); // Close the modal if internet is back
                    _reloadCurrentScreen();
                  } else {
                    logNoInternetNodalRetryEvent(false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(255, 217, 0, 1),
                ),
                child: Text(
                  "Retry",
                  style: GoogleFonts.raleway(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // White text for better contrast
                  ),
                ),
              ),
            ],
          ),
        );
      }
    });
  }

  // void _reloadCurrentScreen() {
  //   Navigator.pushReplacement(
  //     context,
  //     MaterialPageRoute(builder: (context) => context.widget as Widget),
  //   );
  // }

  void _reloadCurrentScreen() {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute != null) {
      Navigator.pushReplacementNamed(context, currentRoute);
    } else {
      // Fallback to using the current widget if the route name is not available
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => context.widget as Widget),
      );
    }
  }

  void logAppMinimize() async {
    final audioProvider = context.read<AudioProvider>();
    final audioPlayer = audioProvider.audioPlayer;
    if (firstLaunch || audioPlayer == null) {
      Map<String, String> deviceDetails = await getDeviceDetails();
      String deviceId = deviceDetails['deviceId'] ?? "Unknown";
      String platform = deviceDetails['platform'] ?? "Unknown";
      String userIP = await getUserIP();
      logAppMinimizeEventFirstLaunch(deviceId, platform, userIP);
    } else {
      logAppMinimizeEvent(
        audioProvider.sectionId,
        audioProvider.audioPlayer!.playing,
        audioProvider.audioPlayer!.position.inSeconds,
      );
    }
  }

  void logAppClose() async {
    if (firstLaunch) {
      Map<String, String> deviceDetails = await getDeviceDetails();
      String deviceId = deviceDetails['deviceId'] ?? "Unknown";
      String platform = deviceDetails['platform'] ?? "Unknown";
      String userIP = await getUserIP();
      logAppCloseEventFirstLaunch(deviceId, platform, userIP);
    } else {
      final audioProvider = context.read<AudioProvider>();
      logAppCloseEvent(
        audioProvider.sectionId,
        audioProvider.audioPlayer!.playing,
        audioProvider.audioPlayer!.position.inSeconds,
      );
    }
  }
}
