/// The four seats at the table. Turn order is anti-clockwise:
/// south -> west -> north -> east -> south ...
///
/// Partners sit across from each other: (south, north) vs (west, east).
enum Seat {
  south,
  west,
  north,
  east;

  /// The seat that plays immediately after this one, going anti-clockwise.
  Seat get next => Seat.values[(index + 1) % 4];

  /// The partner sitting across the table.
  Seat get partner => Seat.values[(index + 2) % 4];

  Team get team => (this == Seat.south || this == Seat.north)
      ? Team.northSouth
      : Team.eastWest;
}

/// The two partnerships.
enum Team {
  northSouth,
  eastWest;

  Team get opponent => this == Team.northSouth ? Team.eastWest : Team.northSouth;
}
