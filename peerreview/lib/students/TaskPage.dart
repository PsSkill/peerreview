import 'package:flutter/material.dart';
import 'package:peerreview/students/StudentDashboard.dart';
import 'AssignmentDetailPage.dart';  // Make sure this path is correct based on your file structure
import 'dart:async'; // For Timer
import 'package:peerreview/students/assignment.dart'; // Import the common Assignment class


class TaskPage extends StatefulWidget {
  final Assignment assignment;

  TaskPage({required this.assignment});

  @override
  _TaskPageState createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  late int remainingTime;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    remainingTime = int.parse(widget.assignment.totalTime) * 60; // Convert minutes to seconds

    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingTime > 0) {
        setState(() {
          remainingTime--;
        });
      } else {
        timer.cancel();
        _showTimeUpDialog();
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Time Up!'),
        content: Text('The time for this task has ended.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('OK')),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Task Page'), backgroundColor: Colors.blueAccent),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Task Name: ${widget.assignment.taskDetails}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Text('Remaining Time:', style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Center(
              child: Text(
                _formatTime(remainingTime),
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
