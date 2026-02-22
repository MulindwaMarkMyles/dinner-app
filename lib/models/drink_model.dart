class Drink {
  final int id;
  final String name;
  final int availableQuantity;

  Drink({
    required this.id,
    required this.name,
    required this.availableQuantity,
  });

  factory Drink.fromJson(Map<String, dynamic> json) {
    return Drink(
      id: json['id'],
      name: json['name'],
      availableQuantity: json['available_quantity'],
    );
  }
}

class DrinkTransaction {
  final int id;
  final String userName;
  final String drinkName;
  final int quantity;
  final String servingPoint;
  final String status;
  final String servedAt;
  final String? approvedAt;
  final String? scannedByUsername;

  DrinkTransaction({
    required this.id,
    required this.userName,
    required this.drinkName,
    required this.quantity,
    required this.servingPoint,
    required this.status,
    required this.servedAt,
    this.approvedAt,
    this.scannedByUsername,
  });

  factory DrinkTransaction.fromJson(Map<String, dynamic> json) {
    return DrinkTransaction(
      id: json['id'],
      userName: json['user_name'],
      drinkName: json['drink_name'],
      quantity: json['quantity'],
      servingPoint: json['serving_point'],
      status: (json['status'] ?? '').toString(),
      servedAt: json['served_at'],
      approvedAt: json['approved_at']?.toString(),
      scannedByUsername: json['scanned_by_username']?.toString(),
    );
  }
}
