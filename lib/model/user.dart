class User {
  int usersId;
  String name;
  int age;
  String address;
  String email;
  String password;

  User({
    required this.usersId,
    required this.name,
    required this.age,
    required this.address,
    required this.email,
    required this.password,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      usersId: json['users_id'],
      name: json['name'],
      age: json['age'],
      address: json['address'],
      email: json['email'],
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'users_id': usersId,
      'name': name,
      'age': age,
      'address': address,
      'email': email,
      'password': password,
    };
  }
}

class UserProfile {
  int usersId;
  String name;
  int age;
  String address;
  String email;

  UserProfile({
    required this.usersId,
    required this.name,
    required this.age,
    required this.address,
    required this.email,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      usersId: json['users_id'],
      name: json['name'],
      age: json['age'],
      address: json['address'],
      email: json['email'],
    );
  }
}
