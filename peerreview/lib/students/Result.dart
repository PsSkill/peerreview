import 'package:flutter/material.dart';
 import 'package:peerreview/config.dart';

class ResultScreen extends StatelessWidget {
  final int score;
  final bool isEligible;

  ResultScreen({required this.score, required this.isEligible});

  @override
  Widget build(BuildContext context) {
    final resultStatus = isEligible ? 'Eligible' : 'Failed';

    // Function to navigate back to StudentDashboard
    void handleGoBack() {
      Navigator.pop(context, resultStatus);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Result"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Result',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Your Score: $score/40',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            SizedBox(height: 10),
            Text(
              isEligible
                  ? 'Congratulations! You are eligible for the next level.'
                  : 'You are not eligible for the next level. Try again!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: handleGoBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                textStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Go Back to Dashboard',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
