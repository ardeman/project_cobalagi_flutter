/// What the family has unlocked. Sold as a one-time purchase.
enum Plan {
  free,
  full;

  int get maxProfiles => switch (this) {
    Plan.free => 1,
    Plan.full => 6,
  };
}
