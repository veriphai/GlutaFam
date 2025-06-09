import 'dart:convert';
import 'package:eureka_app/apis/fetchGeminiKeys.dart';
import 'package:web_socket_channel/io.dart';

class WebSocketService {
  //sweden central
  final String websocketUrlForOpenaiMini =
      "wss://api.openai.com/v1/realtime?model=gpt-4o-mini-realtime-preview-2024-12-17";

  final String websocketUrlForGemini =
      "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent";

  final String websocketUrlForOpenai =
      "wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview";

  late IOWebSocketChannel channel;
  Function(dynamic)? onMessageReceived;
  bool useOpenAI = false;
  bool useGemini = false;

  List<String> geminiKeys = [];
  int _currentGeminiKeyIndex = 0;

  String get currentGeminiKey =>
      geminiKeys.isNotEmpty ? geminiKeys[_currentGeminiKeyIndex] : "";

  void rotateGeminiKey() {
    _currentGeminiKeyIndex = (_currentGeminiKeyIndex + 1) % geminiKeys.length;
    print("🔑 Rotated Gemini Key to index $_currentGeminiKeyIndex");
  }

  Function(String reason)? onConnectionError;

  Future<void> initialize() async {
    geminiKeys = await fetchGeminiKeys();
    _currentGeminiKeyIndex = 0; // Always reset to 0 on fresh fetch
    if (geminiKeys.isEmpty) {
      throw Exception("No Gemini keys available!");
    }
    // print("✅ Gemini keys loaded: $geminiKeys");
  }

  void connect() {
    if (useOpenAI) {
      print("URL for websocket : $websocketUrlForOpenaiMini");
      String openaiKey = "";
      channel = IOWebSocketChannel.connect(websocketUrlForOpenaiMini, headers: {
        "Authorization": "Bearer $openaiKey",
        "OpenAI-Beta": "realtime=v1",
      });
    } else if (useGemini) {
      print("URL for websocket : $websocketUrlForGemini");
      String updatedUrl = "$websocketUrlForGemini?key=$currentGeminiKey";
      channel = IOWebSocketChannel.connect(updatedUrl);
    } else {
      channel = IOWebSocketChannel.connect(websocketUrlForOpenaiMini);
    }
    channel.stream.listen((message) {
      if (onMessageReceived != null) {
        // print(message);
        onMessageReceived!(message);
      }
    }, onError: (error) {
      print("WebSocket error: $error");
    }, onDone: () {
      final closeCode = channel.closeCode;
      final closeReason = channel.closeReason;

      print("❌ WebSocket closed — Code: $closeCode, Reason: $closeReason");
      if (useGemini && closeCode == 1011) {
        if (closeReason == "The service is currently unavailable.") {
        } else if (closeReason ==
            "Deadline expired before operation could complete.") {
        } else {
          print(
              "Quota error detected, rotating Gemini key and reconnecting...");
          rotateGeminiKey();
        }
        connect(); // Reconnect websocket

        if (onConnectionError != null) {
          onConnectionError!(
              closeReason == "The service is currently unavailable."
                  ? "Service unavailable"
                  : closeReason ==
                          "Deadline expired before operation could complete."
                      ? "Deadline Expired"
                      : "1011");
        }
        return;
      }
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
