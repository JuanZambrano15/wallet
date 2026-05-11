// lib/models/income_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Income {
  final String id;
  final String userId;
  final double amount;
  final DateTime date;
  final String sourceId;
  final String description;

  Income({
    required this.id,
    required this.userId,
    required this.amount,
    required this.date,
    required this.sourceId,
    this.description = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'sourceId': sourceId,
      'description': description,
    };
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      amount: (map['amount'] as num? ?? 0).toDouble(),
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
      sourceId: map['sourceId'] as String? ?? 'generic',
      description: map['description'] as String? ?? '',
    );
  }

  Income copyWith({
    String? id,
    String? userId,
    double? amount,
    DateTime? date,
    String? sourceId,
    String? description,
  }) {
    return Income(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      sourceId: sourceId ?? this.sourceId,
      description: description ?? this.description,
    );
  }
}