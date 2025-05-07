import 'dart:convert';
import 'package:web_socket_channel/io.dart';

class WebSocketService {
  //sweden central
  // final String websocketUrl =
  //     "wss://catch-m7iq5tw8-swedencentral.openai.azure.com/openai/realtime?api-version=2024-10-01-preview&deployment=gpt-4o-mini-realtime-preview&api-key=42Or9XVPOllnKWMkmE60EIFvfwPySSZEAoksDOckYW7bszRPaFcRJQQJ99BBACfhMk5XJ3w3AAAAACOGfq96";

  final String websocketUrlForOpenaiMini =
      "wss://api.openai.com/v1/realtime?model=gpt-4o-mini-realtime-preview-2024-12-17";

  final String websocketUrlForGemini =
      "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent";

  final String websocketUrlForOpenai =
      "wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview";
  final String websocketUrl =
      "wss://ai-whisper2392942797736.openai.azure.com/openai/realtime?api-version=2024-10-01-preview&deployment=gpt-4o-mini-realtime-preview&api-key=2f9f3ba9fac54b2fbe42b457f10e852a";

  // final String websocketUrl =
  //     "wss://ai-whisper2392942797736.openai.azure.com/openai/realtime?api-version=2024-10-01-preview&deployment=gpt-4o-realtime-preview-2&api-key=2f9f3ba9fac54b2fbe42b457f10e852a";

  late IOWebSocketChannel channel;
  Function(dynamic)? onMessageReceived;
  bool useOpenAI = false;
  bool useGemini = false;

  void connect() {
    if (useOpenAI) {
      print("URL for websocket : $websocketUrlForOpenaiMini");
      String openaiKey =
          "sk-proj-DsGnxcYNvrHwGSHmsw9FT3BlbkFJosc9TOPpFiRh16bimbuw";
      channel = IOWebSocketChannel.connect(websocketUrlForOpenaiMini, headers: {
        "Authorization": "Bearer $openaiKey",
        "OpenAI-Beta": "realtime=v1",
      });
    } else if (useGemini) {
      print("URL for websocket : $websocketUrlForGemini");
      String geminiKey = "AIzaSyD50eOpqFEhQWIAuyhj55pYscgoqT0Yrrk";
      // String geminiKey = "AIzaSyDMkADjdD6cu9jMy_vPAH-lFx1xE4HoUPY"; //Dagar's key
      String updatedUrl = "$websocketUrlForGemini?key=$geminiKey";
      channel = IOWebSocketChannel.connect(updatedUrl);
    } else {
      channel = IOWebSocketChannel.connect(websocketUrl);
    }
    channel.stream.listen((message) {
      if (onMessageReceived != null) {
        // print(message);
        onMessageReceived!(message);
      }
    }, onError: (error) {
      print("WebSocket error: $error");
    }, onDone: () {
      String stringToAppend = useGemini
          ? "Gemini"
          : useOpenAI
              ? "openai"
              : "microsoft";
      print("WebSocket connection closed: $stringToAppend ");
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
