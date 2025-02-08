import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
 import 'package:peerreview/config.dart';

class StudentDashboard extends StatefulWidget {
  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  List<dynamic> assignments = [];
  String? userName;
  List<String> assignmentTitles = [];
  List<String> questions = [];
  bool isLoading = true;
  List<String?> selectedTitles = [];
  List<List<String?>> rankAssignments = [];
  List<String> studentNames = [];
  int _start = 10;
  Timer? _timer;

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // fetchAssignments(); // This method is not defined in this class
    fetchUserName();
  }

  Future<void> fetchAssignments() async {
  final url = Uri.parse("$apiBaseUrl/api/assignments");

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      int numberOfTasks = data["numberoftasks"] ?? 5;
      int numberOfStudents = data["number_of_students"] ?? 5; // Get the student count
      List<String> titles = (data["assignments"] as List<dynamic>)
          .map((assignment) => assignment["title"].toString())
          .toList();

      if (numberOfTasks == 0 || titles.isEmpty) {
        throw Exception("No tasks or titles found.");
      }

      // Fetch student names dynamically
      List<String> students = await fetchStudentNames(numberOfStudents);

      setState(() {
        questions = List.generate(numberOfTasks,
            (index) => "Who is the most suitable for Task ${index + 1}?");
        assignmentTitles = titles;
        selectedTitles = List.filled(numberOfTasks, null);
        rankAssignments =
            List.generate(numberOfTasks, (_) => List.filled(numberOfStudents, null));
        studentNames.clear();
        studentNames.addAll(students);
        isLoading = false;
      });

      startTimer();
    } else {
      throw Exception("Failed to load data");
    }
  } catch (e) {
    print("Error fetching tasks: $e");
    setState(() {
      questions = List.generate(
          5, (index) => "Who is the most suitable for Task ${index + 1}?");
      assignmentTitles = ["Default Assignment 1", "Default Assignment 2"];
      selectedTitles = List.filled(5, null);
      rankAssignments = List.generate(5, (_) => List.filled(5, null));
      studentNames = ["Default Student 1", "Default Student 2"];
      isLoading = false;
    });
  }
}
Future<List<String>> fetchStudentNames(int count) async {
  final url = Uri.parse("$apiBaseUrl/api/student");

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> students = json.decode(response.body);

      // Extract faculty IDs and email IDs
      List<String> studentList = students
          .take(count) // Get only required number of students
          .map((student) => student["emailId"].toString()) // Use email as name
          .toList();

      return studentList;
    } else {
      throw Exception("Failed to fetch student names.");
    }
  } catch (e) {
    print("Error fetching student names: $e");
    return ["Default Student"];
  }
}


  // Fetch user name from the API
  Future<void> fetchUserName() async {
    try {
      final response =
          await http.get(Uri.parse('$apiBaseUrl/api/student'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userName = data['name'];
        });
      } else {
        throw Exception('Failed to load user details');
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  void navigateToAssignmentDetails(Map<String, dynamic> assignment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignmentDetailsPage(assignment: assignment),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Dashboard'),
        backgroundColor: Color(0xFF2b4f87),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              userName != null ? 'WELCOME $userName' : 'WELCOME',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2b4f87),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: assignments.length,
                itemBuilder: (context, index) {
                  final assignment = assignments[index];
                  return TitleCard(
                    title: assignment['title'],
                    date: assignment['date'],
                    time: assignment['start_time'],
                    buttonText: 'View Details',
                    onPress: () => navigateToAssignmentDetails(assignment),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TitleCard extends StatelessWidget {
  final String title;
  final String date;
  final String time;
  final String buttonText;
  final VoidCallback onPress;

  TitleCard({
    required this.title,
    required this.date,
    required this.time,
    required this.buttonText,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      elevation: 3,
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: $date'),
            Text('Start Time: $time'),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: onPress,
          child: Text(buttonText),
        ),
      ),
    );
  }
}

class AssignmentDetailsPage extends StatefulWidget {
  final Map<String, dynamic> assignment;

  AssignmentDetailsPage({required this.assignment});

  @override
  _AssignmentDetailsPageState createState() => _AssignmentDetailsPageState();
}

class _AssignmentDetailsPageState extends State<AssignmentDetailsPage> {
  late List<dynamic> taskDetails;
  int currentTaskIndex = 0;
  bool isTaskStarted = false;
  late Timer taskTimer = Timer.periodic(Duration(seconds: 1), (timer) {});
  int remainingTime = 0;

  // Track completed tasks
  List<bool> taskCompletionStatus = [];

  @override
  void initState() {
    super.initState();
    taskDetails =
        jsonDecode(widget.assignment['task_details']); // Decode JSON string
    taskCompletionStatus = List.generate(taskDetails.length,
        (index) => false); // Initialize all tasks as not completed
  }

  // Start the task timer
  void _startTask() {
    if (currentTaskIndex < taskDetails.length) {
      setState(() {
        isTaskStarted = true;
        remainingTime = _parseTime(
            taskDetails[currentTaskIndex]['task_time']); // Convert to seconds
      });

      // Cancel existing timer before starting a new one
      taskTimer.cancel();

      // Timer updates every second
      taskTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          if (remainingTime > 0) {
            remainingTime--; // Reduce time by 1 second
          } else {
            // Mark task as completed
            taskCompletionStatus[currentTaskIndex] = true;

            // Move to the next task
            if (currentTaskIndex < taskDetails.length - 1) {
              currentTaskIndex++;
              remainingTime =
                  _parseTime(taskDetails[currentTaskIndex]['task_time']);
            } else {
              // All tasks completed, stop the timer
              taskTimer.cancel();
              isTaskStarted = false;
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text("Task Completed"),
                    content: Text("You have completed all tasks."),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RankAssignmentScreen(
                                taskDetails:
                                    taskDetails, // Pass the task details list
                                onSubmit: (score, isEligible) {
                                  print('Score: $score, Eligible: $isEligible');
                                },
                              ),
                            ),
                          );
                        },
                        child: Text("OK"),
                      ),
                    ],
                  );
                },
              );
            }
          }
        });
      });
    }
  }

  // Helper function to parse the time (e.g., "5 min" or "10 sec")
  int _parseTime(String timeString) {
    final timeRegExp = RegExp(r'(\d+)'); // Extract digits
    final match = timeRegExp.firstMatch(timeString);

    if (match != null) {
      int value = int.parse(match.group(0)!);

      // Check if the string contains 'min' or 'sec' and convert accordingly
      if (timeString.contains('min')) {
        return value * 60; // Convert minutes to seconds
      } else {
        return value; // Return as is if already in seconds
      }
    }

    return 0; // Default return 0 if parsing fails
  }

  @override
  void dispose() {
    taskTimer.cancel();
    super.dispose();
  }

  // Show terms and conditions dialog
  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Terms and Conditions"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("1. No backward option is enabled."),
              Text("2. Copy-paste is disabled."),
              Text("3. No switching tabs."),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                print("User disagreed.");
              },
              child: Text("Disagree"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                _startTask(); // Start the task if the user agrees
                print("User agreed.");
              },
              child: Text("Agree"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assignment['title']),
        backgroundColor: Color(0xFF2b4f87),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailCard(
                title: 'Assignment Details',
                children: [
                  _buildDetailRow('Date', widget.assignment['date']),
                  _buildDetailRow(
                      'Start Time', widget.assignment['start_time']),
                  _buildDetailRow('Stop Time', widget.assignment['stop_time']),
                  _buildDetailRow(
                      'Total Time', widget.assignment['total_time']),
                ],
              ),
              SizedBox(height: 10),
              _buildDetailCard(
                title: 'Explanation',
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      widget.assignment['explanation'],
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              _buildDetailCard(
                title: 'Tasks',
                showTimer: true, // Show live timer inside this card
                children: taskDetails.map((task) {
                  int taskIndex = taskDetails.indexOf(task);
                  bool isCompleted = taskCompletionStatus[taskIndex];
                  return TaskCard(
                    taskTitle: task['task_title'],
                    taskTime: task['task_time'],
                    remainingTime: remainingTime, // Show decreasing time
                    isTaskCompleted: isCompleted,
                  );
                }).toList(),
              ),

              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed:
                      _showTermsAndConditions, // Calls the method to show the dialog
                  child: Text('Start Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 191, 209, 238),
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    textStyle:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Display remaining time only at the bottom
              if (isTaskStarted)
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RankAssignmentScreen(
                          taskDetails:
                              taskDetails, // Pass the task details list
                          onSubmit: (score, isEligible) {
                            print('Score: $score, Eligible: $isEligible');
                          },
                        ),
                      ),
                    );
                  },
                  child: Text('Go to Rankings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    textStyle:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a detailed card widget with a title and a list of child widgets.
  ///
  /// The card includes an optional timer display if [showTimer] is true and
  /// the task is started. The timer shows a countdown in seconds, changing
  /// color to red when time is low.
  ///
  /// Parameters:
  /// - [title]: The title text displayed at the top of the card.
  /// - [children]: A list of widgets to be displayed inside the card.
  /// - [showTimer]: A boolean indicating whether to show a timer, default is false.
  Widget _buildDetailCard(
      {required String title,
      required List<Widget> children,
      bool showTimer = false}) {
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (showTimer && isTaskStarted) // Show timer when task starts
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'Timer: $remainingTime sec', // Show live countdown in seconds
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: remainingTime <= 10 ? Colors.red : Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
            Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final String taskTitle;
  final String taskTime;
  final int remainingTime;
  final bool isTaskCompleted; // Add a flag for completion

  TaskCard({
    required this.taskTitle,
    required this.taskTime,
    required this.remainingTime,
    required this.isTaskCompleted, // Add a flag for completion
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: isTaskCompleted
          ? Colors.green
          : Colors.white, // Change color based on completion status
      child: ListTile(
        contentPadding: EdgeInsets.all(10),
        title: Text(
          taskTitle,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Task Time: $taskTime'),
      ),
    );
  }
}

class RankAssignmentScreen extends StatefulWidget {
  final Function(int score, bool isEligible) onSubmit;

  RankAssignmentScreen({required this.taskDetails, required this.onSubmit});

  final List<dynamic> taskDetails;

  @override
  _RankAssignmentScreenState createState() => _RankAssignmentScreenState();
}

class _RankAssignmentScreenState extends State<RankAssignmentScreen> {
  List<String> questions = [];
  List<String> assignmentTitles = [];
  List<String?> selectedTitles = [];
  final List<String> studentNames = [
    "Student A",
    "Student B",
    "Student C",
    "Student D",
    "Student E"
  ];

  List<List<String?>> rankAssignments = [];
  int currentQuestionIndex = 0;
  int timer = 30;
  Timer? countdownTimer;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAssignments(); // This method is not defined in this class
  }

  Future<void> postRankings() async {
  final url = Uri.parse("$apiBaseUrl/api/rank");

  List<String> taskIds = widget.taskDetails.map((task) => task['id'].toString()).toList();

  for (int i = 0; i < taskIds.length; i++) {
    String? facultyId = selectedTitles[i]; // The entered faculty ID
    if (facultyId == null || facultyId.isEmpty) continue;

    Map<String, dynamic> rankData = {
      "assignment_id": taskIds[i], // Use the corresponding task ID
      "faculty_id": facultyId,
      "task_number": i + 1,
      "rank_1": rankAssignments[i][0] ?? "",
      "rank_2": rankAssignments[i][1] ?? "",
      "rank_3": rankAssignments[i][2] ?? "",
      "rank_4": rankAssignments[i][3] ?? "",
      "rank_5": rankAssignments[i][4] ?? "",
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(rankData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Ranking submitted successfully for Task ${i + 1}");
      } else {
        print("Failed to submit ranking for Task ${i + 1}");
      }
    } catch (e) {
      print("Error submitting ranking: $e");
    }
  }
}

void handleSubmit() async {
  await postRankings();

  int score = (20 + (20 * (currentQuestionIndex / questions.length))).toInt();
  bool isEligible = score >= 20;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ResultScreen(score: score, isEligible: isEligible),
    ),
  );
}

  void startTimer() {
    countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (this.timer == 0) {
        goToNextQuestion();
      } else {
        setState(() {
          this.timer--;
        });
      }
    });
  }

  void goToNextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        timer = 30;
      });
    } else {
      handleSubmit();
    }
  }

  void submitRankings() {
    int score = (20 + (20 * (currentQuestionIndex / questions.length))).toInt();
    bool isEligible = score >= 20;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ResultScreen(score: score, isEligible: isEligible),
      ),
    );
  }

  void showStudentPicker(BuildContext context, int rankIndex) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return Container(
          padding: EdgeInsets.all(10),
          child: ListView.builder(
            itemCount: studentNames.length,
            itemBuilder: (ctx, index) {
              return ListTile(
                title: Text(studentNames[index]),
                onTap: () {
                  setState(() {
                    rankAssignments[currentQuestionIndex][rankIndex] =
                        studentNames[index];
                  });
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Rank Assignment"),
        backgroundColor: Color(0xFF2b4f87),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : questions.isEmpty
              ? Center(child: Text("No tasks available"))
              : Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      Text(
                        questions[currentQuestionIndex],
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Enter   ID:",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "Enter Faculty ID",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            selectedTitles[currentQuestionIndex] =
                                value; // Store entered faculty ID
                          });
                        },
                      ),
                      ElevatedButton(
                        onPressed: () => validateId(
                            context, currentQuestionIndex, selectedTitles),
                        child: Text("Validate  ID"),
                      ),
                      SizedBox(height: 20),
                     Column(
  children: List.generate(5, (rankIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => showStudentPicker(context, rankIndex),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.blue),
              ),
              child: Text(
                rankAssignments[currentQuestionIndex][rankIndex] ?? "Select a student",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
          ),
          SizedBox(width: 20),
          Text(
            "Rank ${rankIndex + 1}",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }),
),

                      SizedBox(height: 20),
Center(
  child: ElevatedButton(
    onPressed: goToNextQuestion,
    child: Text(
      currentQuestionIndex < questions.length - 1
          ? "Next Question"
          : "Submit Assignments",
      style: TextStyle(fontSize: 18),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blueAccent,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    ),
  ),
                          )        ],
        ),
      ),
    );
  }
  
  void fetchAssignments() {}
}

