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
  final String servedAt;

  DrinkTransaction({
    required this.id,
    required this.userName,
    required this.drinkName,
    required this.quantity,
    required this.servingPoint,
    required this.servedAt,
  });

  factory DrinkTransaction.fromJson(Map<String, dynamic> json) {
    return DrinkTransaction(
      id: json['id'],
      userName: json['user_name'],
      drinkName: json['drink_name'],
      quantity: json['quantity'],
      servingPoint: json['serving_point'],
      servedAt: json['served_at'],
    );
  }
}
