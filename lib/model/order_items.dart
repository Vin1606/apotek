class OrderItems {
  int ordersItemsId;
  int ordersId;
  int obatsId;
  int quantity;
  int unitPrice;
  int subtotal;

  OrderItems({
    required this.ordersItemsId,
    required this.ordersId,
    required this.obatsId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory OrderItems.fromJson(Map<String, dynamic> json) {
    return OrderItems(
      ordersItemsId: json['orders_items_id'],
      ordersId: json['orders_id'],
      obatsId: json['obats_id'],
      quantity: json['quantity'],
      unitPrice: json['unit_price'],
      subtotal: json['subtotal'],
    );
  }
}
