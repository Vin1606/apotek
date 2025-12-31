class OrderItem {
  int obatId;
  String name;
  int quantity;
  int unitPrice;

  OrderItem({
    required this.obatId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      obatId: json['obat_id'] ?? json['id'] ?? 0,
      name: json['obat'] != null ? (json['obat']['name'] ?? '') : (json['name'] ?? ''),
      quantity: json['quantity'] ?? 0,
      unitPrice: json['unit_price'] ?? json['price'] ?? 0,
    );
  }
}

class Order {
  int id;
  int userId;
  int totalPrice;
  String paymentStatus;
  List<OrderItem> items;

  Order({
    required this.id,
    required this.userId,
    required this.totalPrice,
    required this.paymentStatus,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsList = <OrderItem>[];
    if (json['items'] is List) {
      for (final it in json['items']) {
        if (it is Map<String, dynamic>) {
          itemsList.add(OrderItem.fromJson(it));
        } else if (it is Map) {
          itemsList.add(OrderItem.fromJson(Map<String, dynamic>.from(it)));
        }
      }
    }

    return Order(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      totalPrice: json['total_price'] ?? 0,
      paymentStatus: json['payment_status'] ?? '',
      items: itemsList,
    );
  }
}
