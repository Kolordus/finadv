import 'package:finadv/service/LocalStorage.dart';
import 'package:finadv/utils/Constants.dart';
import 'package:flutter/material.dart';

import 'model/FinanceEntry.dart';

class DataToSendScreen extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => _DataToSendScreenState();

}

class _DataToSendScreenState extends State<DataToSendScreen> {

  Future<List<FinanceEntry>> getEntitiesToSave() async {
    List<String> jsonList = await LocalStorage.getSavedRecords();
    List<FinanceEntry> list = [];

    jsonList.forEach((element) {
      list.add(FinanceEntry.fromJsonString(element));
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigoAccent,
        title: Text('Waiting entities'),
      ),
      backgroundColor: Colors.white60,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: FutureBuilder(
              future: getEntitiesToSave(),
              builder: (builder, snapshot) {
                return snapshot.connectionState == ConnectionState.waiting
                    ? Center(child: CircularProgressIndicator())
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    renderLastPaymentsWidget(snapshot.data, context),
                  ],
                );
              }),
        ),
      ),
    );
  }

  Widget renderLastPaymentsWidget(_paymentList, context) {
    var actionsAmount = _paymentList?.length ?? 0;
    var deviceWidth = MediaQuery.of(context).size.width;

    return actionsAmount == 0
        ? Center(child: Text('Nothing to show'))
        : Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10))),
      width: deviceWidth * 0.95,
      child: ListView.builder(
          shrinkWrap: true,
          itemCount: actionsAmount,
          itemBuilder: (context, index) {
            var currentElement = _paymentList.elementAt(index);
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
                        // menuItem(Constants.EDIT)
                      ]);

                  await _performAction(name, currentElement, _paymentList);
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
                            Text(currentElement.personName),
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

  Future<void> _performAction(name, FinanceEntry financeEntry, List<FinanceEntry> financeEntryList) async {
    if (name == null)
      return;
    if (name == Constants.DELETE) {
      await LocalStorage.removeRecordFromLocal(financeEntry);
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

}