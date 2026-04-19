class UserModel {
  final String id;
  final String email;
  final String password;
  final String nameUser;

  UserModel({
    required this.id,
    required this.email,
    required this.password,
    this.nameUser = '',
  });
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'nameUser': nameUser,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      nameUser: map['nameUser'] ?? '',
    );
  }
}
