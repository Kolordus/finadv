import 'dart:async';
import 'dart:convert';

import 'package:badges/badges.dart';
import 'package:finadv/RequestsPage.dart';
import 'package:finadv/StepperInputScreenForFinance.dart';
import 'package:finadv/model/FinanceEntry.dart';
import 'package:finadv/service/LocalStorageFinanceEntries.dart';
import 'package:finadv/service/PersistingService.dart';
import 'package:finadv/utils/Constants.dart';
import 'package:finadv/utils/Styles.dart';
import 'package:finadv/web/FinanceHttp.dart';
import 'package:finadv/web/RequestsHttp.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model/StuffRequest.dart';

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
  bool foodFilter = false;
  List<FinanceEntry>? _financeEntries;
  bool isInternetOn = false;
  int requestsAmount = 0;

  @override
  void initState() {
    super.initState();
    this.refreshData();
  }

  Future<void> refreshData() async {
    await _getRequestsAmount();

    try {
      var financeEntryList = await fetchDataAndSave(widget.personName);
      this._financeEntries = financeEntryList;
      this.isInternetOn = true;

    } catch (e) {
      this._financeEntries = await LocalStorageFinanceEntries.getSavedList(widget.personName);
      this.isInternetOn = false;
      print('NO CONNECTION');
    }
  }

  Future<void> _getRequestsAmount() async {
    List<StuffRequest> stuffList = [];
    var response = await RequestsHttp.getStuffRequests();
    jsonDecode(response.body).forEach((element) {
      stuffList.add(StuffRequest.fromJsonMap(element));
    });

    setState(() {
      requestsAmount = stuffList.length;
    });

    await Future.delayed(Duration(milliseconds: 50));

  }

  Future<List<FinanceEntry>> fetchDataAndSave(String personName) async {
    await Future.delayed(Duration(milliseconds: 150));
    List<FinanceEntry> entryList = [];

    List<Future> futures = [
      FinanceHttp.waitForResponseInSeconds(seconds: 5),
      FinanceHttp.getFinanceEntriesFor(personName)
    ];

    var response = await Future.any(futures);

    if (response.statusCode != null && response.statusCode == 200) {
      jsonDecode(response.body).forEach((element) {
        entryList.add(FinanceEntry.fromJsonMap(element));
      });

      await _saveFinanceEntriesInLocalStorageForCurrentPerson(entryList, widget.personName);
      await _saveTotalInLocalStorage(entryList);
    }

    return entryList;
  }

  Future<void> _saveFinanceEntriesInLocalStorageForCurrentPerson(List<FinanceEntry> givenEntries, String personName) async {
    return await LocalStorageFinanceEntries.saveList(givenEntries, personName);
  }

  Future<void> _saveTotalInLocalStorage(List<FinanceEntry> entryList) async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setString(widget.personName, getSumOfAllEntries(entryList));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.indigoAccent,
        title: Text(widget.personName),
        actions: actions(context),
      ),
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 1.0),
        child: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.bottomLeft, end: Alignment.topRight,
                    colors:
                    [
                      Colors.blue,
                      Colors.white10
                    ]
                ),
                borderRadius: BorderRadius.all(Radius.circular(10))),
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: FutureBuilder(
                future: fetchDataAndSave(widget.personName),
                builder: (builder, snapshot) {
                  if (snapshot.hasError) {
                    return RefreshIndicator(
                      onRefresh: _refreshScreen,
                      child: Container(
                          height: Constants.getDeviceHeightForList(context),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                  "Could not get data!\nPull down to reload",
                                  style: TextStyle(color: Colors.white)),
                              renderLastPaymentsWidget(_financeEntries, context),
                              totalWidget(_financeEntries),
                            ],
                          )),
                    );
                  }
                  return RefreshIndicator(
                      onRefresh: _refreshScreen,
                      child: _paymentListView(snapshot, context));
                }),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      StepperInputScreenForFinance(
                          widget.personName, DateTime.now()))
          );

          await Future.delayed(Duration(milliseconds: 500));
          setState(() {});
          // fetchDataToSend(widget.personName);
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }

  List<Widget> actions(BuildContext context) {
    return <Widget>[
      IconButton(
          icon: Icon(
            Icons.fastfood_outlined,
            color: foodFilter ? Colors.grey : Colors.white,
          ),
          onPressed: () {
            setState(() {
              foodFilter = !foodFilter;
            });
          }),
      Center(
        child: Badge(
          showBadge: requestsAmount > 0,
          badgeContent: Text(requestsAmount.toString(), style: TextStyle(color: Colors.white)),
          position: BadgePosition.topStart(),
          child: OutlinedButton(
            style: Styles.buttonStyle(),
            onPressed: () async {
                var push = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            RequestsPage.createRequestPage(widget.personName)));

                _getRequestsAmount();
          }, child: Text("REQUESTS", style: TextStyle(fontSize: 10, color: Colors.yellow),),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(4,0,0,0),
        child: Center(
          child: OutlinedButton(
            style: Styles.buttonStyle(),
            onPressed: () {
            setState(() {
              FinanceHttp.clearAllEntries();
            });
          }, child: Text("FLATTEN", style: TextStyle(color: Colors.red, fontSize: 10)),),
        ),
      ),
    ];
  }

  Widget _paymentListView(AsyncSnapshot<Object?> snapshot,
      BuildContext context) {
    if (snapshot.hasError) _noConnectionWidget(context);

    if (snapshot.connectionState == ConnectionState.done) {
      var entryList = snapshot.data as List<FinanceEntry>;

      if (this.foodFilter) {
        entryList = entryList
            .where((element) =>
        element.operationName.contains('food') ||
            element.operationName.contains('FOOD'))
            .toList();
      }

      return Container(
        height: Constants.getDeviceHeightForList(context),
        width: Constants.getDeviceWidthForList(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(child: renderLastPaymentsWidget(entryList, context), flex: 9),
            Divider(color: Colors.cyanAccent),
            Flexible(child: totalWidget(entryList), flex: 1),
          ],
        ),
      );
    } else
      return Center(child: CircularProgressIndicator());
  }

  SingleChildScrollView _noConnectionWidget(BuildContext context) {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: Container(
          width: Constants.getDeviceWidthForList(context),
          height: Constants.getDeviceHeightForList(context),
          child: Column(
            children: [
              Expanded(
                flex: 1,
                child: Text(
                    "no connection - check if correct wifi and localization on!"),
              ),
            ],
          )),
    );
  }

  Widget totalWidget(list) {
    if (list == null) {
      return Column(
        children: [
          Text("Total: ",
              style: TextStyle(
                  color: Colors.lightGreenAccent, fontWeight: FontWeight.bold)),
        ],
      );
    }
    return Column(
      children: [
        Text("Total: ",
            style: TextStyle(
                color: Colors.lightGreenAccent, fontWeight: FontWeight.bold)),
        Text(getSumOfAllEntries(list),
            style: TextStyle(
                color: Colors.lightGreenAccent,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
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

          String response = await PersistingService.saveFinanceEntry(
              financeEntry);

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
                title: Text('New Entity:'),
                content: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _currencyAmountInputFields(),
                        SizedBox(height: 5),
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
                ),
                actions: [okButton],
              );
            },
          );
        });
  }

  Row _currencyAmountInputFields() {
    return Row(
      children: [
        Flexible(
          child: Container(
            child: TextFormField(
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^[-0-9]+$'))
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
          ),
        ),
        SizedBox(width: 5),
        Flexible(
          child: Container(
            child: TextFormField(
              keyboardType: TextInputType.number,
              // inputFormatters: [
              //   FilteringTextInputFormatter.allow(RegExp(r'\d\d'))
              // ],
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
          ),
        ),
      ],
    );
  }

  String getCurrentDate() {
    DateTime now = DateTime.now();
    String minutes = now.minute
        .toString()
        .length == 1
        ? '0${now.minute}'
        : now.minute.toString();
    String date = '${now.year}-${now.month}-${now.day} ${now.hour}:${minutes}';
    return date;
  }

  int getAmountFromDialog() {
    return int.parse(higherValorController.text) * 100 +
        int.parse(lowerValorController.text);
  }

  Future<void> _refreshScreen() {
    PersistingService.sendLocallySaved();

    setState(() {
      this.refreshData();
    });
    return Future.delayed(Duration(seconds: 1));
  }

  Widget renderLastPaymentsWidget(_paymentList, context) {
    var actionsAmount = _paymentList?.length ?? 0;
    var deviceWidth = MediaQuery
        .of(context)
        .size
        .width;

    late List<FinanceEntry> paymentList;
    if (_paymentList != null) {
      paymentList = _paymentList as List<FinanceEntry>;
      paymentList = paymentList.reversed.toList();
    }
    else {
      _paymentList = [];
    }

    return actionsAmount == 0
        ? Center(child: Text('Nothing to show'))
        : Container(
      width: deviceWidth * 0.95,
      child: ListView.builder(
          shrinkWrap: true,
          itemCount: actionsAmount,
          itemBuilder: (context, index) {
            var currentElement = paymentList.elementAt(index);
            return Padding(
              padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 8.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft, end: Alignment.topRight,
                    colors:
                      [Colors.grey,
                      Colors.blueGrey]

                  ),
                    borderRadius: BorderRadius.all(Radius.circular(10))),
                child:  GestureDetector(
                  onLongPress: () async {
                    var name = await showMenu(
                        context: context,
                        position: RelativeRect.fill,

                        items: <PopupMenuEntry>[
                          menuItem(Constants.DELETE),
                          menuItem(Constants.EDIT)
                        ]);

                    if (this.isInternetOn) {
                      await _performSelectedAction(name, currentElement);
                    }
                  },
                  child: Card(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0.0, 4.0, 0.0, 4.0),
                      child: (Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(child: Text(currentElement.operationName, style: TextStyle(color: Colors.tealAccent,fontWeight: FontWeight.bold),)),
                          Expanded(child: _timeWidget(currentElement)),
                          Flexible(flex: 1, child: Text(
                              currentElement.floatingAmount,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: currentElement.amount >= 0
                                      ? Colors.greenAccent
                                      : Colors.redAccent))),
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            );
          }),
    );
  }

  PopupMenuItem<dynamic> menuItem(String value) {
    IconData icon = value == Constants.EDIT ? Icons.edit : Icons.delete;
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
    switch (cardName) {
      case Constants.PAU:
        return Colors.deepPurple;
      case Constants.JACK:
        return Colors.white10;
      case Constants.SUM_UP:
        return Colors.blue;
      default:
        return Colors.deepPurple;
    }
  }

  Future<void> _performSelectedAction(name, FinanceEntry financeEntry) async {
    if (name == null) return;
    if (name == Constants.DELETE) {
      await PersistingService.deleteEntity(financeEntry);
      await _refreshScreen();
    }
    if (name == Constants.EDIT) {
      Widget okButton = ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {}

            FinanceEntry updatedEntry = FinanceEntry(widget.personName,
                financeEntry.date, nameController.text, getAmountFromDialog());

            await PersistingService.editEntity(updatedEntry);

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
                  title: Text('Edit Entity:'),
                  content: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _currencyAmountInputFields(),
                        SizedBox(height: 5),
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
  }

  Widget _timeWidget(currentElement) {
    return Column(
      children: [
        Text(_getYYYYMMDD(currentElement),style: TextStyle(color: Colors.cyan)),
        SizedBox(width: 15),
        Text(_getHHMMSS(currentElement),
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan)),
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

    if (minute.length == 1) {
      minute = '0' + minute;
    }

    return hour + ':' + minute;
  }

}
