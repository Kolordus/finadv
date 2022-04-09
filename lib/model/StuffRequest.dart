import 'dart:core' as std;

class StuffRequest {
  final std.String date;
  final std.String personName;
  final std.String operationName;

  StuffRequest(this.date, this.personName, this.operationName);

  static StuffRequest fromJsonMap(std.Map json) {
    return StuffRequest(json['date'] as std.String,
        json['personName'] as std.String, json['operationName'] as std.String);
  }

  @std.override
  std.String toString() {
    return 'StuffRequest{date: $date, personName: $personName, operationName: $operationName}';
  }

  std.Map<std.String, std.Object?> toJson() => {
    'date': date,
    'personName': personName,
    'operationName': operationName
  };

}
