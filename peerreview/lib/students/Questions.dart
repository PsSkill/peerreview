import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
 import 'package:peerreview/config.dart';

class QuestionsScreen extends StatefulWidget {
  final Function navigateToDataEntryScreen;

  const QuestionsScreen({Key? key, required this.navigateToDataEntryScreen})
      : super(key: key);

  @override
  _QuestionsScreenState createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  List<dynamic> assignments = [];
  dynamic selectedAssignment;
  List<dynamic> taskDetails = [];
  int currentTaskIndex = 0;
  int timeRemaining = 0;
  bool loading = true;
  int step = 1; // 1 = Browsing, 2 = Speaking

  @override
  void initState() {
    super.initState();
    fetchAssignments();
  }

  Future<void> fetchAssignments() async {
    try {
      final response = await fetch('$apiBaseUrl/api/assignment');
      final data = json.decode(response.body);
      setState(() {
        assignments = data;
        loading = false;
      });
    } catch (error) {
      print('Error fetching assignments: $error');
      setState(() {
        loading = false;
      });
    }
  }

  int extractMinutes(String timeString) {
    final match = RegExp(r'\d+').firstMatch(timeString);
    return match != null ? int.parse(match.group(0)!) * 60 : 0; // Convert to seconds
  }

  void selectAssignment(dynamic assignment) {
    setState(() {
      selectedAssignment = assignment;
      taskDetails = List.from(json.decode(assignment['task_details']));
      currentTaskIndex = 0;
      step = 1;
      timeRemaining = extractMinutes(taskDetails[0]['task_time']);
    });
  }

  late Timer _timer;

  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (timeRemaining > 0) {
        setState(() {
          timeRemaining--;
        });
      } else {
        _timer.cancel();
      }
    });
  }

  String formatTime(int timeInSeconds) {
    final minutes = (timeInSeconds / 60).floor();
    final seconds = timeInSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void handleNext() {
    if (step == 1) {
      // Move from Browsing to Speaking for the current task
      setState(() {
        step = 2;
        timeRemaining = extractMinutes(taskDetails[currentTaskIndex]['task_time']);
      });
      startTimer();
    } else if (step == 2) {
      // Move to the next task or finish
      if (currentTaskIndex < taskDetails.length - 1) {
        setState(() {
          currentTaskIndex++;
          step = 1;
          timeRemaining = extractMinutes(taskDetails[currentTaskIndex]['task_time']);
        });
        startTimer();
      } else {
        // All tasks completed, navigate to next screen
        widget.navigateToDataEntryScreen();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text('Loading assignments...'),
            ],
          ),
        ),
      );
    }

    if (selectedAssignment == null) {
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Select an Assignment',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: assignments.length,
                  itemBuilder: (context, index) {
                    final assignment = assignments[index];
                    return GestureDetector(
                      onTap: () => selectAssignment(assignment),
                      child: Card(
                        color: const Color(0xFF3498db),
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Text(
                            assignment['title'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text(
              'Assignment: ${selectedAssignment['title']}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      step == 1 ? 'Browsing Time' : 'Speaking Time',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      formatTime(timeRemaining),
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFFE74C3C)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task ${currentTaskIndex + 1}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      taskDetails[currentTaskIndex]['task_title'] ?? 'No Task Available',
                      style: const TextStyle(fontSize: 16, color: Color(0xFF555)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              step == 1 ? 'Use your browsing time wisely.' : 'Explain your findings clearly.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: handleNext,
              child: Text(
                step == 1
                    ? 'Next: Speaking Time'
                    : currentTaskIndex < taskDetails.length - 1
                        ? 'Next Task'
                        : 'Finish',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
