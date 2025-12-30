class Obat {
  int id;
  String name;
  String description;
  int price;
  int stock;
  String? image;

  Obat({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    this.image,
  });

  factory Obat.fromJson(Map<String, dynamic> json) {
    return Obat(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'],
      stock: json['stock'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'image': image,
    };
  }
}
