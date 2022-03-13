import 'dart:convert';

import 'package:finadv/model/StuffRequest.dart';
import 'package:http/http.dart' as http;

class HttpRequests {
  static const _CONTENT_TYPE_JSON = {'Content-type': 'application/json'};
  static const String _SERVER_ADDRESS = 'http://10.0.2.2:8080/';
  static const String _FINANCE = 'finance';
  static const String _BALANCE = 'balance';
  static const String _REQUESTS = 'requests';

  // static const String _SERVER_ADDRESS = 'http://192.168.0.17:8080';
  // static const String _SERVER_ADDRESS = 'http://192.168.0.108:8080';

  static final _request = http.Client();

  static getFinanceEntriesFor(String personName) {
    return _request.get(
        Uri.parse(_SERVER_ADDRESS + _FINANCE + '/' + personName.toLowerCase()),
        headers: _CONTENT_TYPE_JSON);
  }

  static clearAllEntries() {
    return _request.delete(Uri.parse(_SERVER_ADDRESS + _FINANCE),
        headers: _CONTENT_TYPE_JSON);
  }

  static deleteFinanceEntry(String encodedJson) {
    return _request.delete(
      Uri.parse(_SERVER_ADDRESS + _FINANCE + '/entry'),
      headers: _CONTENT_TYPE_JSON,
      body: encodedJson,
    );
  }

  static editFinanceEntry(String encodedJson) {
    return _request.put(
      Uri.parse(_SERVER_ADDRESS + _FINANCE),
      headers: _CONTENT_TYPE_JSON,
      body: encodedJson,
    );
  }

  static saveFinanceEntry(String encodedJson) {
    return _request.post(
      Uri.parse(_SERVER_ADDRESS + _FINANCE),
      headers: _CONTENT_TYPE_JSON,
      body: encodedJson,
    );
  }

  static getBalance() {
    return http.Client().get(Uri.parse(_SERVER_ADDRESS + _BALANCE),
        headers: _CONTENT_TYPE_JSON);
  }

  static clearBalance() {
    return http.Client().delete(Uri.parse(_SERVER_ADDRESS + _BALANCE),
        headers: _CONTENT_TYPE_JSON);
  }

  static Future<void> waitForResponseInSeconds({int seconds = 1}) async {
    await Future.delayed(Duration(seconds: seconds));
  }

  static getStuffRequests() {
    return http.Client().get(Uri.parse(_SERVER_ADDRESS + _REQUESTS),
        headers: _CONTENT_TYPE_JSON);
  }

  static deleteStuffRequest(String date) {
    return http.Client().delete(Uri.parse(_SERVER_ADDRESS + _REQUESTS + '?date=' + date),
        headers: _CONTENT_TYPE_JSON,);
  }

  static saveStuffRequest(StuffRequest stuff) {
    return http.Client().post(Uri.parse(_SERVER_ADDRESS + _REQUESTS),
        headers: _CONTENT_TYPE_JSON, body: jsonEncode(stuff.toJson()));
  }
}
