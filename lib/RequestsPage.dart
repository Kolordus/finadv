import 'dart:convert';
import 'dart:core';

import 'package:finadv/model/StuffRequest.dart';
import 'package:finadv/service/LocalStorageStuffRequests.dart';
import 'package:finadv/service/PersistingService.dart';
import 'package:finadv/utils/Styles.dart';
import 'package:finadv/web/FinanceHttp.dart';
import 'package:finadv/web/RequestsHttp.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'model/FinanceEntry.dart';

class RequestsPage extends StatefulWidget {
  final String personName;

  RequestsPage(this.personName);

  static RequestsPage createRequestPage(String personName) =>
      RequestsPage(personName);

  @override
  State<StatefulWidget> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestsPage> {
  List<StuffRequest> _stuffRequests = [];
  final _formKey = GlobalKey<FormState>();
  final operationNameController = TextEditingController();
  int requestsAmount = 0;

  late Future<List<StuffRequest>> _fetchDataFuture = fetchData();

  @override
  void initState() {
    super.initState();
    this._fetchDataFuture = fetchData();
    this.pullData();
  }

  refreshScreen() {
    setState(() {});
  }

  void pullData() async {
    try {
      var _stuffRequests = await fetchData();
      setState(() {
        this._stuffRequests = _stuffRequests;
      });
    } catch (e) {
      print('ERROR!!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text("Requests"),
        ),
        floatingActionButton: OutlinedButton(
            onPressed: () async {
              this.createEntry();
            },
            style: ElevatedButton.styleFrom(
              shape: CircleBorder(),
            ),
            child: Icon(
              Icons.fiber_new,
              size: 50,
              color: Colors.green,
            )),
        body: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [Colors.blue, Colors.white10]),
                borderRadius: BorderRadius.all(Radius.circular(10))),
            child: FutureBuilder(
                future: this._fetchDataFuture,
                builder: (builder, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return Center(
                        child: CircularProgressIndicator(
                          color: Colors.red,
                        ));
                  if (snapshot.hasError)
                    return Column(
                      // mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          'No internet connection :( reading locally saved',
                          style: TextStyle(fontSize: 20),
                        ),
                        locallySavedStuffRequests(),
                      ],
                    );

                  if (snapshot.connectionState == ConnectionState.done &&
                      _stuffRequests.length == 0)
                    return Center(
                        child: Text(
                          'No requests',
                          style: TextStyle(fontSize: 20),
                        ));

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
                    child: Column(
                      children: [
                        GridView.builder(
                            scrollDirection: Axis.vertical,
                            shrinkWrap: true,
                            gridDelegate:
                            SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 150,
                                crossAxisSpacing: 0,
                                mainAxisSpacing: 5),
                            itemCount: _stuffRequests.length,
                            itemBuilder: (BuildContext ctx, index) {
                              return singleTile(
                                  _stuffRequests.elementAt(index));
                            }),
                      ],
                    ),
                  );
                }),
          ),
        ));
  }

  Widget singleTile(StuffRequest stuff) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4.0, 0.0, 4.0, 0.0),
      child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: Colors.black54, borderRadius: BorderRadius.circular(15)),
          child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Flexible(
                    flex: 1,
                    child: Text(
                      stuff.date.substring(0, 11),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.blue,
                          fontSize: 10,
                          decoration: TextDecoration.none),
                    ),
                  ),
                  Flexible(
                      flex: 1,
                      child: Divider(color: Colors.cyan, thickness: 1)),
                  Flexible(
                    flex: 10,
                    child: Text(
                      stuff.operationName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.blue,
                          fontSize: 15,
                          decoration: TextDecoration.none),
                    ),
                  ),
                  Flexible(
                    flex: 1,
                    child: OutlinedButton(
                        onPressed: () async {
                          deleteRequestDialog(stuff);
                        },
                        style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                        ),
                        child: Icon(
                          Icons.cancel,
                          size: 20,
                          color: Colors.red,
                        )),
                  )
                ],
              ))),
    );
  }

  Future deleteRequestDialog(StuffRequest stuff) {
    return showDialog(
        context: context,
        builder: (context) {
          Widget yesButton = OutlinedButton(
              style: Styles.buttonStyle(color: Colors.green),
              onPressed: () async {
                Navigator.pop(context);
                createExpenseDialog(stuff);
              },
              child: Text('Yes'));

          Widget noButton = OutlinedButton(
              style: Styles.buttonStyle(color: Colors.red),
              onPressed: () async {
                await RequestsHttp.deleteStuffRequest(stuff.date);

                setState(() {
                  pullData();
                });
                Navigator.pop(context);
              },
              child: Text('No'));

          return AlertDialog(
            title: Text("Do You wanna add it as expense?"),
            actions: [yesButton, noButton],
          );
        });
  }

  Future createExpenseDialog(StuffRequest stuff) {
    final amountController = TextEditingController();

    String whoAmI = 'Pau';
    return showDialog(
        context: context,
        builder: (context) {
          Widget okButton = ElevatedButton(
              style: Styles.buttonStyle(
                color: Colors.transparent,
                background: Colors.green,
              ),
              onPressed: () async {
                await RequestsHttp.deleteStuffRequest(stuff.date);

                var financeEntry = FinanceEntry(
                    stuff.personName,
                    DateTime.now().toString(),
                    stuff.operationName,
                    int.parse(amountController.text.replaceAll(".", "")));

                await PersistingService.saveFinanceEntry(financeEntry);

                this.pullData();
                Navigator.pop(context);
              },
              child: Text('Ok'));

          return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: Text("Create expense"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Divider(color: Colors.black, thickness: 2),
                      Text(stuff.operationName, style: TextStyle(fontSize: 20)),
                      DropdownButton(
                          value: whoAmI,
                          items: <String>['Pau', 'Jack']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? selected) {
                            setState(() {
                              whoAmI = selected!;
                            });
                          }),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 10, 0, 4),
                        child: TextField(
                          controller: amountController,
                          decoration: InputDecoration(
                            hintText: "kwota",
                            border: OutlineInputBorder(),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          onChanged: (text) {
                            if (text.length > 2) {
                              var pln = text.substring(0, text.length - 2);
                              var gr = text.substring(text.length - 2);

                              amountController.text = pln + '.' + gr;

                              amountController.selection = TextSelection.fromPosition(
                                  TextPosition(offset: amountController.text.length));
                            }
                          },
                        ),
                      )
                    ],
                  ),
                  actions: [okButton],
                );
              }
          );
        });
  }

  Future<List<StuffRequest>> fetchData() async {
    List<StuffRequest> stuffList = [];

    List<Future> futures = [
      FinanceHttp.waitForResponseInSeconds(seconds: 5),
      RequestsHttp.getStuffRequests()
    ];

    var response = await Future.any(futures);

    await Future.delayed(Duration(milliseconds: 150));

    if (response.statusCode == 200) {
      jsonDecode(response.body).forEach((element) {
        stuffList.add(StuffRequest.fromJsonMap(element));
      });

      requestsAmount = stuffList.length;
      await _saveStuffRequestsInLocalStorage(stuffList);
    }

    return stuffList;
  }

  Future<void> _saveStuffRequestsInLocalStorage(
      List<StuffRequest> stuffList) async {
    return await LocalStorageStuffRequests.saveList(stuffList);
  }

  void createEntry() async {
    Widget okButton = ElevatedButton(
        onPressed: () async {
          StuffRequest stuffRequest = StuffRequest(DateTime.now().toString(),
              widget.personName, operationNameController.text);

          await PersistingService.saveStuffRequest(stuffRequest);

          Navigator.pop(context);
          setState(() {
            pullData();
          });
        },
        child: Text('Ok'));

    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('New request:'),
                content: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(20),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter some text';
                              }
                              return null;
                            },
                            controller: operationNameController,
                            decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Operation name'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [okButton],
              );
            },
          );
        });
  }

  Widget locallySavedStuffRequests() {
    return FutureBuilder(
        future: LocalStorageStuffRequests.getSavedList(),
        builder: (builder, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(
                child: Column(
                  children: [
                    Text("bringing locally saved stuff"),
                    CircularProgressIndicator(
                      color: Colors.red,
                    ),
                  ],
                ));

          List<StuffRequest> data = snapshot.data as List<StuffRequest>;

          return GridView.builder(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 150,
                  crossAxisSpacing: 0,
                  mainAxisSpacing: 5),
              itemCount: data.length,
              itemBuilder: (BuildContext ctx, index) {
                return singleTile(data.elementAt(index));
              });
        });
  }
}
