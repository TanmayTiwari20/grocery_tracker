class GroceryItem {
  final int? id;
  final String name;
  final String quantity;
  final DateTime addedOn;
  final DateTime expiryDate;

  GroceryItem({
    this.id,
    required this.name,
    required this.quantity,
    required this.addedOn,
    required this.expiryDate,
  });

  GroceryItem copyWith({
    int? id,
    String? name,
    String? quantity,
    DateTime? expiryDate,
    DateTime? addedOn,
  }) {
    return GroceryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      expiryDate: expiryDate ?? this.expiryDate,
      addedOn: addedOn ?? this.addedOn,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'added_on': addedOn.toIso8601String(),
      'expiry_date': expiryDate.toIso8601String(),
    };
  }

  factory GroceryItem.fromMap(Map<String, dynamic> map) {
    return GroceryItem(
      id: map['id'],
      name: map['name'],
      quantity: map['quantity'],
      expiryDate: DateTime.parse(map['expiry_date']),
      addedOn: DateTime.parse(map['added_on']),
    );
  }
}
