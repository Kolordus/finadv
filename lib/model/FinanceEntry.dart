
class FinanceEntry {
  final String personName;
  final String date;
  final String name;
  final int amount;

  FinanceEntry(this.personName, this.date, this.name, this.amount);

  String get floatingAmount => (amount / 100).toString();

  Map<String, Object?> toJson() => {
    'personName': personName,
    'name': name,
    'date': date,
    'amount': amount,
  };

  static FinanceEntry fromJson(Map json) => FinanceEntry(
    json['personName'] as String,
    json['date'] as String,
    json['name'] as String,
    json['amount'] as int
   );

  @override
  String toString() {
    return 'FinanceEntry{personName: $personName, date: $date, name: $name, amount: $amount}';
  }
}