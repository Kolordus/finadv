import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SummaryCard extends StatefulWidget {
  final List<String>? persons;

  SummaryCard({@required this.persons});

  @override
  State<StatefulWidget> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<SummaryCard> {
  Future<Balance>? _balance;

  @override
  void initState() {
    super.initState();

    this._balance = getBalance();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getBalance(),
        builder: (context, snapshot) {
          return snapshot.connectionState == ConnectionState.waiting
              ? Center(child: CircularProgressIndicator())
              : renderStats(snapshot.data);
        });
  }

  Future<Balance> getBalance() async {
    var response = await http.Client()
        .get(Uri.parse('http://192.168.0.87:8080/balance'), headers: {
      'Content-Type': 'application/json',
    });

    final prefs = await SharedPreferences.getInstance();

    Balance newestBalance = Balance.EMPTY_OBJ;

    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      newestBalance = Balance.fromJson(json);
      prefs.setString("balance", response.body);
    } else {
      print('A network error occurred');
    }

    return newestBalance;
  }

  Widget renderStats(data) {
    var balance = data as Balance;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Na dzień:',
            style: TextStyle(color: Colors.white),
          ),
          Text(
            balance.date.toString(),
            style: TextStyle(color: Colors.white),
          ),
          Text(
            'PROWADZI',
            style: TextStyle(color: Colors.white),
          ),
          Text(balance._whoLeads.toString(),
              style: TextStyle(color: Colors.white)),
          Text('Kwotą:', style: TextStyle(color: Colors.white)),
          Text(balance.balance,
              style: TextStyle(color: Colors.white)),

          IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
          onPressed: () {
            http.Client().delete(Uri.parse('http://192.168.0.87:8080/balance'),
                headers: {'Content-type': 'application/json'});
            setState(() {});
          }),
        ],
      ),
    );
  }
}

class Balance {
  final int _balance;
  final String _whoLeads;
  final String date;

  Balance(this._balance, this._whoLeads, this.date);

  static Balance fromJson(Map json) {
    return new Balance(int.parse(json['balance'].toString()),
        json['whoLeads'].toString(),
        getYYYYMMDD(json['date'])
    );
  }

  String toJson() {
    Map map = Map<String, Object>();
    map['date'] = this.date;
    map['whoLeads'] = this._whoLeads;
    map['date'] = this.date;

    return jsonEncode(map);
  }

  String get balance => (_balance / 100).toString();

  static final Balance EMPTY_OBJ = new Balance(0, 'none', '');

}

// DRY!~!!!
String getYYYYMMDD(currentElement) {
  var dateTime = DateTime.parse(currentElement);

  var year = dateTime.year.toString();
  var month = dateTime.month.toString();
  var day = dateTime.day.toString();

  return year + '-' + month + '-' + day;
}
