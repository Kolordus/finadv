import 'package:finadv/FinanceDetailsCard.dart';
import 'package:finadv/service/PersistingService.dart';
import 'package:finadv/service/LocalStorage.dart';
import 'package:finadv/utils/Constants.dart';
import 'package:flutter/material.dart';
import 'dart:core' as std;

import 'SummaryCard.dart';

void main() async {
  runApp(MyApp());
  LocalStorage.showAll();
  await PersistingService.sendLocallySaved();
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @std.override
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
  final std.String title;

  @std.override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  std.int _selectedIndex = 0;
  PageController pageController = PageController(initialPage: 0);

  void _onItemTapped(std.int index) {
    setState(() {
      _selectedIndex = index;
      pageController.animateToPage(index,
          duration: std.Duration(milliseconds: 200), curve: Curves.bounceInOut);
    });
  }

  @std.override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black12,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey,
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
          SummaryCard(persons: [Constants.PAU, Constants.JACK],),
        ],
      )
    );
  }

}
