import 'package:finadv/model/FinanceEntry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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