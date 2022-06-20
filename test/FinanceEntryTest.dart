import 'package:finadv/model/FinanceEntry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sprawdzamy equalsa', () {

    var financeEntry1 = FinanceEntry('pau', '1', 'dd', 1);
    var financeEntry2 = FinanceEntry('pau', '1', 'dd', 1);

    var financeEntry3 = FinanceEntry('pau', '5', 'dd', 5);
    var financeEntry5 = FinanceEntry('pau', '5', 'dd', 5);

    expect(financeEntry1, equals(financeEntry2));
    expect(financeEntry3, equals(financeEntry5));

    expect(financeEntry1, isNot(financeEntry3));
    expect(financeEntry2, isNot(financeEntry5));
  });


  test('mój pierwszy test <3', () {

    DateTime dateTime = DateTime.now();

    Map map = {
      'personName' : 'pau',
      'date': dateTime.toString(),
      'name': 'operation',
      'amount': 10
    };


    expect(FinanceEntry.fromJsonMap(map),
        equals(preparedFinanceEntry(dateTime)));
  });


}

preparedFinanceEntry(DateTime date) {
  return new FinanceEntry('pau', date.toString(), 'operation', 10);
}