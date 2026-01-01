class Order {
  int ordersId;
  int usersId;
  int totalPrice;
  String shippingAddress;
  String notes;
  String paymentMethod;
  String paidAt;
  int confirmationBy;
  String paymentStatus;
  String? imagePayment;

  Order({
    required this.ordersId,
    required this.usersId,
    required this.totalPrice,
    required this.shippingAddress,
    required this.notes,
    required this.paymentMethod,
    required this.paidAt,
    required this.confirmationBy,
    required this.paymentStatus,
    required this.imagePayment,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      ordersId: json['orders_id'],
      usersId: json['users_id'],
      totalPrice: json['total_price'],
      shippingAddress: json['shipping_address'],
      notes: json['notes'],
      paymentMethod: json['payment_method'],
      paidAt: json['paid_at'],
      confirmationBy: json['confirmation_by'],
      paymentStatus: json['payment_status'],
      imagePayment: json['image_payment'],
    );
  }
}
