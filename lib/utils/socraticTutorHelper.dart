import 'dart:convert';
import 'package:eureka_app/services/webSocketService.dart';

class SocraticTutorHelper {
  late WebSocketService webSocketService;
  Function(String imageUrl)? imageCallback;

  final Map<String, String> images = {
    "img_manure_field_001":
        "https://gluta.s3.ap-south-1.amazonaws.com/audio-podcasts/Class+8/Science/images/Microorganisms%3A+Friend+and+Foe_Microorganisms+and+Where+do+They+Live%3F.webp",
    "img_nutrient_deficiency_002":
        "https://gluta.s3.ap-south-1.amazonaws.com/audio-podcasts/Class+8/Science/images/Microorganisms: Friend and Foe_Friendly Microorganisms.webp",
    "img_rhizobium_nodules_003":
        "https://gluta.s3.ap-south-1.amazonaws.com/audio-podcasts/Class+8/Science/images/Microorganisms: Friend and Foe_Medicinal Use of Microorganisms.webp",
    "img_fertiliser_application_006":
        "https://gluta.s3.ap-south-1.amazonaws.com/audio-podcasts/Class+8/Science/images/Microorganisms: Friend and Foe_Role of Microorganisms in Environment.webp"
  };

  SocraticTutorHelper() {
    // Initialize WebSocket and other components in the constructor
    webSocketService = WebSocketService();
    // webSocketService.onMessageReceived = onMessageReceived;
    webSocketService.connect();
    updateSessionPrompt();
  }

  // WebSocket message handler
  void onMessageReceived(String message) {
    final data = jsonDecode(message);
    print("respones received");
    if (data['type'] == 'response.function_call_arguments.done') {
      final params = jsonDecode(data["arguments"]);
      print(params);
      final String imageId = params["imageId"];
      print(params["imageId"]);
      if (imageCallback != null) {
        String? imageUrl = params["relevanceScore"] > 8 ? images[imageId] : "";
        imageCallback!(imageUrl ?? "");
        imageCallback = null;
      }
    }
  }

  void updateSessionPrompt() {
    final startMessage = {
      "event_id": "image_event_123",
      "type": "session.update",
      "session": {
        "instructions":
            "You are a science teacher expert in teaching student in a socratic fashion. You would be given a list of images for a concept, and the current conversation message from the concept. Your job is to fetch the image required to describe this concept in a better way, then use the tool to fetch the image. There are cases where you think no image is suitable, return an empty image id. ",
        "tools": [
          {
            "type": "function",
            "name": "fetchImage",
            "description":
                "Use this function to fetch a relevant image for the concept you are teaching. For example, if you are teaching about crops and providing examples, you can fetch images of those examples, and add a relavance score to them, like if you fetched image of a generic crop here, it would be less relevant than the actual example image.",
            "parameters": {
              "type": "object",
              "properties": {
                "imageId": {"type": "string"},
                "relevanceScore": {
                  "type": "integer",
                  "description":
                      "Give this score correspoding to how much it is relevant to the given message. This score is given out of 10."
                }
              },
              "required": ["imageId", "relevanceScore"]
            }
          }
        ],
        "tool_choice": "auto"
      }
    };

    webSocketService.sendMessage(startMessage);
  }

  // Start the conversation with the given concept
  void startConversation(String messageForImage) {
    final conversationStartMessage = {
      "type": "conversation.item.create",
      "item": {
        "type": "message",
        "role": "user",
        "content": [
          {
            "type": "input_text",
            "text":
                "Conversation Message: $messageForImage. Images Associated:\nSpreading Manure in Fields\n\nImage ID: img_manure_field_001\nDescription: A farmer spreading manure to enrich the soil with nutrients.\nNutrient Deficient Soil\n\nImage ID: img_nutrient_deficiency_002\nDescription: Soil showing signs of nutrient depletion with unhealthy plants.\nRhizobium Nodules on Roots\n\nImage ID: img_rhizobium_nodules_003\nDescription: Close-up of Rhizobium bacteria nodules on the roots of a leguminous plant.\nLeguminous Plants (Peas and Beans)\n\nImage ID: img_leguminous_plants_004\nDescription: Pea and bean plants growing in a field, showing examples of leguminous crops.\nSymbiotic Relationship Diagram\n\nImage ID: img_symbiosis_diagram_005\nDescription: Diagram showing the symbiotic relationship between Rhizobium bacteria and leguminous plants.\nFertilisers Being Applied\n\nImage ID: img_fertiliser_application_006\nDescription: Fertilisers being applied to soil to replenish nutrients like nitrogen, phosphorus, and potassium.\nHealthy Pulse Crops\n\nImage ID: img_healthy_pulses_007\nDescription: Healthy leguminous crops (beans, peas, gram) ready for harvest."
          }
        ]
      }
    };

    webSocketService.sendMessage(conversationStartMessage);

    final responseRequest = {
      "type": "response.create",
      "response": {
        "modalities": ["text"]
      }
    };
    webSocketService.sendMessage(responseRequest);
  }

  // Example utility method: Fetch image
  void getImage(
      String conversationMessage, Function(String imageUrl) callback) {
    imageCallback = callback;
    startConversation(conversationMessage);
  }

  // Dispose resources
  void dispose() {
    webSocketService.disconnect();
  }
}
