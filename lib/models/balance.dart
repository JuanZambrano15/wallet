import 'package:cloud_firestore/cloud_firestore.dart';

class Balance {
  final String id;
  final String userId;
  final double amount;
  final DateTime date;
  final DateTime InitialDate;
  final DateTime finalDate;
  final String period;

  Balance({
    required this.id,
    required this.userId,
    required this.amount,
    required this.date,
    required this.InitialDate,
    required this.finalDate,
    required this.period,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'InitialDate': Timestamp.fromDate(InitialDate),
      'finalDate': Timestamp.fromDate(finalDate),
      'period': period,
    };
  }

  factory Balance.fromMap(Map<String, dynamic> map) {
    return Balance(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      amount: (map['amount'] as num? ?? 0).toDouble(),
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
      InitialDate: map['InitialDate'] is Timestamp
          ? (map['InitialDate'] as Timestamp).toDate()
          : DateTime.now(),
      finalDate: map['finalDate'] is Timestamp
          ? (map['finalDate'] as Timestamp).toDate()
          : DateTime.now(),
      period: map['period'] as String? ?? 'monthly',
    );
  }

  Balance copyWith({
    String? id,
    String? userId,
    double? amount,
    DateTime? date,
    DateTime? InitialDate,
    DateTime? finalDate,
    String? period,
  }) {
    return Balance(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      InitialDate: InitialDate ?? this.InitialDate,
      finalDate: finalDate ?? this.finalDate,
      period: period ?? this.period,
    );
  }
}
