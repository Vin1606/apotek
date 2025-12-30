class User {
  int id;
  String name;
  int age;
  String address;
  String email;
  String password;

  User({
    required this.id,
    required this.name,
    required this.age,
    required this.address,
    required this.email,
    required this.password,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      age: json['age'],
      address: json['address'],
      email: json['email'],
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'address': address,
      'email': email,
      'password': password,
    };
  }
}

class UserProfile {
  int id;
  String name;
  int age;
  String address;
  String email;

  UserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.address,
    required this.email,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      age: json['age'],
      address: json['address'],
      email: json['email'],
    );
  }
}
