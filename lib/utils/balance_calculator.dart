import 'package:wallet/models/balance.dart'; // Ajusta según tus paths reales
import 'package:wallet/models/expense_model.dart';
import 'package:wallet/models/income_model.dart';

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});
}

class BalanceCalculator {
  
  //Calcula el rango de fechas segun periodo seleccionado partiendo de la fecha actual o de referencia
  static DateRange calculateDateRange(String period, {DateTime? referenceDate}) {
    final reference = referenceDate ?? DateTime.now();
    final year = reference.year;
    final month = reference.month;

    DateTime startDate;
    DateTime endDate;

    switch (period.toLowerCase()) {
      case 'quincenal':
      case 'biweekly':
        if (reference.day <= 15) {
          startDate = DateTime(year, month, 1);
          endDate = DateTime(year, month, 15, 23, 59, 59, 999);
        } else {
          startDate = DateTime(year, month, 16);
          endDate = DateTime(year, month + 1, 0, 23, 59, 59, 999);
        }
        break;

      case 'mensual':
      case 'monthly':
        startDate = DateTime(year, month, 1);
        endDate = DateTime(year, month + 1, 0, 23, 59, 59, 999);
        break;

      case 'semestral':
      case 'semiannually':
        if (month <= 6) {
          startDate = DateTime(year, 1, 1);
          endDate = DateTime(year, 6, 30, 23, 59, 59, 999);
        } else {
          startDate = DateTime(year, 7, 1);
          endDate = DateTime(year, 12, 31, 23, 59, 59, 999);
        }
        break;

      case 'anual':
      case 'annually':
        startDate = DateTime(year, 1, 1);
        endDate = DateTime(year, 12, 31, 23, 59, 59, 999);
        break;

      default:
        startDate = DateTime(year, month, 1);
        endDate = DateTime(year, month + 1, 0, 23, 59, 59, 999);
    }

    return DateRange(start: startDate, end: endDate);
  }

  static Balance process({
    required String balanceId,
    required String userId,
    required String period,
    required DateTime initialDate,
    required DateTime finalDate,
    required List<Income> allIncomes,
    required List<Expense> allExpenses,
  }) {

    final periodIncomes = allIncomes.where((income) {
      return (income.date.isAfter(initialDate) || income.date.isAtSameMomentAs(initialDate)) &&
             (income.date.isBefore(finalDate) || income.date.isAtSameMomentAs(finalDate));
    });

    final periodExpenses = allExpenses.where((expense) {
      return (expense.date.isAfter(initialDate) || expense.date.isAtSameMomentAs(initialDate)) &&
             (expense.date.isBefore(finalDate) || expense.date.isAtSameMomentAs(finalDate));
    });

    final double totalIncomes = periodIncomes.fold(0.0, (sum, item) => sum + item.amount);
    final double totalExpenses = periodExpenses.fold(0.0, (sum, item) => sum + item.amount);

    final double balanceAmount = totalIncomes - totalExpenses;

    return Balance(
      id: balanceId,
      userId: userId,
      amount: balanceAmount,
      date: DateTime.now(),
      InitialDate: initialDate,
      finalDate: finalDate,
      period: period,
    );
  }
}