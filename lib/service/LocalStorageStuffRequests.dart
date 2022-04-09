import 'dart:convert';

import 'package:finadv/model/FinanceEntry.dart';
import 'package:finadv/model/StuffRequest.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageStuffRequests {

  static Future<bool> saveEntityLocally(String json) async {
    SharedPreferences db = await SharedPreferences.getInstance();

    await db.setString('Stuff ' + _currentDateWithoutMS(), json);

    return Future.value(true);
  }

  static String _currentDateWithoutMS() {
    int indexOfLastDot = 19;
    return DateTime.now().toString().substring(0, indexOfLastDot);
  }

  static Future<List<StuffRequest>> getSavedRecords() async {
    SharedPreferences db = await SharedPreferences.getInstance();

    Set<String> keys = db.getKeys();

    List<StuffRequest> stuffList = [];

    if (keys.isNotEmpty) {
      keys.forEach((key) {
        if (key.contains("Stuff")) {
          stuffList.add(StuffRequest.fromJsonMap(jsonDecode(db.getString(key)!)));
        }
      });
    }

    return stuffList;
  }

  static Future<List<String>> getSavedStuffRequestsRecordsAndRemove() async {
    SharedPreferences db = await SharedPreferences.getInstance();

    Set<String> keys = db.getKeys();

    List<String> encodedJsons = [];

    if (keys.isNotEmpty) {
      keys.forEach((key) {
        if (key.contains("Stuff")) {
          encodedJsons.add(db.getString(key)!);
          db.remove(key);
        }
      });
    }

    return encodedJsons;
  }

  static Future<void> removeRecordFromLocal(StuffRequest entry) async {
    SharedPreferences db = await SharedPreferences.getInstance();

    var keyToDelete = 'Stuff ' + entry.date.substring(0, 19);

    db.remove(keyToDelete);
  }

  static void showAll() async {
    SharedPreferences db = await SharedPreferences.getInstance();
    for (var value in db.getKeys()) {
      if (value.contains("Stuff")) print(value);
    }
    print(await db.getStringList('requests'));
  }

  static Future<void> saveList(List<StuffRequest> stuffList) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> stuffRequestsList = [];

    stuffList.forEach((element) {
      stuffRequestsList.add(element.toString());
    });

    prefs.setStringList('requests', stuffRequestsList);
  }

}
