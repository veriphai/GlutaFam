import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:taudio/taudio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class MicSmokeTest extends StatefulWidget {
  const MicSmokeTest({super.key});
  @override
  State<MicSmokeTest> createState() => _MicSmokeTestState();
}

class _MicSmokeTestState extends State<MicSmokeTest> {
  final rec = FlutterSoundRecorder();
  String? path;
  bool recing = false;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final p = await Permission.microphone.request();
    if (!p.isGranted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Mic not granted')));
      return;
    }
    await rec.openRecorder();
    rec.setSubscriptionDuration(const Duration(milliseconds: 200));
  }

  Future<void> _start() async {
    final dir = await getTemporaryDirectory();
    path = '${dir.path}/smoke.wav';
    _sub = rec.onProgress?.listen((e) {
      // debug: print(e.duration.inMilliseconds);
    });
    await rec.startRecorder(
      toFile: path!.replaceAll('.wav', '.m4a'),
      codec: Codec.aacMP4, // <— use MediaRecorder pipeline
      bitRate: 64000,
      sampleRate: 44100,
      numChannels: 1,
    );
    setState(() => recing = true);
  }

  Future<void> _stop() async {
    await rec.stopRecorder();
    await _sub?.cancel();
    setState(() => recing = false);
    if (path != null) {
      final f = File(path!);
      debugPrint('SmokeTest size: ${await f.length()} (${f.path})');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    rec.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mic Smoke Test')),
      body: Center(
        child: ElevatedButton(
          onPressed: recing ? _stop : _start,
          child: Text(recing ? 'Stop' : 'Start'),
        ),
      ),
    );
  }
}
