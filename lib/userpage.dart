// import 'package:firebase_database/firebase_database.dart';
import 'package:attendance_management_system/loginpage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import 'adminpage.dart';

class UserAttendance {
  String date, attendance, sortedDate = "";
  UserAttendance(this.date, this.attendance){
    sortedDate = date.split("-").reversed.join("-");
  }
}

class UserLeaveRequest {
  String date, reason, status, sortedDate = "";
  UserLeaveRequest(this.date, this.reason, this.status){
    sortedDate = date.split("-").reversed.join("-");
  }
}

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'Attendance Management System';

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: _title,
      home: UserPage(strUsername: null,),
      debugShowCheckedModeBanner: false,
    );
  }
}

class UserPage extends StatefulWidget {
  // ignore: prefer_typing_uninitialized_variables
  final strUsername;
  static String myUsername = "";
  const UserPage({Key? key, @required this.strUsername}) : super(key: key);

  @override
  // ignore: no_logic_in_create_state
  State<UserPage> createState() {
    myUsername = strUsername;
    return _UserPageState();
  }
}

class _UserPageState extends State<UserPage> {


  static List<Database> dbList = [];
  static List<UserAttendance> userAttendanceList = [];
  static List<UserLeaveRequest> userLeaveRequestList = [];
  int _selectedIndex = 0;
  String username =   UserPage.myUsername;
  static String todayDateReverse = DateTime.now().toString().substring(0, 10);
  static String todayDate = todayDateReverse.split("-").reversed.join("-");
  DateTime selectedDateAddAttendance = DateTime.now();
  final TextEditingController _textFieldController = TextEditingController();





