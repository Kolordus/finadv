import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static Future<bool> saveEntityLocally(String json) async {
    SharedPreferences db = await SharedPreferences.getInstance();

    db.setString('Local ' + DateTime.now().toString(), json);

    return Future.value(true);
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

  static Future<List<String>> getSavedRecordsAndRemove() async {
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

  static void showAll() async {
    SharedPreferences db = await SharedPreferences.getInstance();
    for (var value in db.getKeys()) {
      if (value.contains("Local"))
        print(value);
    }
  }
}
