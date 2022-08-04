import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class UserAttendance {
  String profilePic, username, attendance, date;
  UserAttendance(this.profilePic, this.username, this.date, this.attendance);
}

class DatabaseKeyValue {
  String key;
  String value;
  DatabaseKeyValue(this.key, this.value);
}

class Database {
  String parent;
  List<DatabaseKeyValue> children = [];
  Database(this.parent);
}



// class UserAttendance {
//   String username;
//   String date;
//   String attendance;
//   UserAttendance(this.username, this.date, this.attendance);
// }



class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'Attendance Management System';

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: _title,
      home: AdminPage(),
      debugShowCheckedModeBanner: false,
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

  // static List<String> list = <String>[];

  static List<UserAttendance> userAttendanceList = <UserAttendance>[];

  static List<Database> dbList = [];

  // static String newValue = "Present";




  // List<Shop> itemsShop = [];
  // Shop itemShop = Shop("A", "B", "C", "D", "E");
  // DatabaseReference itemRefShop = FirebaseDatabase.instance.reference().child('UserInfo');

  // final db = FirebaseFirestore.instance;
  int _selectedIndex = 0;
  static const TextStyle optionStyle =
  TextStyle(fontSize: 30, fontWeight: FontWeight.bold);


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
    // list.clear();

    dbList.clear();

    for (var element in database.snapshot.children) {
      Database dbUser = Database(element.key.toString());
      for (var element2 in element.children) {
        dbUser.children.add(DatabaseKeyValue(element2.key.toString(), element2.value.toString()));
        // list.add("${element2.key} ${element2.value}");
        // debugPrint("${element2.key} ${element2.value}");

      }
      dbList.add(dbUser);
    }

    for(var e in dbList){
      for (var e2 in e.children) {
        debugPrint("${e.parent} ${e2.key} ${e2.value}");
      }
    }

    setUserAttendance(dbList, userAttendanceList);

    return true;
  }

  getWidget(){
    final List<Widget> _widgetOptions = <Widget>[
      Column(
          children: <Widget>[
            Flexible(
              child: ListView.builder(
                itemCount: userAttendanceList.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    shadowColor: Colors.grey.shade300,
                    child: ListTile(
                      title: Text(
                        userAttendanceList[index].username,
                      ),
                      subtitle: Text(
                        userAttendanceList[index].date,
                      ),
                      // trailing: Text(
                      //   userAttendanceList[index].attendance,
                      // ),
                      trailing: DropdownButton<String>(
                        value: userAttendanceList[index].attendance,
                        items: <String>['Present', 'Absent'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          userAttendanceList[index].attendance = newValue!;
                          FirebaseDatabase.instance.ref("UserInfo").child(userAttendanceList[index].username).child("Attendance-${userAttendanceList[index].date}").set(newValue);
                          setState(() {});
                        },
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
    return _widgetOptions[_selectedIndex];
  }


  @override
  Widget build(BuildContext context) {
    // DatabaseReference ref = FirebaseDatabase.instance.ref("UserInfo");

    return FutureBuilder<bool>(
        future: initialize(),
        builder: (context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Attendance Management System'),
              ),
              body: Center(
                child: getWidget(),
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
              floatingActionButton: FloatingActionButton(
                backgroundColor: const Color(0xff03dac6),
                foregroundColor: Colors.black,
                tooltip: 'Add Attendance',
                onPressed: () {
                  // Respond to button press
                  showToast("Add Attendance Pressed");
                },
                child: const Icon(Icons.add),
              ),
            );
          } else {
            return Scaffold(
                appBar: AppBar(
                  title: const Text('Attendance Management System'),
                ),
                body: const Center(
                  child: CircularProgressIndicator()
                )
            );
          }
        }
    );
  }

  static void showToast(String str){
    Fluttertoast.showToast(
        msg: str,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.yellow
    );
  }


  int getMaxLength(List<Database> db){
    int count = 0;
    for (var i in db){
      for (var j in i.children){
        count++;
      }
    }
    return count;
  }

  void setUserAttendance(List<Database> list, List<UserAttendance> userAttendanceList){
    userAttendanceList.clear();
    for(var e in list){
      for (var e2 in e.children) {
        if (e2.key.contains("Attendance-")) {
          userAttendanceList.add(UserAttendance(
              "", e.parent, e2.key.replaceFirst("Attendance-", ""), e2.value));
        }
      }
    }
  }
}


