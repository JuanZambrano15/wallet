// lib/models/income_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Income {
  final String? id;
  final double amount;
  final DateTime date;
  final String sourceId;
  final String? description;

  Income({
    this.id,
    required this.amount,
    required this.date,
    required this.sourceId,
    this.description,
  });

  /// Converts the [Income] object to a Map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'sourceId': sourceId,
      'description': description ?? '',
    };
  }

  /// Creates an [Income] object from a Firestore document snapshot.
  factory Income.fromMap(Map<String, dynamic> map, String documentId) {
    return Income(
      id: documentId,
      amount: (map['amount'] as num).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      sourceId: map['sourceId'] as String? ?? 'general',
      description: map['description'] as String?,
    );
  }

  /// Creates a copy of [Income] with updated fields.
  Income copyWith({
    String? id,
    double? amount,
    DateTime? date,
    String? sourceId,
    String? description,
  }) {
    return Income(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      sourceId: sourceId ?? this.sourceId,
      description: description ?? this.description,
    );
  }

  @override
  String toString() {
    return 'Income(id: $id, amount: $amount, date: $date, sourceId: $sourceId, description: $description)';
  }
}

/// Represents an income source (e.g., "Salary", "Freelance", "General").
class IncomeSource {
  final String id;
  final String name;
  final String? iconName;

  const IncomeSource({
    required this.id,
    required this.name,
    this.iconName,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'iconName': iconName ?? '',
    };
  }

  factory IncomeSource.fromMap(Map<String, dynamic> map, String documentId) {
    return IncomeSource(
      id: documentId,
      name: map['name'] as String,
      iconName: map['iconName'] as String?,
    );
  }

  /// Default fallback source when the user has none configured.
  static const IncomeSource general = IncomeSource(
    id: 'general',
    name: 'General',
    iconName: 'wallet',
  );
}