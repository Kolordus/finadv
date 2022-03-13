import 'dart:convert';

import 'package:finadv/utils/Constants.dart';
import 'package:finadv/utils/HttpRequests.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'DataToSendScreen.dart';

class SummaryCard extends StatefulWidget {
  final List<String>? persons;

  SummaryCard({@required this.persons});

  @override
  State<StatefulWidget> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<SummaryCard> {
  Future<Balance>? _balance;
  var pauTotal;
  var jacTotal;
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();

    this._balance = _getBalanceAndTotals();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _getBalanceAndTotals(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(
                child: Text('Empty', style: TextStyle(color: Colors.white)));

          return snapshot.connectionState == ConnectionState.waiting
              ? Center(child: CircularProgressIndicator())
              : renderStats(snapshot.data);
        });
  }

  Future<Balance> _getBalanceAndTotals() async {
    Balance newestBalance = Balance.EMPTY_OBJ;

    prefs = await SharedPreferences.getInstance();
    pauTotal = prefs.getString(Constants.PAU);
    jacTotal = prefs.getString(Constants.JACK);

    try {
      List<Future> futures = [
        HttpRequests.waitForResponseInSeconds(seconds: 3),
        HttpRequests.getBalance(),
      ];

      var response = await Future.any(futures);


      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        newestBalance = Balance.fromJson(json);
        prefs.setString("balance", response.body);

      }
    } catch (e) {
      var fromLocalStorage = Balance.fromJson(jsonDecode(prefs.getString("balance")!));

      newestBalance = fromLocalStorage != null ? fromLocalStorage : Balance.EMPTY_OBJ;;
    }

    return newestBalance;
  }

  Widget renderStats(data) {
    var balance = data as Balance;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bilans'),
        backgroundColor: Colors.indigoAccent,
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.airplane_ticket_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => DataToSendScreen()));
              // fetchDataToSend(widget.personName);
            },
          ),
          IconButton(
              icon: Icon(Icons.warning_amber_sharp, color: Colors.white),
              onPressed: () {
                HttpRequests.clearBalance();
                setState(() {});
              })
        ],
      ),
      backgroundColor: Colors.white60,
      body: Padding(
        padding: EdgeInsets.only(top: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: Constants.getDeviceWidthForList(context) * 0.9,
              height: Constants.getDeviceHeightForList(context) * 0.5,
              child: Card(
                color: Colors.white70,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            'Podsumowanie',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _personTotalWidget(Constants.JACK, jacTotal),
                              _personTotalWidget(Constants.PAU, pauTotal),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(onPressed: () {},
                            icon: Icon(Icons.ac_unit_outlined, color: Colors.yellow, size: 30,),
                          ),
                          Text(balance._whoLeads.toString().toUpperCase(),
                              style:
                                  TextStyle(color: Colors.black, fontSize: 20)),
                          SizedBox(width: 15),
                          Text(balance.balance,
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Padding _personTotalWidget(String personName, String total) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Text(personName, style: TextStyle(fontSize: 20)),
          ),
          Text(total, style: TextStyle(fontSize: 20)),
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
        json['whoLeads'].toString(), getYYYYMMDD(json['date']));
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

Future<String> _getTotalFromLocalStorageByName(String personName) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(personName).toString();
}
