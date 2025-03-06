const Map<String, Map<String, String>> achievements = {
  "cheerleader": {
    "id": "cheerleader",
    "name": "Cheerleader",
    "imagePath": "lib/assets/achievements/cheer-leader.png",
  },
  "early-riser": {
    "id": "early-riser",
    "name": "Early Riser",
    "imagePath": "lib/assets/achievements/early-riser.png",
  },
  "flawless-finisher": {
    "id": "flawless-finisher",
    "name": "Flawless Finisher",
    "imagePath": "lib/assets/achievements/flawless-finisher.png",
  },
  "mistake-mechanic": {
    "id": "mistake-mechanic",
    "name": "Mistake Mechanic",
    "imagePath": "lib/assets/achievements/mistake-mechanic.png",
  },
  "perfect-week": {
    "id": "perfect-week",
    "name": "Perfect Week",
    "imagePath": "lib/assets/achievements/perfect-week.png",
  },
  "quest-explorer": {
    "id": "quest-explorer",
    "name": "Quest Explorer",
    "imagePath": "lib/assets/achievements/quest-explorer.png",
  },
  "sleep-walker": {
    "id": "sleep-walker",
    "name": "Sleep Walker",
    "imagePath": "lib/assets/achievements/sleep-walker.png",
  },
  "social-butterfly": {
    "id": "social-butterfly",
    "name": "Social Butterfly",
    "imagePath": "lib/assets/achievements/social-butterfly.png",
  },
  "speed-racer": {
    "id": "speed-racer",
    "name": "Speed Racer",
    "imagePath": "lib/assets/achievements/speed-racer.png",
  },
  "legend": {
    "id": "legend",
    "name": "Legend",
    "imagePath": "lib/assets/achievements/topic-completion.png",
  },
  "xp-olympian": {
    "id": "xp-olympian",
    "name": "XP Olympian",
    "imagePath": "lib/assets/achievements/xp-olympian.png",
  },
};

Map<String, String>? getAchievement(String id) {
  return achievements[id];
}
