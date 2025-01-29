import 'dart:convert';
import 'package:web_socket_channel/io.dart';

class WebSocketService {
  final String websocketUrl =
      "wss://ai-whisper2392942797736.openai.azure.com/openai/realtime?api-version=2024-10-01-preview&deployment=gpt-4o-realtime-preview&api-key=2f9f3ba9fac54b2fbe42b457f10e852a";
  late IOWebSocketChannel channel;
  Function(String)? onMessageReceived;

  void connect() {
    channel = IOWebSocketChannel.connect(websocketUrl);
    channel.stream.listen((message) {
      if (onMessageReceived != null) {
        print(message);
        onMessageReceived!(message);
      }
    }, onError: (error) {
      print("WebSocket error: $error");
    }, onDone: () {
      print("WebSocket connection closed");
    });
  }

  void sendMessage(Map<String, dynamic> message) {
    final jsonMessage = jsonEncode(message);
    print("message sent");
    channel.sink.add(jsonMessage);
  }

  void disconnect() {
    channel.sink.close();
  }
}
