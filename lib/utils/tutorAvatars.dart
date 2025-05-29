final Map<String, Map<String, String>> tutorAvatars = {
  "storyteller": {
    "name": "Story-teller",
    "imagePath": "lib/assets/avatars/storyteller.png"
  },
  "roleplay": {
    "name": "Roleplay",
    "imagePath": "lib/assets/avatars/roleplay.png"
  },
  "breakdown": {
    "name": "Mr Breakdown",
    "imagePath": "lib/assets/avatars/breakdown.png"
  },
  "deepdiver": {
    "name": "Deep Diver",
    "imagePath": "lib/assets/avatars/deepdiver.png"
  },
  "mcformula": {
    "name": "MC Formula",
    "imagePath": "lib/assets/avatars/mcformula.png"
  },
  "mememaster": {
    "name": "Meme Master",
    "imagePath": "lib/assets/avatars/mememaster.png"
  },
  "socratic": {
    "name": "Socratic Sage",
    "imagePath": "lib/assets/avatars/socratic.png"
  },
  "trickster": {
    "name": "Trickster",
    "imagePath": "lib/assets/avatars/trickster.png"
  },
  "tutoprime": {
    "name": "Tuto Prime",
    "imagePath": "lib/assets/avatars/tutoprime.png"
  },
  "interest-led": {
    "name": "Mr Interest",
    "imagePath": "lib/assets/avatars/interest-led.png"
  }
};

Map<String, String> getTutorAvatar(String avatarKey) {
  if (tutorAvatars.containsKey(avatarKey)) {
    return tutorAvatars[avatarKey]!;
  } else {
    return tutorAvatars['tutoprime']!;
  }
}
