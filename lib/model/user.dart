class User {
  int usersId;
  String name;
  int age;
  String address;
  String email;
  String password;
  String role; // 'admin' or 'user'

  User({
    required this.usersId,
    required this.name,
    required this.age,
    required this.address,
    required this.email,
    required this.password,
    this.role = 'user',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      usersId: json['users_id'],
      name: json['name'],
      age: json['age'],
      address: json['address'],
      email: json['email'],
      password: json['password'],
      role: json['role'] ?? 'user',
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
      'role': role,
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isUser => role == 'user';
}

class UserProfile {
  int usersId;
  String name;
  int age;
  String address;
  String email;
  String role;

  UserProfile({
    required this.usersId,
    required this.name,
    required this.age,
    required this.address,
    required this.email,
    this.role = 'user',
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      usersId: json['users_id'],
      name: json['name'],
      age: json['age'],
      address: json['address'],
      email: json['email'],
      role: json['role'] ?? 'user',
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isUser => role == 'user';
}
