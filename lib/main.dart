import 'package:finadv/FinanceDetailsCard.dart';
import 'package:finadv/service/PersistingService.dart';
import 'package:finadv/service/LocalStorage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'SummaryCard.dart';

void main() async {
  runApp(MyApp());
  LocalStorage.showAll();
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
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey,
        onTap: _onItemTapped,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.accessibility_sharp),
              label: 'Pau'
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.accessible),
              label: "Jack"
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.attach_money),
              label: 'Podsumowanie'
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
          FinanceDetailsCard(personName: 'Pau'),
          FinanceDetailsCard(personName: 'Jack'),
          SummaryCard(persons: ['Pau', "Jack"],),
        ],
      )
    );
  }

}