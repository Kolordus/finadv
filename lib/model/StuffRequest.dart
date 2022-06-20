import 'dart:core';

class StuffRequest {
  final String date;
  final String personName;
  final String operationName;

  StuffRequest(this.date, this.personName, this.operationName);

  static StuffRequest fromJsonMap(Map json) {
    return StuffRequest(
        json['date'] as String,
        json['personName'] as String,
        json['operationName'] as String);
  }

  @override
  String toString() {
    return 'StuffRequest{date: $date, personName: $personName, operationName: $operationName}';
  }

  Map<String, Object?> toJson() => {
    'date': date,
    'personName': personName,
    'operationName': operationName
  };

}
