import 'dart:async';
import 'dart:convert';

import 'package:finadv/model/FinanceEntry.dart';
import 'package:finadv/service/LocalStorage.dart';
import 'package:finadv/service/PersistingService.dart';
import 'package:finadv/utils/HttpRequests.dart' as req;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FinanceDetailsCard extends StatefulWidget {
  FinanceDetailsCard({Key? key, required this.personName}) : super(key: key);

  final String personName;

  @override
  State createState() => _FinanceDetailsCardState();
}

class _FinanceDetailsCardState extends State<FinanceDetailsCard> {
  final _formKey = GlobalKey<FormState>();
  final higherValorController = TextEditingController();
  final lowerValorController = TextEditingController();
  final nameController = TextEditingController();

  Future<List<FinanceEntry>>? _financeEntries;
  Stopwatch stpwatch = Stopwatch();


  @override
  void initState() {
    super.initState();
    this._financeEntries = fetchData(widget.personName);
  }

  void refreshData() {
    setState(() {
      this._financeEntries = fetchData(widget.personName);
    });
  }

  Future<List<FinanceEntry>> fetchData(String personName) async {
    //
    List<String> savedRecords = await LocalStorage.getSavedRecords();
    print(savedRecords.length);
    // to będzie dawało nam ile jest do wysłania - do zakładki to zrobić 13 listopada

    List<Future> futures = [
      waitForResponse(),
      req.getFinanceEntriesFor(personName)
    ];

    var response = await Future.any(futures);
    if (response is Response) {
      List<FinanceEntry> entryList = [];
      final prefs = await SharedPreferences.getInstance();

      if (response.statusCode == 200) {
        prefs.setString(widget.personName, response.body);

        jsonDecode(response.body).forEach((element) {
          entryList.add(FinanceEntry.fromJson(element));
        });
      }

      return entryList;

    } else {
      throw Error();
    }
  }

  Future<void> waitForResponse() async {
    await Future.delayed(Duration(seconds: 3));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.personName),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            onPressed: () {
              req.clearAllEntries();
              setState(() {});
            },
          )
        ],
      ),
      backgroundColor: setProperColor(widget.personName),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: FutureBuilder(
              future: fetchData(widget.personName),
              builder: (builder, snapshot) {
                if (snapshot.hasError) return Text("no connection - check if correct wifi and localization on!");

                return snapshot.connectionState == ConnectionState.waiting
                    ? Center(child: CircularProgressIndicator())
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          renderLastPaymentsWidget(snapshot.data, context),
                          totalWidget(snapshot.data),
                        ],
                      );
              }),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: createEntry,
        child: const Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget totalWidget(amount) {
    var list = amount as List<FinanceEntry>;

    return Column(
      children: [
        Text("Total: ", style: TextStyle(color: Colors.green)),
        Text(getSumOfAllEntries(list), style: TextStyle(color: Colors.green)),
      ],
    );
  }

  String getSumOfAllEntries(List<FinanceEntry> list) {
    int sum = 0;
    list.forEach((element) {
      sum += element.amount;
    });
    return (sum / 100).toString();
  }

  void createEntry() async {
    Widget okButton = ElevatedButton(
        onPressed: () async {
          if (_formKey.currentState!.validate()) {}

          FinanceEntry financeEntry = FinanceEntry(
              widget.personName,
              DateTime.now().toString(),
              nameController.text,
              getAmountFromDialog());

          String response = await PersistingService.save(financeEntry);

          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(response)));

          Navigator.pop(context);
          setState(() {});
        },
        child: Text('Ok'));

    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('Amount:'),
                content: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(DateTime.now().toString())),
                      TextFormField(
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^[-0-9 ]+$'))
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter some text';
                          }
                          return null;
                        },
                        controller: higherValorController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'zł',
                        ),
                      ),
                      TextFormField(
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^[0-9]+$'))
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter some text';
                          }
                          return null;
                        },
                        controller: lowerValorController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'gr',
                        ),
                      ),

                      TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter some text';
                          }
                          return null;
                        },
                        controller: nameController,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Operation name'),
                      ),
                    ],
                  ),
                ),
                actions: [okButton],
              );
            },
          );
        });
  }

  int getAmountFromDialog() {
    return int.parse(higherValorController.text) * 100 +
    int.parse(lowerValorController.text);
  }

  Widget renderLastPaymentsWidget(_paymentList, context) {
    var actionsAmount = _paymentList?.length ?? 0;
    var deviceWidth = MediaQuery.of(context).size.width;
    List<FinanceEntry> paymentList = _paymentList as List<FinanceEntry>;

    return actionsAmount == 0
        ? Center(child: Text('Nothing to show'))
        : Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                color: Colors.black26),
            width: deviceWidth * 0.95,
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: actionsAmount,
                itemBuilder: (context, index) {
                  var currentElement = paymentList.elementAt(index);
                  return Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                    child: GestureDetector(
                      onLongPress: () async {
                        var name = await showMenu(
                            context: context,
                            position: RelativeRect.fill,
                            items: <PopupMenuEntry>[
                              menuItem('delete'),
                              menuItem('edit')
                            ]);

                        await _performAction(name, currentElement);
                        setState(() {});
                      },
                      child: Card(
                        color: Colors.grey,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: (Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(currentElement.name),
                                  _timeWidget(currentElement),
                                  Text(currentElement.floatingAmount,
                                      style: TextStyle(
                                          fontSize: 15,
                                          color: currentElement.amount >= 0
                                              ? Colors.green
                                              : Colors.redAccent)),
                                ],
                              )
                            ],
                          )),
                        ),
                      ),
                    ),
                  );
                }),
          );
  }

  PopupMenuItem<dynamic> menuItem(String value) {
    IconData icon = value == 'edit' ? Icons.edit : Icons.delete;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: <Widget>[
          Icon(icon),
          Text(value),
        ],
      ),
    );
  }

  Color setProperColor(String cardName) {
    switch (cardName.toLowerCase()) {
      case 'pau':
        return Colors.deepPurple;
      case 'jack':
        return Colors.white10;
      case 'podsumowanie':
        return Colors.blue;
      default:
        return Colors.deepPurple;
    }
  }

  Future<void> _performAction(name, FinanceEntry financeEntry) async {
    if (name == null) return;

    String jsonOfEntry = jsonEncode(financeEntry);

    if (name == 'delete') await PersistingService.deleteEntity(jsonOfEntry);
    if (name == 'edit') await PersistingService.editEntity(jsonOfEntry);
  }

  Widget _timeWidget(currentElement) {
    return Column(
      children: [
        Text(_getYYYYMMDD(currentElement)),
        Text(_getHHMMSS(currentElement)),
      ],
    );
  }

  String _getYYYYMMDD(currentElement) {
    var dateTime = DateTime.parse(currentElement.date);

    var year = dateTime.year.toString();
    var month = dateTime.month.toString();
    var day = dateTime.day.toString();

    return year + '-' + month + '-' + day;
  }

  String _getHHMMSS(currentElement) {
    var dateTime = DateTime.parse(currentElement.date);

    var hour = dateTime.hour.toString();
    var minute = dateTime.minute.toString();

    return hour + ':' + minute;
  }
}
