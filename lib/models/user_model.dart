class User {
  final int id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String gender;
  final int lunchesRemaining;
  final int dinnersRemaining;
  final int drinksRemaining;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.gender,
    required this.lunchesRemaining,
    required this.dinnersRemaining,
    required this.drinksRemaining,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      fullName: json['full_name'],
      gender: json['gender'],
      lunchesRemaining: json['lunches_remaining'],
      dinnersRemaining: json['dinners_remaining'],
      drinksRemaining: json['drinks_remaining'],
    );
  }
}
