import 'package:eureka_app/events/genericEvents.dart';
import 'package:eureka_app/utils/appHelperService.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eureka_app/services/audioProvider.dart';

class LifecycleEventHandler extends WidgetsBindingObserver {
  final BuildContext context;
  final bool firstLaunch;

  LifecycleEventHandler({required this.context, required this.firstLaunch});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      logAppMinimize();
    } else if (state == AppLifecycleState.detached) {
      logAppClose();
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
