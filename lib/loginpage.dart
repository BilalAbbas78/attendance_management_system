// ignore_for_file: use_build_context_synchronously

import 'package:attendance_management_system/adminpage.dart';
import 'package:attendance_management_system/userpage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  static TextEditingController txtUsername = TextEditingController();
  static TextEditingController txtPassword = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  static FocusNode txtUsernameFocusNode = FocusNode();

  static String todayDate = DateTime.now().toString().substring(0, 10).split("-").reversed.join("-");

  Future<bool> initialize() async {
    final database = await FirebaseDatabase.instance
        .ref()
        .child("UserInfo")
        .once();
    for (var element in database.snapshot.children) {
      if (!element.child("Attendance-$todayDate").exists) {
        FirebaseDatabase.instance.ref().child("UserInfo").child(element.key.toString()).child("Attendance-$todayDate").set("Absent");
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // FocusScope.of(context).requestFocus(txtUsernameFocusNode);
    initialize();

    return Theme(
      data: ThemeData(
          textTheme: GoogleFonts.poppinsTextTheme(),
          useMaterial3: true),
      child: Scaffold(
        body: Container(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Padding(
                      padding: EdgeInsets.only(top: 30.0),
                      child: Text(
                        'Attendance Management System',
                        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 30,
                ),
                const Text(
                  'Sign in',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 14,
                ),
                const Text(
                  'Please sign in to continue',
                ),
                const SizedBox(
                  height: 40,
                ),
                TextFormField(
                  controller: txtUsername,
                  focusNode: txtUsernameFocusNode,
                  // autofocus: true,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Please enter a username";
                    } else {
                      return null;
                    }
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                      borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.tertiary),
                    ),
                    fillColor: Colors.lightBlue,
                    labelText: 'Username',
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                TextFormField(
                  controller: txtPassword,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Please enter a password";
                    } else {
                      return null;
                    }
                  },
                  obscureText: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    labelText: 'Password',
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => signUp(context),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: const [
                            Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Icon(
                                Icons.arrow_circle_left,
                              ),
                            ),
                            Text(
                              'Sign Up',
                            )
                          ],
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 28),
                      ),
                      onPressed: () => signIn(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Row(
                            children: const [
                              Text(
                                'Continue',
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 0),
                                child: Icon(
                                  Icons.arrow_right_alt_rounded,
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  void signUp(BuildContext context) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("UserInfo/${txtUsername.text}");
    var sp = await ref.once();

    if (_formKey.currentState!.validate()) {
      if (sp.snapshot.value == null) {
        await ref.set({
          "password": txtPassword.text,
        });
        showToast("Account created successfully");
        FirebaseDatabase.instance.ref().child("UserInfo").child(txtUsername.text).child("Attendance-$todayDate").set("Absent");
        FocusScope.of(context).requestFocus(txtUsernameFocusNode);
        gotoUserPage(context);
        // txtUsername.clear();
        // txtPassword.clear();
        // txtUsername.focus
      } else {
        showToast("Account with this username already exists");
      }
    }
  }

  void signIn(BuildContext context) async {

    DatabaseReference ref = FirebaseDatabase.instance.ref("UserInfo/${txtUsername.text}");
    var sp = await ref.once();

    if (_formKey.currentState!.validate()){
      if (txtUsername.text == "admin" && txtPassword.text == "admin") {
        FocusScope.of(context).requestFocus(txtUsernameFocusNode);
        gotoAdminPage(context);
      }
      else if (sp.snapshot.child("password").value == txtPassword.text) {
        FocusScope.of(context).requestFocus(txtUsernameFocusNode);
        gotoUserPage(context);
      }
      else {
        showToast("Incorrect username or password");
      }
    }
  }

  Future<void> gotoAdminPage(BuildContext context) async {
    Navigator.push(context,
      MaterialPageRoute(builder: (context) => const AdminPage()),);

    // bool focus = await Navigator.of(context).push(MaterialPageRoute(builder: (_)=> AdminPage()));
    // if (focus == true){
    //
    //   FocusScope.of(context).requestFocus(txtUsernameFocusNode);
    //
    // }

  }

  void gotoUserPage(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => UserPage(strUsername: txtUsername.text)));
  }

  void showToast(String str){
    Fluttertoast.showToast(
      msg: str,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }
}