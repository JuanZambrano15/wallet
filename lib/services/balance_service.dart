import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet/models/balance.dart';
import 'package:wallet/models/expense_model.dart';
import 'package:wallet/models/income_model.dart';
import 'package:wallet/utils/balance_calculator.dart'; 

class BalanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _col => _db.collection('balances');

  Future<String> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    if (userId.isEmpty) throw Exception('Usuario no autenticado');
    return userId;
  }

  Future<Balance> calculateAndSavePeriodBalance(String period) async {
    final userId = await _getCurrentUserId();

    final range = BalanceCalculator.calculateDateRange(period);

    final incomeSnapshot = await _db
        .collection('incomes')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(range.end))
        .get();

    final incomes = incomeSnapshot.docs
        .map((doc) => Income.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    final expenseSnapshot = await _db
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(range.end))
        .get();

    final expenses = expenseSnapshot.docs
        .map((doc) => Expense.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    final ref = _col.doc();

    final balanceCalculado = BalanceCalculator.process(
      balanceId: ref.id,
      userId: userId,
      period: period,
      initialDate: range.start,
      finalDate: range.end,
      allIncomes: incomes,
      allExpenses: expenses,
    );

    await ref.set(balanceCalculado.toMap());

    return balanceCalculado;
  }

  Future<Balance> createBalance({
    required String userId,
    required double amount,
    required DateTime date,
    required DateTime initialDate,
    required DateTime finalDate,
    required String period,
  }) async {
    final ref = _col.doc();
    final balance = Balance(
      id: ref.id,
      userId: userId,
      amount: amount,
      date: date,
      InitialDate: initialDate,
      finalDate: finalDate,
      period: period,
    );

    await ref.set(balance.toMap());
    return balance;
  }

  Future<Balance?> getBalanceByPeriod({
    required String userId,
    required String period,
  }) async {
    final snapshot = await _col
        .where('userId', isEqualTo: userId)
        .where('period', isEqualTo: period)
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return Balance.fromMap(snapshot.docs.first.data() as Map<String, dynamic>);
  }

  Future<void> updateBalanceAmount({
    required String balanceId,
    required double newAmount,
  }) async {
    await _col.doc(balanceId).update({'amount': newAmount});
  }
}