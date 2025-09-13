# AI Tutor Screen Components

This directory contains the refactored AI Tutor screen broken down into manageable components.

## File Structure

```
aiTutor/
├── aiTutorScreenV2.dart          # Main screen integrating all components
├── components/
│   ├── ai_tutor_types.dart       # Type definitions and state management
│   ├── ai_tutor_helpers.dart     # Utility functions and helpers
│   ├── text_highlighter.dart     # Text highlighting logic
│   ├── input_island.dart         # Voice/text input component
│   ├── message_bubbles.dart      # Chat message bubbles
│   ├── feedback_cards.dart       # Gap and feedback cards
│   ├── lesson_start_components.dart # Lesson start screen components
│   └── common_ui_components.dart # Reusable UI components
└── README.md                     # This file
```

## Component Overview

### Core Components

1. **aiTutorScreenV2.dart** - Main screen that orchestrates all components
2. **ai_tutor_types.dart** - Contains `InputMode` enum and `AITutorState` class
3. **ai_tutor_helpers.dart** - Utility functions for time formatting, text processing, etc.

### UI Components

4. **input_island.dart** - Handles the floating input interface (voice/text/recording)
5. **message_bubbles.dart** - Renders assistant and user message bubbles
6. **feedback_cards.dart** - Displays gap identification and feedback cards
7. **lesson_start_components.dart** - All components for the lesson start screen
8. **common_ui_components.dart** - Reusable UI elements and modal sheets
9. **text_highlighter.dart** - Handles text highlighting for keywords, phrases, evidence

## Key Features Preserved

- ✅ All original functionality maintained
- ✅ WebSocket integration for real-time features
- ✅ Audio recording and playback
- ✅ Text highlighting for keywords/phrases/evidence
- ✅ Gap identification and feedback system
- ✅ Lesson start screen with objectives
- ✅ Language and voice selection
- ✅ Progress tracking and checkpoint management

## Usage

Import and use `AITutorScreenV2` instead of the original `AITutorScreen`:

```dart
import 'package:eureka_app/screens/aiTutor/aiTutorScreenV2.dart';

// Use AITutorScreenV2 with the same parameters as the original
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AITutorScreenV2(
      conceptId: conceptId,
      conceptName: conceptName,
      // ... other parameters
    ),
  ),
);
```

## Benefits of This Structure

1. **Maintainability** - Each component has a single responsibility
2. **Reusability** - Components can be reused in other screens
3. **Testability** - Individual components can be tested in isolation
4. **Readability** - Easier to understand and navigate the codebase
5. **Scalability** - New features can be added as separate components

## Component Dependencies

- Most UI components are stateless and depend on passed parameters
- State management is centralized in `AITutorState` class
- Helper functions are pure functions without side effects
- WebSocket and API integrations remain in the main screen file