  @override
  Widget build(BuildContext context) {
    LoginPageState.txtUsername.clear();
    LoginPageState.txtPassword.clear();
    // FocusScope.of(LoginPageState().context).requestFocus(LoginPageState.txtUsernameFocusNode);
    return FutureBuilder<bool>(
        future: initialize(),
        builder: (context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.hasData) {
            return getWidget();
          } else {
            return Scaffold(
                appBar: AppBar(
                  title: const Text('Attendance Management System',
                    style: TextStyle(
                      fontSize: 17,
                    ),
                  ),
                ),
                body: const Center(
                    child: CircularProgressIndicator()
                )
            );
          }
        }
    );
  }

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

    dbList.clear();
    for (var element in database.snapshot.children) {
      Database dbUser = Database(element.key.toString());
      for (var element2 in element.children) {
        dbUser.children.add(DatabaseKeyValue(element2.key.toString(), element2.value.toString()));
      }
      dbList.add(dbUser);
      setUserAttendanceList();
      setUserLeaveRequestList();
      // showToast(todayDate);
    }

    // setUserAttendance(dbList, userAttendanceList);
    // setLeaveApprovalList();
    // setGradingList();
    // String formatDate(DateTime date) => DateFormat("dd-MM-yyyy").format(date);
    // searchWithDate(formatDate(selectedDateFilterAttendance));

    return true;
  }

  setUserLeaveRequestList() {
    userLeaveRequestList.clear();
    for (var element in dbList) {
      for (var element2 in element.children) {
        if (element2.key.startsWith("Leave") && element.parent == username) {
          if (element2.key.startsWith("LeaveRequest")) {
            userLeaveRequestList.add(UserLeaveRequest(
                element2.key.replaceFirst("LeaveRequest-", ""), element2.value,
                "Pending"));
          }
          else if (element2.key.startsWith("LeaveAccepted")) {
            userLeaveRequestList.add(UserLeaveRequest(
                element2.key.replaceFirst("LeaveAccepted-", ""), element2.value,
                "Accepted"));
          }
          else if (element2.key.startsWith("LeaveRejected")) {
            userLeaveRequestList.add(UserLeaveRequest(
                element2.key.replaceFirst("LeaveRejected-", ""), element2.value,
                "Rejected"));
          }
        }
      }
    }
    userLeaveRequestList.sort((a, b) => a.sortedDate.compareTo(b.sortedDate));
  }

  setUserAttendanceList() {
    userAttendanceList.clear();
    for (var element in dbList) {
      for (var element2 in element.children) {
        if (element2.key.startsWith("Attendance-") && element.parent == username) {
          UserAttendance userAttendance = UserAttendance(element2.key.replaceFirst("Attendance-", ""), element2.value);
          userAttendanceList.add(userAttendance);
        }
      }
    }
    userAttendanceList.sort((a, b) => a.sortedDate.compareTo(b.sortedDate));
  }

  getWidget(){
    final List<Widget> widgetOptions = <Widget>[
      Scaffold(
        appBar: AppBar(
          title: const Text('Attendance Management System',
            style: TextStyle(
              fontSize: 17,
            ),
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.back_hand_outlined),
              onPressed: () {
                FirebaseDatabase.instance.ref().child("UserInfo").child(username).child("Attendance-$todayDate").get().then((value) {
                  if (value.value == "Present") {
                    showToast("Attendance already marked");
                  }
                  else {
                    FirebaseDatabase.instance.ref().child("UserInfo").child(username).child("Attendance-$todayDate").set("Present");
                    showToast("Attendance marked");
                  }
                },
                );
                setState(() {});
              },
            ),
          ],
        ),
        body: Center(
            child: getViewAttendanceWidget()
        ),
        bottomNavigationBar: getBottomNavigationBar(),
      ),



      Scaffold(
        appBar: AppBar(
          title: const Text('Attendance Management System',
            style: TextStyle(
              fontSize: 17,
            ),
          ),
        ),
        body: Center(
          child: getRequestLeaveWidget(),
        ),
        bottomNavigationBar: getBottomNavigationBar(),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xff03dac6),
          foregroundColor: Colors.black,
          tooltip: 'Request Leave',
          onPressed: () {
            _selectDateRequestLeave(context);
          },
          child: const Icon(Icons.add),
        ),
      ),

    ];
    return widgetOptions[_selectedIndex];
  }

  Future<void> _displayTextInputDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          String formatDate(DateTime date) => DateFormat("dd-MM-yyyy").format(date);
          return AlertDialog(
            title: Text('Request Leave for ${formatDate(selectedDateAddAttendance)}'),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  // valueText = value;
                });
              },
              controller: _textFieldController,
              decoration: const InputDecoration(hintText: "Enter Reason for Leave"),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('SUBMIT'),
                onPressed: () {
                  if (_textFieldController.text.isNotEmpty) {
                    FirebaseDatabase.instance
                        .ref()
                        .child("UserInfo")
                        .child(username)
                        .child("LeaveRequest-${formatDate(selectedDateAddAttendance)}")
                        .set(_textFieldController.text);
                    _textFieldController.clear();
                    setState(() {
                      Navigator.pop(context);
                    });
                  }

                },
              ),

            ],
          );
        });
  }

  Future<void> _selectDateRequestLeave(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDateAddAttendance,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null) {
      if (picked.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))) {
        showToast("You can't request leave for past date");
      }
      else {
        // ignore: use_build_context_synchronously
        _displayTextInputDialog(context);
        setState(() {
          selectedDateAddAttendance = picked;
        });
      }
    }
  }

  getRequestLeaveWidget(){
    if (userLeaveRequestList.isEmpty){
      return const Text (
        "Nothing to show",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    else {
      return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
              child: Text("Student: $username",
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                itemCount: userLeaveRequestList.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    shadowColor: Colors.grey.shade300,
                    child: ListTile(
                      title: Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Text(userLeaveRequestList[index].date),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                        child: Text(userLeaveRequestList[index].reason),
                      ),
                      trailing: Text(userLeaveRequestList[index].status,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ]
      );
    }
  }

  getViewAttendanceWidget(){
    if (userAttendanceList.isEmpty){
      return const Text (
        "Nothing to show",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    else {
      return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
              child: Text("Student: $username",
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                itemCount: userAttendanceList.length,
                itemBuilder: (BuildContext context, int index) {
                  if (userAttendanceList[index].date == todayDate) {
                    return Card(
                        shadowColor: Colors.grey.shade300,
                        child: ListTile(
                          title: Text(
                              userAttendanceList[index].date,
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,

                              )
                          ),
                          trailing: Text(
                              userAttendanceList[index].attendance,
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,

                              )
                          ),
                        )
                    );
                  }
                  else {
                    return Card(
                      shadowColor: Colors.grey.shade300,
                      child: ListTile(
                        title: Text(userAttendanceList[index].date),
                        trailing: Text(userAttendanceList[index].attendance,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }

                },
              ),
            ),
          ]
      );
    }
  }

  // void handleClick(String value) {
  //   switch (value) {
  //     case 'Mark Attendance':
  //       FirebaseDatabase.instance.ref().child("UserInfo").child(username).child("Attendance-$todayDate").get().then((value) {
  //         if (value.value == "Present") {
  //           showToast("Attendance already marked");
  //         }
  //         else {
  //           FirebaseDatabase.instance.ref().child("UserInfo").child(username).child("Attendance-$todayDate").set("Present");
  //           showToast("Attendance marked");
  //         }
  //       });
  //       break;
  //     case 'Logout':
  //       showToast('Logout');
  //       break;
  //   }
  //   setState(() {});
  // }

  showToast(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }


  getBottomNavigationBar(){
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'View Attendance',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.approval),
          label: 'Request Leave',
        ),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.amber[800],
      onTap: _onItemTapped,
    );
  }
}

