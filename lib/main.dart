import 'dart:core';

import 'package:finadv/FinanceDetailsCard.dart';
import 'package:finadv/service/LocalStorageFinanceEntries.dart';
import 'package:finadv/service/PersistingService.dart';
import 'package:finadv/utils/Constants.dart';
import 'package:flutter/material.dart';

import 'SummaryCard.dart';

// flutter build apk --split-per-abi
void main() async {
  runApp(MyApp());
  await PersistingService.sendLocallySaved();
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Domkowe rozliczenia',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Domkowe rozliczenia'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  PageController pageController = PageController(initialPage: 0);

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      pageController.animateToPage(index,
          duration: Duration(milliseconds: 200), curve: Curves.bounceInOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black12,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(30), topLeft: Radius.circular(30)),
          boxShadow: [
            BoxShadow(color: Colors.black38, spreadRadius: 0, blurRadius: 10),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10.0),
            topRight: Radius.circular(10.0),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.blueAccent,
            onTap: _onItemTapped,
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.white,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                  icon: Icon(Icons.accessibility_sharp),
                  label: Constants.PAU
              ),
              BottomNavigationBarItem(
                  icon: Icon(Icons.accessible),
                  label: Constants.JACK
              ),
              BottomNavigationBarItem(
                  icon: Icon(Icons.attach_money),
                  label: Constants.SUM_UP
              ),
            ],
          ),
        ),
      ),
      body: PageView(
        controller: pageController,
        onPageChanged: (value) => {
          setState(() => {
            _selectedIndex = value
          })
        },
        children: [
          FinanceDetailsCard(personName: Constants.PAU),
          FinanceDetailsCard(personName: Constants.JACK),
          SummaryCard(),
        ],
      )
    );
  }

}
