import 'dart:convert';
import 'dart:core';

import 'package:finadv/model/StuffRequest.dart';
import 'package:finadv/utils/HttpRequests.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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


  @override
  void initState() {
    super.initState();
    this.pullData();
    // to do preferences!!
  }

  refreshScreen() {
    setState(() {
      // teraz tak: to by wyglądało na invalidate cache...
      // ale chyba dużo aplikacji ma zrobione tak, żę przeładowuje dane
      // wiec zostawiam to tak jak jest
    });
  }

  void pullData() async {
    final prefs = await SharedPreferences.getInstance();

    // todo prefs!!
    try {
      var _stuffRequests = await fetchData();
      setState(() {
        this._stuffRequests = _stuffRequests;
      });
    } catch (e) {
      print(e);
      print('jest kurwa~!!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Requests"),),
      floatingActionButton: OutlinedButton(
          onPressed: () async {

            // var stuffRequest = StuffRequest(DateTime.now().toString(), "pau", "mockowa operacja!");
            // await HttpRequests.saveStuffRequest(stuffRequest);

            this.createEntry();
          },
          style: ElevatedButton.styleFrom(
            shape: CircleBorder(),
          ),
          child: Icon(Icons.fiber_new, size: 50, color: Colors.green,)
      ),
      body: Container(
        color: Colors.blueGrey,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              FutureBuilder(
                future: fetchData(),
                builder: (builder, snapshot) {
                  if (snapshot.hasError) return Text('no to dupsko');
                  return GridView.builder(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 150,
                          crossAxisSpacing: 0,
                          mainAxisSpacing: 5),
                      itemCount: _stuffRequests.length,
                      itemBuilder: (BuildContext ctx, index) {
                        return singleTile(_stuffRequests.elementAt(index));
                      });
              }
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget singleTile(StuffRequest stuff) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4.0, 0.0, 4.0, 0.0),
      child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(15)
          ),
          child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(stuff.personName,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blue,
                        fontSize: 10,
                        decoration: TextDecoration.none),),
                  Text(stuff.date,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blue,
                        fontSize: 10,
                        decoration: TextDecoration.none),),
                  Text(stuff.operationName,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blue,
                        fontSize: 13,
                        decoration: TextDecoration.none),),
                  OutlinedButton(
                      onPressed: () async {
                        await HttpRequests.deleteStuffRequest(stuff.date);
                        this.pullData();
                      },
                      style: ElevatedButton.styleFrom(
                        shape: CircleBorder(),
                      ),
                      child: Icon(Icons.cancel, size: 20, color: Colors.red,)
                  )
                ],
              ))),
    );
  }

  fetchData() async {
    await Future.delayed(Duration(milliseconds: 150));
    List<StuffRequest> stuffList = [];

    List<Future> futures = [
      HttpRequests.waitForResponseInSeconds(seconds: 3),
      HttpRequests.getStuffRequests()
    ];
    var response = await Future.any(futures);

    if (response.statusCode == 200) {
      jsonDecode(response.body).forEach((element) {
        stuffList.add(StuffRequest.fromJsonMap(element));
      });

      await _saveStuffRequestsInLocalStorage(stuffList);
    }

    return stuffList;
  }

  Future<void> _saveStuffRequestsInLocalStorage(List<StuffRequest> stuffList) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> stuffRequestsList = [];

    stuffList.forEach((element) {
      stuffRequestsList.add(element.toString());
    });

    prefs.setStringList('requests', stuffRequestsList);
  }

  void createEntry() async {
    Widget okButton = ElevatedButton(
        onPressed: () async {
          StuffRequest stuffRequest = StuffRequest(
              DateTime.now().toString(),
              widget.personName,
              operationNameController.text
          );

          await HttpRequests.saveStuffRequest(stuffRequest);

          Navigator.pop(context);
          setState(() { pullData(); });
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

}
