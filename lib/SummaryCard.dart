import 'dart:convert';

import 'package:finadv/utils/Constants.dart';
import 'package:finadv/utils/Styles.dart';
import 'package:finadv/web/FinanceHttp.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'DataToSendScreen.dart';

class SummaryCard extends StatefulWidget {
  final List<String> persons = [Constants.PAU, Constants.JACK];

  SummaryCard();

  @override
  State<StatefulWidget> createState() => _SummaryCardState();


}

class _SummaryCardState extends State<SummaryCard> {
  late Future<Balance> _balance;
  var pauTotal;
  var jacTotal;
  late SharedPreferences prefs;
  bool isInternetOn = false;
  bool demandRecalculate = false;
  Balance offlineBalance = Balance.EMPTY_OBJ;

  @override
  void initState() {
    super.initState();
    this._balance = _getBalanceAndTotals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bilans'),
        backgroundColor: Colors.indigoAccent,
        actions: <Widget>[
          Center(
            child: OutlinedButton(
              style: Styles.buttonStyle(),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DataToSendScreen()));
                // fetchDataToSend(widget.personName);
              },
              child: Text(
                "TO SEND",
                style: TextStyle(fontSize: 10, color: Colors.yellow),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4,0,4,0),
            child: Center(
              child: OutlinedButton(
                style: Styles.buttonStyle(),
                onPressed: () {
                  showChangeIPDialog();
                },
                child: Text(
                  "IP",
                  style: TextStyle(fontSize: 10, color: Colors.yellow),
                ),
              ),
            ),
          ),
          Center(
            child: OutlinedButton(
              style: Styles.buttonStyle(),
              onPressed: () {
                FinanceHttp.clearBalance();
                setState(() {});
              },
              child: Text(
                "ZERO BALANCES",
                style: TextStyle(fontSize: 10, color: Colors.red),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [Colors.white10, Colors.blue]),
              borderRadius: BorderRadius.all(Radius.circular(10))),
          child: FutureBuilder(
              future: _getBalanceAndTotals(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child:
                          Text('Empty', style: TextStyle(color: Colors.white)));
                }

                if (snapshot.connectionState == ConnectionState.done) {
                  return renderStats(snapshot.data);
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                return Text('somethign went wrong');
              }),
        ),
      ),
    );
  }

  Future<Balance> _getBalanceAndTotals() async {
    await Future.delayed(Duration(milliseconds: 150));
    Balance newestBalance = Balance.EMPTY_OBJ;

    prefs = await SharedPreferences.getInstance();
    pauTotal = prefs.getString(Constants.PAU);
    jacTotal = prefs.getString(Constants.JACK);

    try {
      List<Future> futures = [
        FinanceHttp.waitForResponseInSeconds(seconds: 5),
        FinanceHttp.getBalance(),
      ];

      var response = await Future.any(futures);

      if (response.statusCode != null && response.statusCode == 200) {
        var json = jsonDecode(response.body);
        newestBalance = Balance.fromJson(json);
        prefs.setString("balance", response.body);
        isInternetOn = true;
      }
    } catch (e) {
      isInternetOn = false;
      var fromLocalStorage =
          Balance.fromJson(jsonDecode(prefs.getString("balance")!));
      newestBalance =
          fromLocalStorage != null ? fromLocalStorage : Balance.EMPTY_OBJ;
    }

    return newestBalance;
  }

  Widget renderStats(data) {
    var balance = data as Balance;
    return Card(
      color: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'SUMMARY',
                  style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 30,
                      fontWeight: FontWeight.bold),
                ),
                isInternetOn
                    ? Text('')
                    : Text(
                        'No internet - bringing previously saved balance',
                        style: TextStyle(color: Colors.cyanAccent),
                      ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.ac_unit_outlined,
                    color: Colors.yellow,
                    size: 30,
                  ),
                ),
                Text(
                    demandRecalculate
                        ? offlineBalance._whoLeads
                        : balance._whoLeads.toString().toUpperCase(),
                    style: TextStyle(color: Colors.tealAccent, fontSize: 20)),
                SizedBox(width: 15),
                Text(
                    demandRecalculate
                        ? offlineBalance.balance
                        : balance.balance,
                    style: TextStyle(
                        color: Colors.tealAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 30)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Padding _personTotalWidget(String personName, String total) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(personName, style: TextStyle(fontSize: 25, color: Colors.teal)),
          Text(total, style: TextStyle(fontSize: 28, color: Colors.tealAccent)),
        ],
      ),
    );
  }

  void _recalculateBalance() {
    var result = (double.parse(jacTotal) - double.parse(pauTotal));

    int parsedToInt = int.parse(result.abs().toString().replaceAll('.', ''));

    demandRecalculate = true;

    this.offlineBalance =
        Balance(parsedToInt, result > 0 ? Constants.JACK : Constants.PAU, '');
  }

  void showChangeIPDialog() {
    var ipFieldCtrl = TextEditingController();
    Widget okButton = ElevatedButton(
        onPressed: () async {
          setState(() {
            Constants.SERVER_IP = ipFieldCtrl.value.text;
          });
          Navigator.pop(context);
        },
        child: Text('Ok'));

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Change IP'),
            actions: [okButton],
            content: Column(
              children: [
                Text('Current ' + Constants.SERVER_IP),
                TextFormField(
                    controller: ipFieldCtrl,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Operation name'))
              ],
            ),
          );
        });
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
