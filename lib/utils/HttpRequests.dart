import 'package:http/http.dart' as http;

getFinanceEntriesFor(String personName) {
  return http.Client().get(
      Uri.parse('http://192.168.0.87:8080/finance/' + personName),
      headers: {
        'Content-Type': 'application/json',
      });
}

clearAllEntries() {
  return http.Client().delete(
      Uri.parse('http://192.168.0.87:8080/finance'),
      headers: {'Content-type': 'application/json'});
}
