import 'dart:async';

import 'package:attendance_management_system/loginpage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:month_year_picker/month_year_picker.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_localizations/flutter_localizations.dart';



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

class LeaveRequest {
  String username, date, reason, sortedDate = "";
  LeaveRequest(this.username, this.date, this.reason){
    sortedDate = date.split("-").reversed.join("-");
  }
}

class Grading {
  String username, grade = "", present, absent, leave;
  Grading(this.username, this.present, this.absent, this.leave){
    if (int.parse(present) >= 26) {
      grade = "A";
    } else if (int.parse(present) >= 21) {
      grade = "B";
    } else if (int.parse(present) >= 16) {
      grade = "C";
    } else if (int.parse(present) >= 11) {
      grade = "D";
    } else if (int.parse(present) >= 6) {
      grade = "E";
    } else {
      grade = "F";
    }
  }
}



class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'Attendance Management System';

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        MonthYearPickerLocalizations.delegate,
      ],
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
  static List<LeaveRequest> leaveRequestList = [];
  static List<Grading> gradingList = [];
  static List<String> gradingMonthYear = [DateTime.now().year.toString(), zeros(DateTime.now().month.toString())];

  int _selectedIndex = 0;

  final Completer<GoogleMapController> _controller = Completer();

  static const CameraPosition initialCameraPosition = CameraPosition(
    bearing: -40.0,
    tilt: 40.0,
    target: LatLng(33.603577, 73.026438),
    zoom: 20.0,
  );

  // static const CameraPosition ezilineCameraPosition = CameraPosition(
  //     bearing: -40.0,
  //     target: LatLng(33.603577, 73.026438),
  //     tilt: 40,
  //     zoom: 20);

  // gotoEziline() async {
  //   final GoogleMapController controller = await _controller.future;
  //   controller.animateCamera(CameraUpdate.newCameraPosition(ezilineCameraPosition));
  // }



  @override
  Widget build(BuildContext context) {
    LoginPageState.txtUsername.clear();
    LoginPageState.txtPassword.clear();

    // showToast("str");


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
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    )
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
    // if (index == 3) {
    //   gotoEziline();
    // }

    setState(() {
      _selectedIndex = index;
      // showToast(index.toString());

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
    setLeaveRequestList();
    setGradingList();

    String formatDate(DateTime date) => DateFormat("dd-MM-yyyy").format(date);

    searchWithDate(formatDate(selectedDateFilterAttendance));

    return true;
  }

  static zeros(String str){
    if (str.length == 1) {
      return "0$str";
    } else {
      return str;
    }
  }

  setGradingList(){
    int present, absent, leave;
    gradingList.clear();
    for(var e in dbList){
      present = 0; absent = 0; leave = 0;
      for (var e2 in e.children) {
        if (e2.key.contains(RegExp("Attendance-[0-9]{2}-${gradingMonthYear[1]}-${gradingMonthYear[0]}"))) {
          if (e2.value == "Present") {
            present++;
          } else if (e2.value == "Absent") {
            absent++;
          } else if (e2.value == "Leave") {
            leave++;
          }
        }
      }
      if (present != 0 || absent != 0 || leave != 0) {
        Grading g = Grading(e.parent, present.toString(), absent.toString(), leave.toString());
        gradingList.add(g);
      }
    }
  }

  setLeaveRequestList(){
    leaveRequestList.clear();
    for(var e in dbList){
      for (var e2 in e.children) {
        if (e2.key.startsWith("LeaveRequest-")) {
          leaveRequestList.add(LeaveRequest(e.parent, e2.key.replaceFirst("LeaveRequest-", ""), e2.value));
        }
      }
    }
    leaveRequestList.sort((a, b) => a.sortedDate.compareTo(b.sortedDate));
    // leaveRequestList.add(LeaveRequest('user1', '2020-01-01', 'reason1'));
  }

  getWidget(){

    final List<Widget> widgetOptions = <Widget>[
      Scaffold(
        appBar: AppBar(
          title: const Text('Attendance Management System',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

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
            child: getViewAttendanceWidget()
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
          title: const Text('Attendance Management System',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: getLeaveRequestWidget(),
        ),
        bottomNavigationBar: getBottomNavigationBar(),
      ),




      Scaffold(
        appBar: AppBar(
          title: const Text('Attendance Management System',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: () async {
                DateTime dt = DateTime.parse('${gradingMonthYear[0]}-${gradingMonthYear[1]}-01 00:00:00');
                final selected = await showMonthYearPicker(
                  context: context,
                  initialDate: dt,
                  firstDate: DateTime(2019),
                  lastDate: DateTime(2023),
                );
                if (selected != null) {
                  setState(() {
                    gradingMonthYear[0] = selected.year.toString();
                    gradingMonthYear[1] = zeros(selected.month.toString());
                    // showToast(zeros(selected.month.toString()) + " " + selected.year.toString());
                  });
                }
              },
            ),
          ],
        ),
        body: Center(
          child: getGradingWidget(),
        ),
        bottomNavigationBar: getBottomNavigationBar(),
      ),




      Scaffold(
        appBar: AppBar(
          title: const Text('Attendance Management System',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: initialCameraPosition,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
        ),
        bottomNavigationBar: getBottomNavigationBar(),
      ),



    ];


    return widgetOptions[_selectedIndex];
  }


  getGradingWidget(){
    if (gradingList.isEmpty){
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
            Flexible(
              child: ListView.builder(
                itemCount: gradingList.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    shadowColor: Colors.grey.shade300,
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(gradingList[index].username[0]),
                      ),
                      title: Text(
                        gradingList[index].username,
                      ),
                      subtitle: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        // crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            "Present: ${gradingList[index].present}",
                          ),
                          Text(
                            "Absent: ${gradingList[index].absent}",
                          ),
                          Text(
                            "Leave: ${gradingList[index].leave}",
                          ),
                        ],
                      ),
                      trailing: Text("Grade: ${gradingList[index].grade}"),
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
    if (searchWithDateList.isEmpty){
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
                      trailing: Padding(
                        padding: const EdgeInsets.only(right: 30.0),
                        child: SizedBox(
                          width: 100,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            direction: Axis.vertical,
                            runSpacing: 20,
                            children: [
                              DropdownButton<String>(
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
                              InkWell(
                                  onTap: () {
                                    _deleteAttendanceDialog(index);
                                  },
                                  child: const Icon(
                                    Icons.delete,
                                    size: 30,
                                  )
                              ),
                            ],
                          ),
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

  getLeaveRequestWidget(){
    if (leaveRequestList.isEmpty){
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
                itemCount: leaveRequestList.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    shadowColor: Colors.grey.shade300,
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(leaveRequestList[index].username[0]),
                      ),
                      title: Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Text(leaveRequestList[index].username),
                      ),
                      subtitle: Column (
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Text(leaveRequestList[index].date),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                              child: Text(leaveRequestList[index].reason),
                            ),
                          ]
                      ),
                      trailing: SizedBox(
                        width: 100,
                        child: Row(
                          children: [
                            IconButton(onPressed: () {
                              FirebaseDatabase.instance.ref("UserInfo").child(leaveRequestList[index].username).child("LeaveRequest-${leaveRequestList[index].date}").remove();
                              FirebaseDatabase.instance.ref("UserInfo").child(leaveRequestList[index].username).child("LeaveRejected-${leaveRequestList[index].date}").set(leaveRequestList[index].reason);
                              setState(() {
                                leaveRequestList.removeAt(index);
                              });
                              showToast("Leave Rejected");
                            }, icon: const Icon(Icons.close)),
                            IconButton(onPressed: () {
                              FirebaseDatabase.instance.ref("UserInfo").child(leaveRequestList[index].username).child("LeaveRequest-${leaveRequestList[index].date}").remove();
                              FirebaseDatabase.instance.ref("UserInfo").child(leaveRequestList[index].username).child("LeaveAccepted-${leaveRequestList[index].date}").set(leaveRequestList[index].reason);
                              FirebaseDatabase.instance.ref("UserInfo").child(leaveRequestList[index].username).child("Attendance-${leaveRequestList[index].date}").set("Leave");
                              setState(() {
                                leaveRequestList.removeAt(index);
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
      type: BottomNavigationBarType.fixed,
      items: <BottomNavigationBarItem>[
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'View Attendance',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            children: <Widget>[
              const Icon(Icons.approval),
              Positioned(
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  child: Text(
                    leaveRequestList.length.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            ],
          ),
          label: 'Leave Approvals',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.grading),
          label: 'Grading',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.location_pin),
          label: 'Location',
        ),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.amber[800],
      onTap: _onItemTapped,
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
        if (e2.key.startsWith("Attendance-")) {
          userAttendanceList.add(UserAttendance(
              "", e.parent, e2.key.replaceFirst("Attendance-", ""), e2.value));
        }
      }
    }
  }
}


