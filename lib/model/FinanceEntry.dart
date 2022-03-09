

import 'dart:convert';
import 'dart:core' as std;

class FinanceEntry {
  final std.String personName;
  final std.String date;
  final std.String operationName;
  final std.int amount;

  FinanceEntry(this.personName, this.date, this.operationName, this.amount);

  std.String get floatingAmount => (amount / 100).toString();

  std.Map<std.String, std.Object?> toJson() => {
    'personName': personName,
    'operationName': operationName,
    'date': date,
    'amount': amount,
  };

  static FinanceEntry fromJsonMap(std.Map json) => FinanceEntry(
    json['personName'] as std.String,
    json['date'] as std.String,
    json['operationName'] as std.String,
    json['amount'] as std.int
   );

  static FinanceEntry fromJsonString (std.String json) {
    std.Map<std.String, std.Object> jsonMap = jsonDecode(json);
    return FinanceEntry.fromJsonMap(jsonMap);
  }

  @std.override
  std.String toString() {
    return 'FinanceEntry{personName: $personName, date: $date, name: $operationName, amount: $amount}';
  }

  @std.override
  std.int get hashCode {
    return std.Object.hash(this.personName, this.floatingAmount, this.date, this.amount, this.operationName);
  }
}