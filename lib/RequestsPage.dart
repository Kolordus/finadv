import 'dart:convert';
import 'dart:core';

import 'package:finadv/model/StuffRequest.dart';
import 'package:finadv/service/LocalStorageStuffRequests.dart';
import 'package:finadv/service/PersistingService.dart';
import 'package:finadv/web/FinanceHttp.dart';
import 'package:finadv/web/RequestsHttp.dart';
import 'package:flutter/material.dart';

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
  late Future<List<StuffRequest>> _fetchDataFuture = fetchData();

  @override
  void initState() {
    super.initState();
    this._fetchDataFuture = fetchData();
    this.pullData();
    // to do preferences!!
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
      appBar: AppBar(
        title: Text("Requests"),
        actions: [IconButton(
            icon: Icon(
              Icons.refresh,
            ),
            onPressed: () async {
              await PersistingService.sendLocallySaved();
              setState(() {
              });
            })],
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
                  begin: Alignment.bottomLeft, end: Alignment.topRight,
                  colors:
                  [
                    Colors.blue,
                    Colors.white10
                  ]
              ),
              borderRadius: BorderRadius.all(Radius.circular(10))),
          child: FutureBuilder(
              future: this._fetchDataFuture,
              builder: (builder, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return Center(child: CircularProgressIndicator(color: Colors.red,));
                if (snapshot.hasError)
                  return Column(
                    // mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('No internet connection :( reading locally saved', style: TextStyle(fontSize: 20),),
                      locallySavedStuffRequests(),
                    ],
                  );

                if (snapshot.connectionState == ConnectionState.done && _stuffRequests.length == 0)
                  return Center(child: Text('No requests', style: TextStyle(fontSize: 20),));

                return GridView.builder(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 150,
                        crossAxisSpacing: 0,
                        mainAxisSpacing: 5),
                    itemCount: _stuffRequests.length,
                    itemBuilder: (BuildContext ctx, index) {
                      return singleTile(_stuffRequests.elementAt(index), true);
                    });
              }),
        ),
      )
    );
  }

  Widget singleTile(StuffRequest stuff, bool showDeleteButton) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4.0, 0.0, 4.0, 0.0),
      child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: Colors.black54, borderRadius: BorderRadius.circular(15)),
          child: Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                stuff.personName,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.blue,
                    fontSize: 10,
                    decoration: TextDecoration.none),
              ),
              Text(
                stuff.date,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.blue,
                    fontSize: 10,
                    decoration: TextDecoration.none),
              ),
              Text(
                stuff.operationName,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.blue,
                    fontSize: 13,
                    decoration: TextDecoration.none),
              ),
              showDeleteButton ? OutlinedButton(
                  onPressed: () async {
                    await RequestsHttp.deleteStuffRequest(stuff.date);
                    this.pullData();
                  },
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                  ),
                  child: Icon(
                    Icons.cancel,
                    size: 20,
                    color: Colors.red,
                  )) : Text('LOCAL', style: TextStyle(color: Colors.red),)
            ],
          ))),
    );
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

      await _saveStuffRequestsInLocalStorage(stuffList);
    }

    return stuffList;
  }

  Future<void> _saveStuffRequestsInLocalStorage(List<StuffRequest> stuffList) async {
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
    return
      FutureBuilder(
          future: LocalStorageStuffRequests.getSavedList(),
          builder: (builder, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return Center(child: Column(
                children: [
                  Text("bringing locally saved stuff"),
                  CircularProgressIndicator(color: Colors.red,),
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
                  return singleTile(data.elementAt(index), false);
                });
          });
  }

}

