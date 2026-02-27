import 'package:flutter_test/flutter_test.dart';

import 'package:dgrr_app/features/transactions/domain/entities/transaction.dart';

void main() {
  group('TransactionType', () {
    test('fromString parses income and expense', () {
      expect(TransactionType.fromString('income'), TransactionType.income);
      expect(TransactionType.fromString('expense'), TransactionType.expense);
    });

    test('fromString parses legacy types', () {
      expect(TransactionType.fromString('payment'), TransactionType.payment);
      expect(TransactionType.fromString('refund'), TransactionType.refund);
      expect(TransactionType.fromString('fee'), TransactionType.fee);
    });

    test('value returns correct string', () {
      expect(TransactionType.income.value, 'income');
      expect(TransactionType.expense.value, 'expense');
    });
  });
}
