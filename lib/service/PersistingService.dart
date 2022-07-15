import 'dart:convert';

import 'package:android_intent/android_intent.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:finadv/model/FinanceEntry.dart';
import 'package:finadv/model/StuffRequest.dart';
import 'package:finadv/service/LocalStorageStuffRequests.dart';
import 'package:finadv/web/RequestsHttp.dart';
import 'package:http/http.dart';

import '../web/FinanceHttp.dart';
import 'LocalStorageFinanceEntries.dart';

class PersistingService {
  static Future<String> saveFinanceEntry(FinanceEntry financeEntry) async {
    String encodedJson = jsonEncode(financeEntry.toJson());
    var response;

    var canSend = await PersistingService._canSend();
    if (canSend) {
      response = await _sendFinanceToServer(encodedJson);
    } else {
      response = await LocalStorageFinanceEntries.saveEntityLocally(encodedJson);
    }

    if (response is Response) {
      return response.statusCode == 201
          ? 'success'
          : _getErrorMessage(response.body);
    }

    return response == true ? 'success' : 'failed';
  }

  static Future<String> saveStuffRequest(StuffRequest stuffRequest) async {
    String encodedJson = jsonEncode(stuffRequest.toJson());
    var response;

    var canSend = await PersistingService._canSend();
    if (canSend) {
      response = await _sendStuffToServer(encodedJson);
    } else {
      response = await LocalStorageStuffRequests.saveEntityLocally(encodedJson);
    }

    if (response is Response) {
      return response.statusCode == 201
          ? 'success'
          : _getErrorMessage(response.body);
    }

    return response == true ? 'success' : 'failed';
  }

  static String _getErrorMessage(String body) {
    Map<String, dynamic> responseJson = jsonDecode(body);
    String errorMessage = responseJson.remove('message')!;
    return errorMessage;
  }

  static Future<void> sendLocallySaved() async {
    var canSend = await _canSend();
    List<Future> toSend = [];

    if (canSend) {
      toSend.add(_sendLocalFinanceEntries());
      toSend.add(_sendLocalStuffRequests());

      await Future.wait(toSend);
    }
  }

  static Future<List<Future<Response>>> _sendLocalFinanceEntries() async {
    List<Future<Response>> futures = [];

    List<String> savedRecords = await LocalStorageFinanceEntries.getSavedFinanceEntriesRecordsAndRemove();

    for (String record in savedRecords)
      futures.add(_sendFinanceToServer(record));

    return futures;
  }

  static Future<List<Future<Response>>> _sendLocalStuffRequests() async {
    List<Future<Response>> futures = [];
    List<String> savedRecords = await LocalStorageStuffRequests.getSavedStuffRequestsRecordsAndRemove();

    for (String record in savedRecords)
      futures.add(_sendStuffToServer(record));

    return futures;
  }

  static Future<bool> _canSend() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    // var wifiName = await WifiInfo().getWifiName();

    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      return true;
    }

    return false;
  }

  static void openLocationSetting() async {
    final AndroidIntent intent = new AndroidIntent(
      action: 'android.settings.LOCATION_SOURCE_SETTINGS',
    );
    await intent.launch();
  }

  static Future<Response> _sendFinanceToServer(String encodedJson) async {
    return await FinanceHttp.saveFinanceEntry(encodedJson);
  }

  static Future<Response> _sendStuffToServer(String encodedJson) async {
    return await RequestsHttp.saveStuffRequest(encodedJson);
  }

  static Future<Response> deleteEntity(FinanceEntry financeEntry) async {
    return await FinanceHttp.deleteFinanceEntry(jsonEncode(financeEntry));
  }

  static Future<Response> editEntity(FinanceEntry entry) async {
    return await FinanceHttp.editFinanceEntry(jsonEncode(entry.toJson()));
  }
}
