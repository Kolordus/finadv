import 'dart:async';
import 'dart:convert';
import 'package:finadv/StepperInputScreenForFinance.dart';
import 'package:finadv/model/FinanceEntry.dart';
import 'package:finadv/service/PersistingService.dart';
import 'package:finadv/utils/Constants.dart';
import 'package:finadv/utils/HttpRequests.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finadv/RequestsPage.dart';

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

  List<FinanceEntry>? _financeEntries;
  Stopwatch stpwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    this.refreshData();
  }

  void refreshData() async {
    try {
      var financeEntryList = await fetchDataAndSaveTotal(widget.personName);
      setState(() {
        this._financeEntries = financeEntryList;
      });
    } catch (e) {
      print(e);
      print('jest kurwa~!!');
    }
  }

  Future<List<FinanceEntry>> fetchDataAndSaveTotal(String personName) async {
    await Future.delayed(Duration(milliseconds: 150));
    List<FinanceEntry> entryList = [];

    List<Future> futures = [
      HttpRequests.waitForResponseInSeconds(seconds: 3),
      HttpRequests.getFinanceEntriesFor(personName)
    ];
    var response = await Future.any(futures);

    if (response.statusCode == 200) {
      jsonDecode(response.body).forEach((element) {
        entryList.add(FinanceEntry.fromJsonMap(element));
      });

      await _saveTotalInLocalStorage(entryList);
    }

    return entryList;
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
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.request_page,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => RequestsPage.createRequestPage(widget.personName)));
            },
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            onPressed: () {
              HttpRequests.clearAllEntries();
              setState(() {});
            },
          )
        ],
      ),
      backgroundColor: Colors.white60,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: FutureBuilder(
              future: fetchDataAndSaveTotal(widget.personName),
              builder: (builder, snapshot) {
                if (snapshot.hasError)
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: Container(
                            height: Constants.getDeviceHeightForList(context),
                            child: Center(child: Text("Could not get data!")))),
                  );
                return RefreshIndicator(
                    onRefresh: _refresh,
                    child: _paymentListView(snapshot, context));
              }),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        // onPressed: createEntry,
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      StepperInputScreenForFinance(widget.personName, DateTime.now()))
          );
          // fetchDataToSend(widget.personName);
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _paymentListView(AsyncSnapshot<Object?> snapshot, BuildContext context) {
    if (snapshot.hasError) _noConnectionWidget(context);

    if (snapshot.connectionState == ConnectionState.done) {
      return Container(
        height: Constants.getDeviceHeightForList(context),
        width: Constants.getDeviceWidthForList(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            renderLastPaymentsWidget(snapshot.data, context),
            totalWidget(snapshot.data),
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

  Widget totalWidget(amount) {
    return Column(
      children: [
        Text("Total: ",
            style: TextStyle(
                color: Colors.lightGreenAccent, fontWeight: FontWeight.bold)),
        Text(getSumOfAllEntries(amount),
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
    String minutes = now.minute.toString().length == 1
        ? '0${now.minute}'
        : now.minute.toString();
    String date = '${now.year}-${now.month}-${now.day} ${now.hour}:${minutes}';
    return date;
  }

  int getAmountFromDialog() {
    return int.parse(higherValorController.text) * 100 +
        int.parse(lowerValorController.text);
  }

  Future<void> _refresh() {
    PersistingService.sendLocallySaved();
    this.refreshData();
    return Future.delayed(Duration(seconds: 1));
  }

  Widget renderLastPaymentsWidget(_paymentList, context) {
    var actionsAmount = _paymentList?.length ?? 0;
    var deviceWidth = MediaQuery.of(context).size.width;

    late List<FinanceEntry> paymentList = _paymentList as List<FinanceEntry>;

    return actionsAmount == 0
        ? Center(child: Text('Nothing to show'))
        : Container(
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
                              menuItem(Constants.DELETE),
                              menuItem(Constants.EDIT)
                            ]);

                        await _performSelectedAction(name, currentElement);
                        setState(() {});
                      },
                      child: Card(
                        color: Colors.white70,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: (Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(currentElement.operationName),
                                  _timeWidget(currentElement),
                                  Text(currentElement.floatingAmount,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
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
    if (name == Constants.DELETE)
      await PersistingService.deleteEntity(financeEntry);
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

// Future<List<FinanceEntry>> fetchLocalData(String personName) async {
//   List<FinanceEntry> list =
//       await LocalStorage.getLocallyEntitiesFromServer(personName);
//   if (list.isEmpty)
//     throw Error();
//   else
//     return list;
// }
}
