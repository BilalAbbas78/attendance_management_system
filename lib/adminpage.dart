import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: _title,
      home: AdminPage(),
    );
  }
}

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {

  // static var list = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"];

  static List<String> list = <String>[];

  // List<Shop> itemsShop = [];
  // Shop itemShop = Shop("A", "B", "C", "D", "E");
  // DatabaseReference itemRefShop = FirebaseDatabase.instance.reference().child('UserInfo');

  final db = FirebaseFirestore.instance;
  int _selectedIndex = 0;
  static const TextStyle optionStyle =
  TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static final List<Widget> _widgetOptions = <Widget>[
    Column(
        children: <Widget>[
          Flexible(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (BuildContext context, int index) {
                return Card(
                  shadowColor: Colors.grey.shade300,
                  child: ListTile(
                    title: Text(
                      list[index],
                    ),
                  ),
                );
              },
            ),
          ),
        ]
    ),
    const Text(
      'Index 1: Business',
      style: optionStyle,
    ),
    const Text(
      'Index 2: School',
      style: optionStyle,
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<bool> initialize() async {
    final database = await FirebaseDatabase.instance
        .ref()
        .child("UserInfo")
        .once();

    // debugPrint(database.snapshot.value.toString());

    // debugPrint(database.toString());
    list.clear();

    for (var element in database.snapshot.children) {
      for (var element2 in element.children) {
        list.add("${element2.key} ${element2.value}");
        // debugPrint("${element2.key} ${element2.value}");

      }
    }

    for(var e in list){
      debugPrint(e);
    }

    return true;
  }


  @override
  Widget build(BuildContext context) {
    DatabaseReference ref = FirebaseDatabase.instance.ref("UserInfo");

    return FutureBuilder<bool>(
        future: initialize(),
        builder: (context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Attendance Management System'),
              ),
              body: Center(
                child: _widgetOptions.elementAt(_selectedIndex),
              ),
              bottomNavigationBar: BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'View Attendance',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.business),
                    label: 'Business',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.school),
                    label: 'School',
                  ),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: Colors.amber[800],
                onTap: _onItemTapped,
              ),
            );
          } else {
            return Center(child: const CircularProgressIndicator());
          }
        }
    );
  }
}

class Shop {
  String key;
  String name;
  String address;
  String phone;
  String thumbnail;

  Shop(this.key, this.name,this.address,this.phone,this.thumbnail);


}
