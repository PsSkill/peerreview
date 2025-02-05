import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TaskPage extends StatefulWidget {
  final String assignmentTitle;
  final Map<String, dynamic> taskDetails;
  final int taskTime; // Time in minutes

  TaskPage({
    required this.assignmentTitle,
    required this.taskDetails,
    required this.taskTime,
  });

  @override
  _TaskPageState createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  int remainingTime = 0; // Time in seconds
  Timer? taskTimer;
  String? question;

  @override
  void initState() {
    super.initState();
    remainingTime = widget.taskTime * 60; // Convert minutes to seconds
    fetchQuestion();
    startTimer();
  }

  // Fetch question based on assignment title
  Future<void> fetchQuestion() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.168.45:5000/api/questions'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Filter questions based on assignment title
        final filteredQuestions = data.where((q) => q['title'] == widget.assignmentTitle).toList();
        
        if (filteredQuestions.isNotEmpty) {
          setState(() {
            question = filteredQuestions[0]['question']; // Pick the first question
          });
        } else {
          setState(() {
            question = 'No question found for this task.';
          });
        }
      } else {
        throw Exception('Failed to load questions');
      }
    } catch (e) {
      setState(() {
        question = 'Error loading question.';
      });
      print('Error fetching questions: $e');
    }
  }

  // Start countdown timer
  void startTimer() {
    taskTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingTime > 0) {
        setState(() {
          remainingTime--;
        });
      } else {
        timer.cancel();
        showTaskCompletedDialog();
      }
    });
  }

  // Show task completion dialog
  void showTaskCompletedDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Time's Up!"),
          content: Text("You have completed the task."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Go back to assignment details
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    taskTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Task Page"),
        backgroundColor: Color(0xFF2b4f87),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Task: ${widget.taskDetails['task_title']}",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Question:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              question ?? 'Loading question...',
              style: TextStyle(fontSize: 16),
            ),
            Spacer(),
            Text(
              "Time Remaining: $remainingTime seconds",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: remainingTime <= 10 ? Colors.red : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
