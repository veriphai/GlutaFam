// Ember — data/models/npc.dart
//
// A lightweight tribe member. The Elder + a few tribe NPCs are seeded; the sim
// nudges mood and the renderer animates them. Pure value object.

import '../../core/enums.dart';
import '../../core/geometry.dart';
import '../../core/ids.dart';

class Npc {
  const Npc({
    required this.id,
    required this.role,
    required this.coord,
    this.state = AnimState.idle,
    this.mood = NpcMood.content,
    this.dialogueId,
    this.assignedNodeId,
    this.name = '',
  });

  final EntityId id;
  final NpcRole role;
  final GridCoord coord;

  /// Current animation state (idle/walk/work/...).
  final AnimState state;
  final NpcMood mood;

  /// Id of the dialogue tree this NPC currently offers, if any.
  final String? dialogueId;

  /// Resource node this NPC is assigned to harvest, if any.
  final EntityId? assignedNodeId;

  /// Display name (Elder has one; tribe may be empty).
  final String name;

  bool get isAssigned => assignedNodeId != null;

  Npc copyWith({
    EntityId? id,
    NpcRole? role,
    GridCoord? coord,
    AnimState? state,
    NpcMood? mood,
    String? dialogueId,
    bool clearDialogue = false,
    EntityId? assignedNodeId,
    bool clearAssignment = false,
    String? name,
  }) {
    return Npc(
      id: id ?? this.id,
      role: role ?? this.role,
      coord: coord ?? this.coord,
      state: state ?? this.state,
      mood: mood ?? this.mood,
      dialogueId: clearDialogue ? null : (dialogueId ?? this.dialogueId),
      assignedNodeId:
          clearAssignment ? null : (assignedNodeId ?? this.assignedNodeId),
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'role': role.name,
        'coord': coord.toJson(),
        'state': state.name,
        'mood': mood.name,
        if (dialogueId != null) 'dialogueId': dialogueId,
        if (assignedNodeId != null) 'assignedNodeId': assignedNodeId,
        'name': name,
      };

  factory Npc.fromJson(Map<String, dynamic> j) => Npc(
        id: j['id'] as String? ?? '',
        role: npcRoleFromName(j['role']),
        coord: GridCoord.fromJson(
            (j['coord'] as Map).cast<String, dynamic>()),
        state: animStateFromName(j['state']),
        mood: npcMoodFromName(j['mood']),
        dialogueId: j['dialogueId'] as String?,
        assignedNodeId: j['assignedNodeId'] as String?,
        name: j['name'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      other is Npc &&
      other.id == id &&
      other.role == role &&
      other.coord == coord &&
      other.state == state &&
      other.mood == mood &&
      other.dialogueId == dialogueId &&
      other.assignedNodeId == assignedNodeId &&
      other.name == name;

  @override
  int get hashCode => Object.hash(
        id,
        role,
        coord,
        state,
        mood,
        dialogueId,
        assignedNodeId,
        name,
      );
}
