/// A child on this device. Only a nickname and avatar are stored; no real names.
class Profile {
  const Profile({
    required this.id,
    required this.nickname,
    required this.avatar,
    required this.createdAt,
  });

  factory Profile.fromMap(int id, Map<String, Object?> map) => Profile(
    id: id,
    nickname: map['nickname']! as String,
    avatar: map['avatar']! as int,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']! as int),
  );

  final int id;
  final String nickname;
  final int avatar;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
    'nickname': nickname,
    'avatar': avatar,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };
}
