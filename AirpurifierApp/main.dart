
import 'package:airpurifier_fin/DebugPage.dart';
import 'package:airpurifier_fin/HomePage.dart';
import 'package:airpurifier_fin/ManageButton.dart';
import 'package:airpurifier_fin/ManageColor.dart';
import 'package:airpurifier_fin/SettingPage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDeWQoWQMlSBovPHB6p9-LT0HuyqC9UXR4",
      appId: "1:128369275382:android:2f6105b7d102b1881297d7",
      messagingSenderId: "128369275382",
      projectId: "sht2024-za-airpurifier",
      storageBucket: "sht2024-za-airpurifier.appspot.com"
    )
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ColorProvider()),
        ChangeNotifierProvider(create: (context) => SwitchProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        splashColor: Colors.transparent, // 터치 시 스플래시 효과 제거
        //highlightColor: Colors.transparent, // 터치 시 하이라이트 효과 제거
      ),
      debugShowCheckedModeBanner: false,
      title: 'AirPurifierDesign',
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPagetState();
}

class _MainPagetState extends State<MainPage> {
  int _selectedIndex = 1;
  
  final List<Widget> _widgetOptions = <Widget>[
    Debugpage(),
    const Homepage(),
    const Settingpage()
  ];

  void _onItemTapped(int index){
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        elevation: 0.0, //떠 있는 듯한 효과 제거
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.device_hub),
            label: 'Debug'
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home'
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        onTap: _onItemTapped,
        showUnselectedLabels: false,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold 
        ),
      ),
    );
  }
}