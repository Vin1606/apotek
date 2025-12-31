class Obat {
  int obatsId;
  String name;
  String description;
  int price;
  int stock;
  String? image;

  Obat({
    required this.obatsId,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    this.image,
  });

  factory Obat.fromJson(Map<String, dynamic> json) {
    return Obat(
      obatsId: json['obats_id'],
      name: json['name'],
      description: json['description'],
      price: json['price'],
      stock: json['stock'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'obats_id': obatsId,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'image': image,
    };
  }
}
