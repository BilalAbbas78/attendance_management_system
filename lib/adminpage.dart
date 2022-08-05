import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore: import_of_legacy_library_into_null_safe
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
  DateTime selectedDateAddAttendance = DateTime.now();
  DateTime selectedDateFilterAttendance = DateTime.now();
  static List<Database> dbList = [];
  static List<String> attendanceList = ['Present', 'Absent', 'Leave'];

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

    // for(var e in dbList){
    //   for (var e2 in e.children) {
    //     debugPrint("${e.parent} ${e2.key} ${e2.value}");
    //   }
    // }

    setUserAttendance(dbList, userAttendanceList);

    return true;
  }

  getWidget(){
    final List<Widget> widgetOptions = <Widget>[
      Column(
          children: <Widget>[
            Flexible(
              child: ListView.builder(
                itemCount: userAttendanceList.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    shadowColor: Colors.grey.shade300,
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(userAttendanceList[index].username[0]),
                      ),
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
                        items: <String>['Present', 'Absent', 'Leave'].map((String value) {
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
                      onLongPress: () {
                        _deleteAttendanceDialog(index);
                      },
                    ),
                  );
                },
              ),
            ),
          ]
      ),
      const Text(
        'Index 1: Leave Approvals',
        style: optionStyle,
      ),
      const Text(
        'Index 2: Grading',
        style: optionStyle,
      ),
    ];
    return widgetOptions[_selectedIndex];
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
                actions: [
                  IconButton(
                    icon: const Icon(Icons.calendar_month),
                    onPressed: () {
                      showToast("Calender clicked");
                    },
                  ),
                  // add more IconButton
                ],
              ),
              body: Center(
                child: getWidget(),
              ),
              bottomNavigationBar: BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'View Attendance',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.approval),
                    label: 'Leave Approvals',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.grading),
                    label: 'Grading',
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
                  // showToast("Add Attendance Pressed");
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Select one Student'),
                          content: addAttendanceStudentsListDialog(),
                        );
                      });
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

  Widget addAttendanceStudentsListDialog() {
    return SizedBox(
      height: 300.0, // Change as per your requirement
      width: 300.0, // Change as per your requirement
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: dbList.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text(dbList[index].parent),
            onTap: () {
              // Navigator.of(context).pop();
              _selectDate(context);
              showToast(dbList[index].parent);
            },
          );
        },
      ),
    );
  }

  Widget addAttendanceListDialog() {
    return SizedBox(
      height: 300.0, // Change as per your requirement
      width: 300.0, // Change as per your requirement
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: 3,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text(attendanceList[index]),
            onTap: () {
              // _selectDate(context);
              showToast(attendanceList[index]);
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }


  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDateAddAttendance,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != selectedDateAddAttendance) {
      showDialog(
          context: context,
          builder: (BuildContext context) {

            return AlertDialog(
              title: const Text('Select Attendance'),
              content: addAttendanceListDialog(),
            );

          });
      setState(() {
        selectedDateAddAttendance = picked;
        showToast("${selectedDateAddAttendance.toLocal()}".split(' ')[0]);

      });
    }
  }

  Future<void> _deleteAttendanceDialog(int index) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Attendance'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('Do you want to delete this attendance?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                FirebaseDatabase.instance.ref("UserInfo").child(userAttendanceList[index].username).child("Attendance-${userAttendanceList[index].date}").remove();
                userAttendanceList.removeAt(index);
                setState(() {});
                showToast("Attendance Deleted");
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
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


