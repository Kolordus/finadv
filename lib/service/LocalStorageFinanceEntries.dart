import 'dart:convert';

import 'package:finadv/model/FinanceEntry.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageFinanceEntries {

  static Future<bool> saveEntityLocally(String json) async {
    SharedPreferences db = await SharedPreferences.getInstance();

    await db.setString('Local ' + _currentDateWithoutMS(), json);

    return Future.value(true);
  }

  static String _currentDateWithoutMS() {
    int indexOfLastDot = 19;
    return DateTime.now().toString().substring(0, indexOfLastDot);
  }

  static Future<List<String>> getSavedRecords() async {
    SharedPreferences db = await SharedPreferences.getInstance();

    Set<String> keys = db.getKeys();

    List<String> encodedJsons = [];

    if (keys.isNotEmpty) {
      keys.forEach((key) {
        if (key.contains("Local")) {
          encodedJsons.add(db.getString(key)!);
        }
      });
    }

    return encodedJsons;
  }

  static Future<List<String>> getSavedFinanceEntriesRecordsAndRemove() async {
    SharedPreferences db = await SharedPreferences.getInstance();

    Set<String> keys = db.getKeys();

    List<String> encodedJsons = [];

    if (keys.isNotEmpty) {
      keys.forEach((key) {
        if (key.contains("Local")) {
          encodedJsons.add(db.getString(key)!);
          db.remove(key);
        }
      });
    }

    return encodedJsons;
  }

  static Future<void> removeRecordFromLocal(FinanceEntry entry) async {
    SharedPreferences db = await SharedPreferences.getInstance();

    var keyToDelete = 'Local ' + entry.date.substring(0, 19);

    db.remove(keyToDelete);
  }

  static void showAll() async {
    SharedPreferences db = await SharedPreferences.getInstance();
    for (var value in db.getKeys()) {
      if (value.contains("Local")) print(value);
    }

    print(await db.getStringList('entries Jack'));
    print(await db.getStringList('entries Pau'));

  }

  static Future<String> getTotalForName(String personName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(personName).toString();
  }

  static saveList(givenEntries, personName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> parsedEntries = [];

    givenEntries.forEach((element) {
      parsedEntries.add(jsonEncode(element));
    });

    prefs.setStringList('entries ' + personName, parsedEntries);
  }

  static Future<List<FinanceEntry>> getSavedList(String personName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? parsedEntries = prefs.getStringList('entries ' + personName);
    List<FinanceEntry> resultList = [];

    parsedEntries?.forEach((element) {
      resultList.add(FinanceEntry.fromJsonMap(jsonDecode(element)));
    });

    return resultList;
  }

}
