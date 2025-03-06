import 'dart:convert';
import 'package:web_socket_channel/io.dart';

class WebSocketServiceForOpenai {
  //sweden central
  final String websocketUrl =
      "wss://api.openai.com/v1/realtime?model=gpt-4o-mini-realtime-preview-2024-12-17";
  // final String websocketUrl =
  //     "wss://ai-whisper2392942797736.openai.azure.com/openai/realtime?api-version=2024-10-01-preview&deployment=gpt-4o-mini-realtime-preview&api-key=2f9f3ba9fac54b2fbe42b457f10e852a";

  // final String websocketUrl =
  //     "wss://ai-whisper2392942797736.openai.azure.com/openai/realtime?api-version=2024-10-01-preview&deployment=gpt-4o-realtime-preview-2&api-key=2f9f3ba9fac54b2fbe42b457f10e852a";

  late IOWebSocketChannel channel;
  Function(String)? onMessageReceived;

  void connect() {
    String openaiKey =
        "sk-proj-DsGnxcYNvrHwGSHmsw9FT3BlbkFJosc9TOPpFiRh16bimbuw";
    channel = IOWebSocketChannel.connect(websocketUrl, headers: {
      "Authorization": "Bearer $openaiKey",
      "OpenAI-Beta": "realtime=v1",
    });
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
