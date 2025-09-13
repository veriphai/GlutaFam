# Checkpoint Feedback API Documentation

This document outlines the API design for the Checkpoint Feedback system that replaces static data with dynamic API-driven data.

## API Endpoints

### 1. Fetch Checkpoint Feedback

**Endpoint:** `GET /gluta/fam/checkpoint-feedback`

**Description:** Retrieves comprehensive feedback data for a specific checkpoint including objectives, learning gaps, shining moments, and performance metrics.

**Query Parameters:**

- `conceptConversations` (required): The concept conversations data
- `checkpointNumber` (required): The checkpoint number (integer)

**Headers:**

- `Authorization: Bearer {token}` (required)
- `Content-Type: application/json`
- `Accept-Encoding: gzip`

**Response Format:**

```json
{
  "subject": "Mathematics",
  "title": "Checkpoint 1 feedback",
  "checkpointTitle": "Spot the relationship",
  "timeSpentSec": 218,
  "turns": {
    "student": 4,
    "assistant": 5,
    "hints": 1
  },
  "summary": "Correct rule surfaced; link to constant k was implicit. Add one more test pair to lock it in.",
  "objectives": [
    {
      "id": "o1",
      "text": "Define direct proportion in plain words.",
      "score": 1.0,
      "evidence": "When x goes up, y goes up in the same ratio.",
      "open": false
    }
  ],
  "gaps": [
    {
      "id": "g1",
      "type": "Incomplete link",
      "title": "Skipped why k stays constant",
      "severity": 62,
      "evidence": "Double x so y doubles",
      "fix": "Show k = y/x stays the same across pairs; try (3,6) and (5,10).",
      "action": "drill",
      "resolved": false
    }
  ],
  "shining": [
    {
      "type": "Reasoning",
      "quote": "If x doubles then y doubles, so it's proportional."
    }
  ],
  "clarity": 68,
  "depth": 72,
  "boardDelta": {
    "added": ["Use k = y/x to test proportion"],
    "removed": []
  },
  "showAllGaps": false
}
```

**Error Responses:**

- `400`: Bad Request - Missing required parameters
- `401`: Unauthorized - Invalid or missing authentication token
- `404`: Not Found - Checkpoint not found
- `500`: Internal Server Error

### 2. Update Learning Gap Status

**Endpoint:** `PUT /gluta/fam/update-learning-gap-status`

**Description:** Updates the resolution status of a learning gap.

**Headers:**

- `Authorization: Bearer {token}` (required)
- `Content-Type: application/json`
- `Accept-Encoding: gzip`

**Request Body:**

```json
{
  "gapId": "g1",
  "resolved": true,
  "chapterId": "chapter_123",
  "episodeId": "episode_456",
  "checkpointId": "checkpoint_789"
}
```

**Response Format:**

```json
{
  "success": true,
  "message": "Learning gap status updated successfully"
}
```

**Error Responses:**

- `400`: Bad Request - Invalid request body
- `401`: Unauthorized - Invalid authentication token
- `404`: Not Found - Gap not found
- `500`: Internal Server Error

## Data Models

### CheckpointReport

- `subject`: String - Subject name (Mathematics, Science, etc.)
- `title`: String - Feedback title
- `checkpointTitle`: String - Specific checkpoint name
- `timeSpentSec`: Integer - Time spent in seconds
- `turns`: TurnsData - Interaction data
- `summary`: String - Overall performance summary
- `objectives`: Array of Objective - Learning objectives
- `gaps`: Array of LearningGap - Identified learning gaps
- `shining`: Array of ShiningMoment - Positive moments
- `clarity`: Double - Clarity score (0-100)
- `depth`: Double - Reasoning depth score (0-100)
- `boardDelta`: BoardDelta (optional) - Board changes
- `showAllGaps`: Boolean - UI state for gap display

### TurnsData

- `student`: Integer - Number of student turns
- `assistant`: Integer - Number of assistant turns
- `hints`: Integer - Number of hints given

### Objective

- `id`: String - Unique identifier
- `text`: String - Objective description
- `score`: Double - Achievement score (0.0-1.0)
- `evidence`: String - Evidence of achievement
- `open`: Boolean - UI state for expansion

### LearningGap

- `id`: String - Unique identifier
- `type`: String - Gap category
- `title`: String - Gap description
- `severity`: Integer - Severity score (0-100)
- `evidence`: String - Student quote demonstrating gap
- `fix`: String - Recommended solution
- `action`: String - Action type (drill, example, etc.)
- `resolved`: Boolean - Resolution status

### ShiningMoment

- `type`: String - Moment category
- `quote`: String - Student quote

### BoardDelta

- `added`: Array of String - Items added to board
- `removed`: Array of String - Items removed from board

## Implementation Details

### Client-side Components

1. **API Service** (`lib/apis/fetchCheckpointFeedback.dart`)

   - Handles HTTP requests to fetch feedback data
   - Includes proper authentication and error handling

2. **Gap Update API** (`lib/apis/updateLearningGapStatus.dart`)

   - Manages learning gap status updates
   - Supports optimistic UI updates with rollback on failure

3. **Service Layer** (`lib/services/checkpointFeedbackService.dart`)

   - Provides high-level interface for feedback operations
   - Handles JSON serialization/deserialization
   - Manages data model transformations

4. **Updated Screen** (`lib/screens/checkpointFeedbackScreen.dart`)
   - Now accepts required parameters for API calls
   - Includes loading states and error handling
   - Supports both API data and fallback sample data
   - Implements optimistic updates for gap resolution

### Usage Example

```dart
// Initialize screen with API parameters
CheckpointFeedbackScreen(
  conceptConversations: "conversation_data_string",
  checkpointNumber: 1,
)

// Service usage
final feedback = await CheckpointFeedbackService.getCheckpointFeedback(
  conceptConversations: "conversation_data_string",
  checkpointNumber: 1,
);

// Note: Gap resolution functionality is temporarily disabled
// showing "Coming soon" message to users
```

## Features

### Loading States

- Displays loading indicator while fetching data
- Graceful error handling with retry functionality
- Fallback to sample data if API fails

### Disabled Features

- Gap resolution functionality is temporarily disabled
- Shows "Coming soon" message with schedule icon
- Prevents users from attempting to resolve gaps

### Error Handling

- Comprehensive try-catch blocks
- User-friendly error messages
- Network timeout handling
- Authentication error management

### Authentication

- Uses existing `AuthTokenService`
- Bearer token authentication
- Automatic token refresh support

## Security Considerations

- All endpoints require authentication
- Input validation on both client and server
- Proper error message sanitization
- Rate limiting should be implemented server-side

## Performance Optimizations

- Response compression with gzip
- Efficient JSON parsing
- Minimal network requests
- Caching strategy for frequently accessed data

## Future Enhancements

1. **Offline Support**: Cache feedback data for offline viewing
2. **Real-time Updates**: WebSocket support for live feedback updates
3. **Analytics**: Track user interactions with feedback
4. **Personalization**: Adaptive feedback based on user preferences
5. **Export**: Allow users to export feedback reports
