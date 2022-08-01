import 'package:attendance_management_system/login_1.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          useMaterial3: true,
          textTheme: GoogleFonts.poppinsTextTheme()),
      debugShowCheckedModeBanner: false,
      home: const LoginPageOne(),
    );
  }
}