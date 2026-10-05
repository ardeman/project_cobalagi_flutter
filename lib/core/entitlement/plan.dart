/// What the family has unlocked. The app is free; any donation unlocks [full].
enum Plan {
  free,
  full;

  int get maxProfiles => switch (this) {
    Plan.free => 1,
    Plan.full => 6,
  };
}
