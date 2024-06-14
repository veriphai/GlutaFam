import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class SpeechScreen extends StatefulWidget {
  @override
  _SpeechScreenState createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Press the button and start speaking';
  WebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _channel = WebSocketChannel.connect(
        Uri.parse('wss://glutaclass.com:8080/gluta/websocket'));
    print('socket conected');
    print(_channel);
  }

  void _sendText(String text) async {
    text = "Hello, how are you ?";
    print(text);
    var url = Uri.parse('https://glutaclass.com:8080/gluta/fam/sendText');
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "role": "user",
            "parts": [
              {"text": text}
            ]
          }
        ]
      }),
    );
    if (response.statusCode == 200) {
      print("text sent, connecting to socket");
      _connectWebSocket(); // Connect to WebSocket after sending the text
    } else {
      print('Failed to send text: ${response.body}');
    }
  }

  void _connectWebSocket() {
    _channel!.stream.listen((data) {
      // Parse the incoming data
      Map<String, dynamic> response = jsonDecode(data);
      if (response.containsKey('candidates') &&
          response['candidates'].isNotEmpty) {
        var candidates = response['candidates'];
        // Assuming the first candidate and the first part contains the required text
        if (candidates[0]['content'] != null &&
            candidates[0]['content']['parts'] != null &&
            candidates[0]['content']['parts'].isNotEmpty) {
          var text = candidates[0]['content']['parts'][0]['text'];
          setState(() {
            _text = text; // Update the text with response from WebSocket
            print("Received text: $_text");
          });
        }
      }
    }, onError: (error) {
      print("WebSocket error: $error");
    });
  }

  @override
  void dispose() {
    _channel?.sink.close(); // Close the WebSocket connection
    _speech.stop();
    super.dispose();
  }

  Future<bool> getMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      // We didn't ask for permission yet or the permission has been denied before but not permanently.
      Map<Permission, PermissionStatus> statuses = await [
        Permission.microphone,
      ].request();
      return statuses[Permission.microphone]!.isGranted;
    } else if (status.isPermanentlyDenied) {
      // The permission is permanently denied, take them to the app settings.
      openAppSettings();
    }
    return status.isGranted;
  }

  void _listen() async {
    bool hasPermission = await getMicrophonePermission();
    if (hasPermission) {
      if (!_isListening) {
        bool available = await _speech.initialize(
          onStatus: (status) {
            print('onStatus: $status');
            if (status == stt.SpeechToText.doneStatus) {
              _sendText(
                  _text); // Send final text when speech is considered complete
            }
          },
          onError: (val) => print('onError: $val'),
        );
        // bool available = await _speech.initialize(
        //   onStatus: (val) => print('onStatus: $val'),
        //   onError: (val) => print('onError: $val'),
        // );
        if (available) {
          setState(() => _isListening = true);
          _speech.listen(
              onResult: (val) => setState(() {
                    _text = val.recognizedWords;
                  }),
              listenFor: Duration(minutes: 2),
              pauseFor: Duration(seconds: 10),
              listenOptions: stt.SpeechListenOptions(
                listenMode: stt.ListenMode.dictation,
                cancelOnError: false,
                partialResults: true,
                autoPunctuation: true,
              ));
        }
      } else {
        setState(() => _isListening = false);
        _speech.stop();
        _sendText(_text);
      }
    } else {
      print("Microphone permission is denied.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Speech to Text'),
        centerTitle: true,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _listen,
        child: Icon(_isListening ? Icons.mic : Icons.mic_none),
      ),
      body: SingleChildScrollView(
        reverse: true,
        child: Container(
          padding: const EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 150.0),
          child: Text(
            _text,
            style: const TextStyle(
              fontSize: 24.0,
              color: Colors.black,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
