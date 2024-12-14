import 'package:eureka_app/apis/logEventsApi.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SimulationScreen extends StatefulWidget {
  final String simulationUrl;

  const SimulationScreen({Key? key, required this.simulationUrl})
      : super(key: key);

  @override
  _SimulationScreenState createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    logPageOpenEvent(
      screenName: "SimulationScreen",
      eventDetails: {
        "description": "User opened the simulation",
        "simulationUrl": widget.simulationUrl
      },
    );

    _setCurrentScreen();

    // Ensure that WebView is initialized for the platform
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.simulationUrl));
  }

  Future<void> _setCurrentScreen() async {
    await FirebaseAnalytics.instance.logScreenView(
        screenClass: 'SimulationScreen',
        screenName: "Simulation Screen",
        parameters: {"simulationUrl": widget.simulationUrl});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Simulation",
          style: const TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
