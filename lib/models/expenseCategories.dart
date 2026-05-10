class ExpenseCategory {
  final String id;
  final String userId;  
  final String name;
  final String emoji;
  final String description;
  final bool personalized;

  ExpenseCategory({
    required this.id,
    required this.userId,
    required this.name,
    required this.emoji,
    this.description = '',
    this.personalized = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'name': name,
    'emoji': emoji,
    'description': description,
    'personalized': personalized,
  };

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) => ExpenseCategory(
    id: map['id'] ?? '',
    userId: map['userId'] ?? '',
    name: map['name'] ?? '',
    emoji: map['emoji'] ?? '📦',
    description: map['description'] ?? '',
    personalized: map['personalized'] ?? false,
  );

  ExpenseCategory copyWith({
    String? name, String? emoji, String? description,
  }) => ExpenseCategory(
    id: id, userId: userId,
    name: name ?? this.name,
    emoji: emoji ?? this.emoji,
    description: description ?? this.description,
    personalized: personalized,
  );
}