# Task: Implement Auto-Scrolling for AI Tutor Conversation Messages

## Overview

You need to add auto-scrolling functionality to the AI Tutor screen (`aiTutorScreenV2.dart`) so that whenever a new conversation message is added or updated, the ListView automatically scrolls down to show the latest message. This should **ONLY** apply to conversation items, **NOT** to wsEvents (gap cards, feedback cards, etc.).

## Current Code Structure Analysis

### Key Components to Understand:

1. **Conversation State Management**:

   - `_state.conversations` is a List<Map<String, dynamic>> that holds all conversation messages
   - Messages have roles: 'user', 'assistant', 'checkpoint_feedback'

2. **ListView Structure** (lines 2110-2238):

   ```dart
   ListView.builder(
     padding: const EdgeInsets.fromLTRB(12, 8, 12, 140),
     itemCount: _state.conversations.length + _state.wsEvents.length,
     itemBuilder: (context, index) {
       if (index < _state.conversations.length) {
         // This is a conversation item - AUTO-SCROLL SHOULD TRIGGER HERE
         final convo = _state.conversations[index];
         // ... render conversation bubbles
       } else {
         // This is a wsEvent - DO NOT AUTO-SCROLL FOR THESE
         final event = _state.wsEvents[index - _state.conversations.length];
         // ... render feedback cards, gaps, etc.
       }
     }
   )
   ```

3. **Where Conversations Are Modified** (these are your trigger points):
   - `_mergeConversationsPreservingFeedback()` - Main method that updates conversations from backend
   - `_updateTranscription()` - Updates user message with transcribed text
   - `_followUpConversation()` - Adds new user/assistant messages
   - `_onSendText()` - Adds user text messages
   - `_sendRecording()` - Adds user audio messages

## Implementation Steps

### Step 1: Add ScrollController to State

```dart
class _AITutorScreenV2State extends State<AITutorScreenV2> {
  // Add this with other controllers
  late ScrollController _scrollController;

  // ... existing code
}
```

### Step 2: Initialize ScrollController in initState()

```dart
@override
void initState() {
  super.initState();
  // Add this line after existing initializations
  _scrollController = ScrollController();

  // ... existing initState code
}
```

### Step 3: Add ScrollController to ListView

```dart
ListView.builder(
  controller: _scrollController, // Add this line
  padding: const EdgeInsets.fromLTRB(12, 8, 12, 140),
  itemCount: _state.conversations.length + _state.wsEvents.length,
  // ... rest of ListView code
)
```

### Step 4: Create Auto-Scroll Helper Method

```dart
void _scrollToBottom() {
  if (_scrollController.hasClients) {
    // Use a small delay to ensure the new message is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
}
```

### Step 5: Add Auto-Scroll Triggers

You need to call `_scrollToBottom()` in these specific locations:

#### A. In `_mergeConversationsPreservingFeedback()` method:

- Add `_scrollToBottom();` at the END of the method (after line 581)
- This handles backend conversation updates

#### B. In `_followUpConversation()` method:

- Add `_scrollToBottom();` in the setState block where you add new user messages (around line 825)
- Add `_scrollToBottom();` in the setState block where you add loading assistant messages (around line 842)

#### C. In `_onSendText()` method:

- Add `_scrollToBottom();` at the end of the setState block (after line 1096)

#### D. In `_sendRecording()` method:

- Add `_scrollToBottom();` at the end of the setState block (after line 1054)

#### E. In `_updateTranscription()` method:

- Add `_scrollToBottom();` at the end of the setState block (after line 256)

### Step 6: Dispose ScrollController

```dart
@override
void dispose() {
  _scrollController.dispose(); // Add this line
  _recorder?.closeRecorder();
  // ... rest of existing dispose code
}
```

## Important Notes

### DO NOT Auto-Scroll For:

- wsEvents (gap cards, feedback notifications, etc.)
- Any updates to `_state.wsEvents`
- Checkpoint feedback cards that are not part of conversations

### DO Auto-Scroll For:

- New user messages (text or audio)
- New assistant messages (including loading states)
- Updated conversation content from backend
- Transcription updates

### Testing Scenarios:

1. Send a text message - should auto-scroll
2. Send an audio message - should auto-scroll when transcription appears
3. Receive assistant response - should auto-scroll
4. Gap cards appearing - should NOT auto-scroll
5. Checkpoint feedback notifications - should NOT auto-scroll

### Edge Cases to Handle:

- Check `_scrollController.hasClients` before scrolling
- Use `WidgetsBinding.instance.addPostFrameCallback` to ensure UI is rendered
- Don't scroll if user is manually scrolling up to read previous messages

## Files to Modify:

- `lib/screens/aiTutor/aiTutorScreenV2.dart`

## Success Criteria:

- Conversation messages automatically scroll to bottom when added/updated
- wsEvents (gaps, feedback cards) do NOT trigger auto-scroll
- Smooth animation (300ms duration)
- No crashes or performance issues
- ScrollController properly disposed

## Code Quality Requirements:

- Follow existing code style and patterns
- Add proper comments for the new functionality
- Ensure no memory leaks with proper disposal
- Test thoroughly before submitting

## Detailed Implementation Guide

### Location-Specific Instructions:

1. **Line ~70-80**: Add `late ScrollController _scrollController;` with other controller declarations

2. **Line ~88 (initState)**: Add `_scrollController = ScrollController();` after existing initializations

3. **Line 2111 (ListView.builder)**: Add `controller: _scrollController,` parameter

4. **After line 1822 (before dispose)**: Add the `_scrollToBottom()` helper method

5. **Line 1805 (dispose)**: Add `_scrollController.dispose();` as the first line

6. **Specific setState blocks to modify**:
   - Line 256 (end of `_updateTranscription` setState)
   - Line 581 (end of `_mergeConversationsPreservingFeedback`)
   - Line 825 (in `_followUpConversation` user message setState)
   - Line 842 (in `_followUpConversation` assistant message setState)
   - Line 1054 (end of `_sendRecording` setState)
   - Line 1096 (end of `_onSendText` setState)

This implementation will provide a smooth user experience where users always see the latest conversation messages without manual scrolling, while preserving their ability to scroll up to review previous messages when needed.
