// import 'dart:async';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:flutter_sound/flutter_sound.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';

// class AudioChatScreen extends StatefulWidget {
//   const AudioChatScreen({Key? key}) : super(key: key);

//   @override
//   _AudioChatScreenState createState() => _AudioChatScreenState();
// }

// class _AudioChatScreenState extends State<AudioChatScreen> {
//   final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
//   final FlutterSoundPlayer _player = FlutterSoundPlayer();
//   WebSocketChannel? _channel;
//   bool _isRecording = false;

//   StreamController<Uint8List>? _audioStreamController;

//   @override
//   void initState() {
//     super.initState();
//     _initializeAudio();
//   }

//   Future<void> _initializeAudio() async {
//     await _recorder.openRecorder();
//     await _player.openPlayer();
//   }

//   Future<void> _startAudioChat() async {
//     // WebSocket connection to GPT-4o API
//     const websocketUrl = "wss://api.openai.com/v1/audio/realtime";
//     const apiKey = "YOUR_API_KEY"; // Replace with your GPT-4o API key

//     _channel = WebSocketChannel.connect(
//       Uri.parse(websocketUrl),
//     );

//     // Send Authorization Header (if required)
//     _channel!.sink.add({
//       "Authorization": "Bearer $apiKey",
//     });

//     // Initialize the StreamController for audio data
//     _audioStreamController = StreamController<Uint8List>();

//     // Start listening to the stream and send data to WebSocket
//     _audioStreamController!.stream.listen((audioData) {
//       if (_channel != null) {
//         _channel!.sink.add(audioData); // Send audio chunks to the WebSocket
//       }
//     });

//     // Start recording
//     await _recorder.openRecorder();
//     await _recorder.startRecorder(
//       toStream: (data) {
//         if (data != null) {
//           // Add the audio data to the stream
//           _audioStreamController!.add(data);
//         }
//       },
//       codec: Codec.pcm16, // Use PCM 16-bit format
//       sampleRate: 16000, // Ensure compatibility with GPT-4o's requirements
//     );

//     // Listen for AI-generated audio responses
//     _channel!.stream.listen((audioData) {
//       _playAudioResponse(audioData);
//     });
//   }

//   void _stopAudioChat() async {
//     if (_recorder.isRecording) {
//       await _recorder.stopRecorder();
//     }

//     // Close WebSocket connection
//     _channel?.sink.close();
//     setState(() {
//       _isRecording = false;
//     });
//   }

//   void _playAudioResponse(Uint8List audioData) async {
//     await _player.startPlayer(
//       fromDataBuffer: audioData,
//       codec: Codec.pcm16,
//     );
//   }

//   @override
//   void dispose() {
//     _recorder.closeRecorder();
//     _player.closePlayer();
//     _channel?.sink.close();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Audio AI Chat"),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             IconButton(
//               icon: Icon(_isRecording ? Icons.mic_off : Icons.mic),
//               color: _isRecording ? Colors.red : Colors.blue,
//               iconSize: 50,
//               onPressed: _isRecording ? _stopAudioChat : _startAudioChat,
//             ),
//             const SizedBox(height: 20),
//             Text(
//               _isRecording ? "Recording..." : "Press to Start",
//               style: const TextStyle(fontSize: 18),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
