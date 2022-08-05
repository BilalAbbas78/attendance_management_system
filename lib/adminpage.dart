import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

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

class LeaveApproval {
  String username, date, reason;
  LeaveApproval(this.username, this.date, this.reason);
}



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

  DateTime selectedDateAddAttendance = DateTime.now();
  DateTime selectedDateFilterAttendance = DateTime.now();
  static List<Database> dbList = [];
  static List<UserAttendance> userAttendanceList = [];
  static List<String> attendanceList = ['Present', 'Absent', 'Leave'];
  static List<String> addAttendanceInfo = ['', '', ''];
  static List<UserAttendance> searchWithDateList = [];
  static List<LeaveApproval> leaveApprovalList = [];

  int _selectedIndex = 0;

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
        // list.add("${element2.key} ${element2.value}");
        // debugPrint("${element2.key} ${element2.value}");

      }
      dbList.add(dbUser);
    }

    setUserAttendance(dbList, userAttendanceList);
    setLeaveApprovalList();

    String formatDate(DateTime date) => DateFormat("dd-MM-yyyy").format(date);

    searchWithDate(formatDate(selectedDateFilterAttendance));

    return true;
  }

  setLeaveApprovalList(){
    leaveApprovalList.clear();
    for(var e in dbList){
      for (var e2 in e.children) {
        if (e2.key.contains("LeaveApproval-")) {
          leaveApprovalList.add(LeaveApproval(e.parent, e2.key.replaceFirst("LeaveApproval-", ""), e2.value));
        }
      }
    }
    // leaveApprovalList.add(LeaveApproval('user1', '2020-01-01', 'reason1'));
  }

  getWidget(){
    final List<Widget> widgetOptions = <Widget>[
      Scaffold(
        appBar: AppBar(
          title: const Text('Attendance Management System'),
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: () {
                _selectDateSearchAttendance(context);
                // showToast("Calender clicked");
              },
            ),
            // add more IconButton
          ],
        ),
        body: Center(
          child: Column(
              children: <Widget>[
                Flexible(
                  child: ListView.builder(
                    itemCount: searchWithDateList.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Card(
                        shadowColor: Colors.grey.shade300,
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(searchWithDateList[index].username[0]),
                          ),
                          title: Text(
                            searchWithDateList[index].username,
                          ),
                          subtitle: Text(
                            searchWithDateList[index].date,
                          ),
                          // trailing: Text(
                          //   searchWithDateList[index].attendance,
                          // ),
                          trailing: DropdownButton<String>(
                            value: searchWithDateList[index].attendance,
                            items: <String>['Present', 'Absent', 'Leave'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              searchWithDateList[index].attendance = newValue!;
                              FirebaseDatabase.instance.ref("UserInfo").child(searchWithDateList[index].username).child("Attendance-${searchWithDateList[index].date}").set(newValue);
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
        ),
        bottomNavigationBar: getBottomNavigationBar(),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xff03dac6),
          foregroundColor: Colors.black,
          tooltip: 'Add Attendance',
          onPressed: () {
            // Respond to button press
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
      ),


      Scaffold(
        appBar: AppBar(
          title: const Text('Attendance Management System'),
        ),
        body: Center(
          child: getLeaveApprovalWidget(),
        ),
        bottomNavigationBar: getBottomNavigationBar(),
      ),




      Scaffold(
        appBar: AppBar(
          title: const Text('Attendance Management System'),
        ),
        body: const Center(
          child: Text (
            "Grading",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        bottomNavigationBar: getBottomNavigationBar(),
      ),
    ];
    return widgetOptions[_selectedIndex];
  }

  getLeaveApprovalWidget(){
    if (leaveApprovalList.isEmpty){
      return const Text (
        "No leave approval pending",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    else {
      return Column(
          children: <Widget>[
            Flexible(
              child: ListView.builder(
                itemCount: leaveApprovalList.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    shadowColor: Colors.grey.shade300,
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(leaveApprovalList[index].username[0]),
                      ),
                      title: Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Text(leaveApprovalList[index].username),
                      ),
                      subtitle: Column (
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Text(leaveApprovalList[index].date),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                              child: Text(leaveApprovalList[index].reason),
                            ),
                          ]
                      ),
                      trailing: SizedBox(
                        width: 100,
                        child: Row(
                          children: [
                            IconButton(onPressed: () {
                              FirebaseDatabase.instance.ref("UserInfo").child(leaveApprovalList[index].username).child("LeaveApproval-${leaveApprovalList[index].date}").remove();
                              FirebaseDatabase.instance.ref("UserInfo").child(leaveApprovalList[index].username).child("LeaveRejected-${leaveApprovalList[index].date}").set(leaveApprovalList[index].reason);
                              setState(() {
                                leaveApprovalList.removeAt(index);
                              });
                              showToast("Leave Rejected");
                            }, icon: const Icon(Icons.not_interested)),
                            IconButton(onPressed: () {
                              FirebaseDatabase.instance.ref("UserInfo").child(leaveApprovalList[index].username).child("LeaveApproval-${leaveApprovalList[index].date}").remove();
                              FirebaseDatabase.instance.ref("UserInfo").child(leaveApprovalList[index].username).child("LeaveAccepted-${leaveApprovalList[index].date}").set(leaveApprovalList[index].reason);
                              FirebaseDatabase.instance.ref("UserInfo").child(leaveApprovalList[index].username).child("Attendance-${leaveApprovalList[index].date}").set("Leave");
                              setState(() {
                                leaveApprovalList.removeAt(index);
                              });
                              showToast("Leave Approved");
                            }, icon: const Icon(Icons.done)),
                          ],
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

  getBottomNavigationBar(){
    return BottomNavigationBar(
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
    );
  }


  @override
  Widget build(BuildContext context) {
    // DatabaseReference ref = FirebaseDatabase.instance.ref("UserInfo");



    return FutureBuilder<bool>(
        future: initialize(),
        builder: (context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.hasData) {
            return getWidget();


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

  void searchWithDate(String date) {
    searchWithDateList.clear();
    for(var e in userAttendanceList){
      if(e.date == date){
        searchWithDateList.add(e);
      }
    }

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
              addAttendanceInfo[0] = dbList[index].parent;
              _selectDateAddAttendance(context);
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
              addAttendanceInfo[2] = attendanceList[index];
              FirebaseDatabase.instance.ref("UserInfo").child(addAttendanceInfo[0]).child("Attendance-${addAttendanceInfo[1]}").set(addAttendanceInfo[2]);
              showToast("Attendance Added");
              selectedDateFilterAttendance = selectedDateAddAttendance;
              // searchWithDate(addAttendanceInfo[1]);
              setState(() {
              });
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }


  Future<void> _selectDateAddAttendance(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDateAddAttendance,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null) {
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
        String formatDate(DateTime date) => DateFormat("dd-MM-yyyy").format(date);
        addAttendanceInfo[1] = formatDate(picked);
      });
    }
  }

  Future<void> _selectDateSearchAttendance(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDateFilterAttendance,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null) {
      setState(() {
        selectedDateFilterAttendance = picked;
        String formatDate(DateTime date) => DateFormat("dd-MM-yyyy").format(date);
        searchWithDate(formatDate(picked));
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
                Text('Are you sure want to delete this attendance?'),
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
              child: const Text('Delete'),
              onPressed: () {
                FirebaseDatabase.instance.ref("UserInfo").child(searchWithDateList[index].username).child("Attendance-${searchWithDateList[index].date}").remove();
                searchWithDateList.removeAt(index);
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


