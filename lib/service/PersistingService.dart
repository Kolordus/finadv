import 'dart:convert';

import 'package:android_intent/android_intent.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:finadv/model/FinanceEntry.dart';
import 'package:finadv/utils/HttpRequests.dart';
import 'package:http/http.dart';
import 'package:wifi_info_flutter/wifi_info_flutter.dart';

import 'LocalStorage.dart';

class PersistingService {

  static Future<String> save(FinanceEntry financeEntry) async {
    String encodedJson = jsonEncode(financeEntry.toJson());
    var response;

    var canSend = await PersistingService._canSend();
    if (canSend) {
      response = await _sendToServer(encodedJson);
    } else {
      response = await LocalStorage.saveEntityLocally(encodedJson);
    }

    if (response is Response) {
      return response.statusCode == 201 ? 'success' : _getErrorMessage(response.body);
    }

    return response == true ? 'success' : 'failed';
  }

  static String _getErrorMessage(String body) {
    Map<String, dynamic> responseJson = jsonDecode(body);
    String errorMessage = responseJson.remove('message')!;
    return errorMessage;
  }

  static Future<void> sendLocallySaved() async {
    List<Future<Response>> futures = [];

    var canSend = await _canSend();
    if (canSend) {

      List<String> savedRecords = await LocalStorage.getSavedRecordsAndRemove();

      for (String record in savedRecords)
        futures.add(_sendToServer(record));
    }

    Future.wait(futures);
  }

  static Future<bool> _canSend() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    var wifiName = await WifiInfo().getWifiName();

    // if (connectivityResult == ConnectivityResult.wifi && wifiName == Constants.DESIRED_WIFI) {
    if (connectivityResult == ConnectivityResult.wifi) {
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

  static Future<Response> _sendToServer(String encodedJson) async {
    return await HttpRequests.saveFinanceEntry(encodedJson);
  }

  static Future<Response> deleteEntity(FinanceEntry financeEntry) async {
    return await HttpRequests.deleteFinanceEntry(jsonEncode(financeEntry));
  }

  static Future<Response> editEntity(FinanceEntry entry) async {
    return await HttpRequests.editFinanceEntry(jsonEncode(entry.toJson()));
  }

}
