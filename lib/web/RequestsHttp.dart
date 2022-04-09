import 'package:finadv/utils/Constants.dart';
import 'package:http/http.dart' as http;

class RequestsHttp {
  static const _CONTENT_TYPE_JSON = {'Content-type': 'application/json'};
  static const String _REQUESTS = 'requests';

  static getStuffRequests() {
    return http.Client().get(Uri.parse(Constants.SERVER_ADDRESS + _REQUESTS),
        headers: _CONTENT_TYPE_JSON);
  }

  static deleteStuffRequest(String date) {
    return http.Client().delete(
      Uri.parse(Constants.SERVER_ADDRESS + _REQUESTS + '?date=' + date),
      headers: _CONTENT_TYPE_JSON,
    );
  }

  static saveStuffRequest(String stuff) {
    return http.Client().post(Uri.parse(Constants.SERVER_ADDRESS + _REQUESTS),
        headers: _CONTENT_TYPE_JSON, body: stuff);
  }
}
