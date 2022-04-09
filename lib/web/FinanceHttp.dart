import 'dart:convert';

import 'package:finadv/model/StuffRequest.dart';
import 'package:finadv/utils/Constants.dart';
import 'package:http/http.dart' as http;

class FinanceHttp {
  static const _CONTENT_TYPE_JSON = {'Content-type': 'application/json'};
  static const String _BALANCE = 'balance';
  static const String _FINANCE = 'finance';

  static getFinanceEntriesFor(String personName) {
    return http.Client().get(
        Uri.parse(Constants.SERVER_ADDRESS + _FINANCE + '/' + personName.toLowerCase()),
        headers: _CONTENT_TYPE_JSON);
  }

  static clearAllEntries() {
    return http.Client().delete(Uri.parse(Constants.SERVER_ADDRESS + _FINANCE),
        headers: _CONTENT_TYPE_JSON);
  }

  static deleteFinanceEntry(String encodedJson) {
    return http.Client().delete(
      Uri.parse(Constants.SERVER_ADDRESS + _FINANCE + '/entry'),
      headers: _CONTENT_TYPE_JSON,
      body: encodedJson,
    );
  }

  static editFinanceEntry(String encodedJson) {
    return http.Client().put(
      Uri.parse(Constants.SERVER_ADDRESS + _FINANCE),
      headers: _CONTENT_TYPE_JSON,
      body: encodedJson,
    );
  }

  static saveFinanceEntry(String encodedJson) {
    return http.Client().post(
      Uri.parse(Constants.SERVER_ADDRESS + _FINANCE),
      headers: _CONTENT_TYPE_JSON,
      body: encodedJson,
    );
  }

  static getBalance() {
    return http.Client().get(Uri.parse(Constants.SERVER_ADDRESS + _BALANCE),
        headers: _CONTENT_TYPE_JSON);
  }

  static clearBalance() {
    return http.Client().delete(Uri.parse(Constants.SERVER_ADDRESS + _BALANCE),
        headers: _CONTENT_TYPE_JSON);
  }

  static Future<void> waitForResponseInSeconds({int seconds = 1}) async {
    await Future.delayed(Duration(seconds: seconds));
  }
}
