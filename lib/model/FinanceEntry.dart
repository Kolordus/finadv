

import 'dart:convert';
import 'dart:core';

class FinanceEntry {
  final String personName;
  final String date;
  final String operationName;
  final int amount;

  FinanceEntry(this.personName, this.date, this.operationName, this.amount);

  String get floatingAmount => (amount / 100).toString();

  Map<String, Object?> toJson() => {
    'personName': personName,
    'operationName': operationName,
    'date': date,
    'amount': amount,
  };

  static FinanceEntry fromJsonMap(Map json) => FinanceEntry(
    json['personName'] as String,
    json['date'] as String,
    json['operationName'] as String,
    json['amount'] as int
   );

  static FinanceEntry fromJsonString (String json) {
    var jsonMap = jsonDecode(json);

    return FinanceEntry.fromJsonMap(jsonMap);
  }

  @override
  String toString() {
    return 'FinanceEntry{personName: $personName, date: $date, name: $operationName, amount: $amount}';
  }

  @override
  int get hashCode {
    return Object.hash(this.personName, this.floatingAmount, this.date, this.amount, this.operationName);
  }
}