class ResultScreen extends StatelessWidget {
  final int score;
  final bool isEligible;

  ResultScreen({required this.score, required this.isEligible});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Result"),
        backgroundColor: Color(0xFF2b4f87),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Your Score: $score",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              isEligible ? "You are eligible!" : "You are not eligible",
              style: TextStyle(
                  fontSize: 20, color: isEligible ? Colors.green : Colors.red),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Back to Home"),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> validateId(BuildContext context, int currentQuestionIndex,
    List<String?> selectedTitles) async {
  String? facultyId = selectedTitles[currentQuestionIndex];

  if (facultyId == null || facultyId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Please enter a  ID."),
    ));
    return;
  }

  final url =
      Uri.parse("$apiBaseUrl/api/student?facultyId=$facultyId");

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(" ID is valid!"),
          backgroundColor: Colors.green,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Invalid  ID."),
          backgroundColor: Colors.red,
        ));
      }
    } else {
      throw Exception("Failed to validate  ID.");
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Error: $e"),
      backgroundColor: Colors.red,
    ));
  }
}
Future<void> fetchRankings() async {
  final url = Uri.parse("$apiBaseUrl/api/get_rankings");
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      calculateScores(data);
    } else {
      print("Failed to fetch rankings");
    }
  } catch (e) {
    print("Error fetching rankings: $e");
  }
}
void calculateScores(List<dynamic> rankings) {
  Map<String, int> studentScores = {};

  for (var entry in rankings) {
    String student = entry['student_name'];
    int rank = entry['rank'];

    // Assign points based on rank
    int points = 0;
    if (rank == 1) points = 4;
    else if (rank == 2) points = 3;
    else if (rank == 3) points = 2;
    else if (rank == 4) points = 1;
    else if (rank == 5) points = 0;

    // Add points to student score
    studentScores[student] = (studentScores[student] ?? 0) + points;
  }

  // Identify top 3 students
  List<MapEntry<String, int>> sortedStudents = studentScores.entries.toList();
  sortedStudents.sort((a, b) => b.value.compareTo(a.value));

  List<String> topThree = sortedStudents.take(3).map((e) => e.key).toList();

  // Penalize incorrect judges (if they placed a non-top-3 student in ranks 1-3)
  for (var entry in rankings) {
    String student = entry['student_name'];
    int rank = entry['rank'];
    if (rank <= 3 && !topThree.contains(student)) {
      studentScores[student] = (studentScores[student] ?? 0) - 2; // Negative points
    }
  }

  // Compute final results
    displayResults(studentScores);
  }
  
  void showResults(Map<String, int> studentScores) {
    // Implement your logic to display the results here
    studentScores.forEach((student, score) {
      print('Student: $student, Score: $score');
    });
}
void displayResults(Map<String, int> studentScores) {
  List<MapEntry<String, int>> sortedStudents = studentScores.entries.toList();
  sortedStudents.sort((a, b) => b.value.compareTo(a.value));

  int maxPossibleScore = 4 * studentScores.length; // Max points = 4 * num students

  print("Final Scores:");
  for (var entry in sortedStudents) {
    String student = entry.key;
    int score = entry.value;
    double percentage = (score / maxPossibleScore) * 100;

    bool passed = percentage >= 50;
    print("$student - Score: $score (${percentage.toStringAsFixed(2)}%) - ${passed ? "✅ Passed" : "❌ Failed"}");

    if (passed) {
      postResults(student, score, passed);
    }
  }
}

Future<void> submitResults(String student, int score, bool passed) async {
  final url = Uri.parse("$apiBaseUrl/api/results");
  final resultData = {
    "student": student,
    "score": score,
    "passed": passed,
  };

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode(resultData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("Results posted successfully for $student");
    } else {
      print("Failed to post results for $student");
    }
  } catch (e) {
    print("Error posting results: $e");
  }
}

Future<void> postResults(String student, int score, bool passed) async {
  final url = Uri.parse("$apiBaseUrl/api/post_results");

  Map<String, dynamic> resultData = {
    "student_name": student,
    "score": score,
    "status": passed ? "Passed" : "Failed",
  };

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode(resultData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("Result posted successfully for $student");
    } else {
      print("Failed to post result for $student");
    }
  } catch (e) {
    print("Error posting result: $e");
  }
}
