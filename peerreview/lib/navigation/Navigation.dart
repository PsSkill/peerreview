import 'package:flutter/material.dart';
import 'package:peerreview/students/Result.dart';
import 'package:peerreview/Admin/CreateAssignment.dart';
import 'package:peerreview/Admin/DetailPage.dart';
import 'package:peerreview/Admin/adminDashboard.dart';
import 'package:peerreview/LoginScreen.dart';
import 'package:peerreview/Loginstudent.dart';
import 'package:peerreview/students/Questions.dart';
import 'package:peerreview/students/RankAssignmentScreen.dart'; // Add this line
// import 'package:peerreview/students/AttendanceScreen.dart'; // Add this line

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      initialRoute: '/studentLogin', // Set initial route here
      routes: {
        '/admin': (context) => AdminScreen(),
        '/login': (context) => LoginScreen(),
        '/studentDashboard': (context) => StudentDashboard(),
        '/studentLogin': (context) => LoginScreenStudents(),
        '/createAssignment': (context) => CreateAssignment(),
        '/detailPage': (context) => DetailPage(assignment: {}), 
        '/questions': (context) => QuestionsScreen(navigateToDataEntryScreen: (data) {
          // Add your navigation logic here
        }),
        '/resultScreen': (context) => ResultScreen(score: 0, isEligible: false),
        '/ranking': (context) => RankAssignmentScreen(),
        // '/attendance': (context) => AttendanceScreen(),
      },
    );
  }
}
