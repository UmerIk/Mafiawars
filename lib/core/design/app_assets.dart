// Created by Hamza Ali on 2026-11-25.
/// Original Figma assets. Older descriptive filenames in the project were
/// assigned to unrelated artwork; use this catalog instead of those aliases.
abstract final class AppAssets {
  static const background = 'assets/images/bg_skyline.png';
  static const logo = 'assets/images/mafia_wars_logo.png';
  static const characters = 'assets/images/login_characters.png';
  static const avatars =
      'assets/images/d8a4204aef5e559f502d9a55371cf91407c50e23';
  static const joinRoom = 'assets/images/join_room.png';
  static const createRoom = 'assets/images/create_room.png';
  static const party = 'assets/images/in_person_party.png';
  static const privateRoom =
      'assets/images/cd33c0515bb930b903caf42d4052da9beb170409';
  static const inPerson =
      'assets/images/c9c43a001f94212ee7daebf473212798db09260b';
  static const mafia = 'assets/images/3b5c76a4d251af2df4dbc8c52f6781a18859e597';
  static const doctor =
      'assets/images/4294836414bf65d8f88144c92807076a544369dc';
  static const detective =
      'assets/images/a7f18cd0d2a85738fb0e4ccf01a47897c5eaaf0f';
  static const snitch =
      'assets/images/7c46a2a08790f3d3218f43f66dfb31f1b281e8ad';

  static const avatarNames = <String>[
    'Boss',
    'Violet',
    'Professor',
    'Doctor',
    'Friday13',
    'Scout',
    'Nurse',
    'PandaRed',
    'Raccoon',
    'Fox',
    'AgentX',
    'Rayven',
    'Sci-dude',
    'Itsyobro',
    'Scarlet',
    'Owl',
    'Raven',
    'Pilot',
    'Shadow',
    'Cypork',
    'Faceless',
    'Ajax',
    'Femme',
    'Detective',
    'Darkling',
  ];

  static const avatarDisplayOrder = [
    0,
    1,
    2,
    3,
    4,
    9,
    5,
    16,
    6,
    8,
    14,
    10,
    11,
    17,
    13,
    19,
    15,
    21,
    12,
    18,
    24,
    20,
    22,
    7,
    23,
  ];

  static String avatarId(int index) => 'avatar_$index';

  static int? avatarIndex(String value) {
    if (!value.startsWith('avatar_')) return null;
    final index = int.tryParse(value.substring(7));
    return index != null && index >= 0 && index < avatarNames.length
        ? index
        : null;
  }
}
