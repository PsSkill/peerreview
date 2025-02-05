import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RankAssignmentScreen extends StatefulWidget {
  @override
  _RankAssignmentScreenState createState() => _RankAssignmentScreenState();
}

class _RankAssignmentScreenState extends State<RankAssignmentScreen> {
  List<Task> tasks = [];
  List<Student> students = [];
  Map<int, Map<int, int>> rankings = {}; // {task_id: {ranked_student_id: rank_given}}
  int totalStudents = 0;
  int numberOfTasks = 0;

  @override
  void initState() {
    super.initState();
    fetchAssignmentDetails();
    fetchStudentDetails();
  }

  // Fetch Assignment Details
  Future<void> fetchAssignmentDetails() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.168.45:5001/api/assignments'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body)[0]; // First assignment
        setState(() {
          totalStudents = data['number_of_students'];
          numberOfTasks = data['numberoftasks'];
          tasks = List<Task>.from(json.decode(data['task_details']).map((task) => Task.fromJson(task)));
        });
      } else {
        throw Exception('Failed to load assignment details');
      }
    } catch (e) {
      print('Error fetching assignment details: $e');
    }
  }

  // Fetch Student Details
  Future<void> fetchStudentDetails() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.168.45:5000/api/student'));
      if (response.statusCode == 200) {
        setState(() {
          students = List<Student>.from(json.decode(response.body).map((json) => Student.fromJson(json)));
        });
      } else {
        throw Exception('Failed to load student details');
      }
    } catch (e) {
      print('Error fetching student details: $e');
    }
  }

  // Store Rankings in API
  Future<void> submitRankings() async {
    for (var task in tasks) {
      rankings[task.taskId]?.forEach((rankedStudentId, rankGiven) async {
        final response = await http.post(
          Uri.parse('http://192.168.168.45:5002/api/rank'),
          headers: {"Content-Type": "application/json"},
          body: json.encode({
            "ranker_id": 1, // Assume logged-in student's ID
            "ranked_student_id": rankedStudentId,
            "task_id": task.taskId,
            "rank_given": rankGiven,
          }),
        );

        if (response.statusCode != 200) {
          print("Failed to submit ranking for student $rankedStudentId");
        }
      });
    }

    calculateResults();
  }

  // Calculate Total Points & Store Result
  Future<void> calculateResults() async {
    Map<int, int> studentTotalPoints = {};
    for (var student in students) {
      studentTotalPoints[student.facultyId] = 0;
    }

    // Assign Points Based on Ranking
    for (var task in tasks) {
      var taskRankings = rankings[task.taskId] ?? {};
      var sortedRanks = taskRankings.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value)); // Sort by rank

      for (var i = 0; i < sortedRanks.length; i++) {
        int studentId = sortedRanks[i].key;
        int rank = sortedRanks[i].value;

        if (rank == 1) studentTotalPoints[studentId] = (studentTotalPoints[studentId] ?? 0) + 4;
        else if (rank == 2) studentTotalPoints[studentId] = (studentTotalPoints[studentId] ?? 0) + 3;
        else if (rank == 3) studentTotalPoints[studentId] = (studentTotalPoints[studentId] ?? 0) + 2;
        else if (rank == 4) studentTotalPoints[studentId] = (studentTotalPoints[studentId] ?? 0) + 1;
        else studentTotalPoints[studentId] = (studentTotalPoints[studentId] ?? 0) + 0;
      }
    }

    // Calculate Average Points
    int totalPoints = studentTotalPoints.values.reduce((a, b) => a + b);
    double averagePoints = totalPoints / totalStudents;

    // Store Results in API
    for (var student in students) {
      int studentPoints = studentTotalPoints[student.facultyId] ?? 0;
      String resultStatus = (studentPoints >= (0.5 * averagePoints)) ? "pass" : "fail";

      final response = await http.post(
        Uri.parse('http://192.168.168.45:5002/api/result'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "student_id": student.facultyId,
          "total_points": studentPoints,
          "average_points": averagePoints,
          "result_status": resultStatus,
        }),
      );

      if (response.statusCode != 200) {
        print("Failed to submit result for student ${student.facultyId}");
      }
    }

    // Show final result message
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Ranking Completed"),
        content: Text("Results have been saved successfully!"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Rank Assignment')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tasks:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ...tasks.map((task) => ListTile(title: Text(task.taskTitle), subtitle: Text('Duration: ${task.taskTime}'))),
            SizedBox(height: 20),
            Text('Rank Students:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ...students.map((student) => RankInputCard(
                  student: student,
                  onRankChanged: (taskId, rank) {
                    setState(() {
                      rankings[taskId] ??= {};
                      rankings[taskId]![student.facultyId] = rank;
                    });
                  },
                )),
            SizedBox(height: 20),
            ElevatedButton(onPressed: submitRankings, child: Text('Submit Ranking')),
          ],
        ),
      ),
    );
  }
}

// Rank Input Card
class RankInputCard extends StatelessWidget {
  final Student student;
  final Function(int, int) onRankChanged;

  RankInputCard({required this.student, required this.onRankChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      elevation: 3,
      child: ListTile(
        title: Text(student.name),
        subtitle: Row(
          children: List.generate(5, (index) {
            int rank = index + 1;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ElevatedButton(
                onPressed: () => onRankChanged(1, rank), // Assume task_id = 1
                child: Text('$rank'),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// Task Model
class Task {
  final int taskId;
  final String taskTitle;
  final String taskTime;

  Task({required this.taskId, required this.taskTitle, required this.taskTime});

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(taskId: json['task_id'], taskTitle: json['task_title'], taskTime: json['task_time']);
  }
}

// Student Model
class Student {
  final int facultyId;
  final String emailId;
  String get name => emailId.split('@')[0];

  Student({required this.facultyId, required this.emailId});

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(facultyId: json['facultyId'], emailId: json['emailId']);
  }
}
