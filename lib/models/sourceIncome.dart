class SourceIncome {
  final String id;
  final String userId;
  final String name;
  final String description;
  final bool personalized;

  SourceIncome({
    required this.id,
    required this.userId,
    required this.name,
    this.description = '',
    this.personalized = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'personalized': personalized,
    };
  }

  factory SourceIncome.fromMap(Map<String, dynamic> map) {
    return SourceIncome(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      personalized: map['personalized'] ?? false,
    );
  }

  SourceIncome copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    bool? personalized,
  }) {
    return SourceIncome(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      personalized: personalized ?? this.personalized,
    );
  }
}
