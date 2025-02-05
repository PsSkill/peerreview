import 'package:flutter/material.dart';
import 'package:peerreview/students/Result.dart';
import 'package:peerreview/Admin/CreateAssignment.dart';
import 'package:peerreview/Admin/DetailPage.dart';
import 'package:peerreview/Admin/adminDashboard.dart';
import 'package:peerreview/LoginScreen.dart';
import 'package:peerreview/Loginstudent.dart';
import 'package:peerreview/students/Questions.dart';

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
        '/questions': (context) => QuestionsScreen(),
        '/resultScreen': (context) => ResultScreen(),
        '/ranking': (context) => RankAssignmentScreen(),
        '/attendance': (context) => AttendanceScreen(),
      },
    );
  }
}
