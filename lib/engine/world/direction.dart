/// Compass facing on the grid. y grows downwards, like screen coordinates.
enum Direction {
  north(0, -1),
  east(1, 0),
  south(0, 1),
  west(-1, 0);

  const Direction(this.dx, this.dy);

  final int dx;
  final int dy;

  Direction get left => values[(index + 3) % 4];

  Direction get right => values[(index + 1) % 4];
}
