import 'package:attendance_management_system/loginpage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:month_year_picker/month_year_picker.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        MonthYearPickerLocalizations.delegate,
      ],
      theme: ThemeData(
          useMaterial3: true,
          textTheme: GoogleFonts.poppinsTextTheme()
      ),
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
    );
  }
}