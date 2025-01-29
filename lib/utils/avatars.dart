import 'dart:math';

final Map<String, Map<String, String>> avatars = {
  "avatar-1": {"name": "Alien", "imagePath": "lib/assets/avatars/alien.png"},
  "avatar-2": {"name": "Angel", "imagePath": "lib/assets/avatars/angel.png"},
  "avatar-3": {"name": "Devil", "imagePath": "lib/assets/avatars/devil.png"},
  "avatar-4": {
    "name": "Female-Death",
    "imagePath": "lib/assets/avatars/female-death.png"
  },
  "avatar-5": {
    "name": "Female-Elf",
    "imagePath": "lib/assets/avatars/female-elf.png"
  },
  "avatar-6": {
    "name": "Female-Fairy",
    "imagePath": "lib/assets/avatars/female-fairy.png"
  },
  "avatar-7": {
    "name": "Female-Superhero",
    "imagePath": "lib/assets/avatars/female-superhero.png"
  },
  "avatar-8": {
    "name": "Fighter",
    "imagePath": "lib/assets/avatars/fighter.png"
  },
  "avatar-9": {
    "name": "Flash-Hero",
    "imagePath": "lib/assets/avatars/flash-hero.png"
  },
  "avatar-10": {"name": "Genie", "imagePath": "lib/assets/avatars/genie.png"},
  "avatar-11": {
    "name": "Invisible-Man",
    "imagePath": "lib/assets/avatars/invisible-man.png"
  },
  "avatar-12": {
    "name": "Mermaid",
    "imagePath": "lib/assets/avatars/mermaid.png"
  },
  "avatar-13": {
    "name": "Mother-Nature",
    "imagePath": "lib/assets/avatars/mother-nature.png"
  },
  "avatar-14": {"name": "Ogre", "imagePath": "lib/assets/avatars/ogre.png"},
  "avatar-15": {"name": "Pirate", "imagePath": "lib/assets/avatars/pirate.png"},
  "avatar-16": {
    "name": "Princess",
    "imagePath": "lib/assets/avatars/princess.png"
  },
  "avatar-17": {"name": "Queen", "imagePath": "lib/assets/avatars/queen.png"},
  "avatar-18": {"name": "Robot", "imagePath": "lib/assets/avatars/robot.png"},
  "avatar-19": {
    "name": "Super-Boy",
    "imagePath": "lib/assets/avatars/super-boy.png"
  },
  "avatar-20": {
    "name": "Superhero",
    "imagePath": "lib/assets/avatars/superhero.png"
  },
  "avatar-21": {
    "name": "Superwoman",
    "imagePath": "lib/assets/avatars/superwoman.png"
  },
  "avatar-22": {
    "name": "Tree-man",
    "imagePath": "lib/assets/avatars/tree-man.png"
  },
  "avatar-23": {"name": "Viking", "imagePath": "lib/assets/avatars/viking.png"},
  "avatar-24": {"name": "Witch", "imagePath": "lib/assets/avatars/witch.png"},
  "avatar-25": {"name": "Zombie", "imagePath": "lib/assets/avatars/zombie.png"}
};

Map<String, String> getAvatar(String avatarKey) {
  if (avatars.containsKey(avatarKey)) {
    return avatars[avatarKey]!;
  } else {
    // Return a random avatar
    final randomIndex = Random().nextInt(avatars.length);
    final randomKey = avatars.keys.elementAt(randomIndex);
    return avatars[randomKey]!;
  }
}
