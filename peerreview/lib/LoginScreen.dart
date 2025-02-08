import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'package:peerreview/Admin/adminDashboard.dart';
import 'package:peerreview/students/studentDashboard.dart' as student;
import 'package:peerreview/config.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController facultyIdController = TextEditingController();
  bool loading = false;
  bool rememberMe = false;
  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();
    checkSavedLogin(); // Check stored credentials on startup
  }

  /// Check if login credentials are stored
  Future<void> checkSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    bool tempLogin = prefs.getBool('tempLogin') ?? false;

    if (!tempLogin) {
      String? savedEmail = prefs.getString('email');
      String? savedFacultyId = prefs.getString('facultyId');

      if (savedEmail != null && savedFacultyId != null) {
        emailController.text = savedEmail;
        facultyIdController.text = savedFacultyId;
        rememberMe = prefs.getBool('rememberMe') ?? false;
      }
    } else {
      // Clear temporary login data if Remember Me was not checked
      prefs.remove('email');
      prefs.remove('facultyId');
      prefs.remove('tempLogin');
    }
  }

  /// Handle login and store credentials if "Remember Me" is checked
  Future<void> handleLogin() async {
    String email = emailController.text.trim();
    String facultyId = facultyIdController.text.trim();

    if (email.isEmpty || facultyId.isEmpty) {
      showErrorDialog('Please enter both Email and Faculty ID');
      return;
    }

    int? facultyIdInt = int.tryParse(facultyId);
    if (facultyIdInt == null) {
      showErrorDialog('Faculty ID must be a valid number');
      return;
    }

    setState(() => loading = true);

    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$apiBaseUrl/api/faculty')),
        http.get(Uri.parse('$apiBaseUrl/api/student')),
      ]);

      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        final List facultyData = json.decode(responses[0].body);
        final List studentData = json.decode(responses[1].body);

        bool isFaculty = facultyData.any((faculty) =>
            faculty['emailId'] == email && faculty['facultyId'].toString() == facultyId);
        bool isStudent = studentData.any((student) =>
            student['emailId'] == email && student['facultyId'].toString() == facultyId);

        setState(() => loading = false);

        if (isFaculty || isStudent) {
          final prefs = await SharedPreferences.getInstance();

          // Always store credentials temporarily
          prefs.setString('email', email);
          prefs.setString('facultyId', facultyId);

          // If Remember Me is not checked, clear credentials on logout or app restart
          prefs.setBool('tempLogin', !rememberMe);
          prefs.setBool('rememberMe', rememberMe);

          // Navigate to respective dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => isFaculty ? AdminScreen() : student.StudentDashboard()),
          );
        } else {
          showErrorDialog('Invalid credentials');
        }
      } else {
        throw Exception('Server error');
      }
    } catch (e) {
      setState(() => loading = false);
      showErrorDialog('Network error. Please check your connection.');
    }
  }

  /// Logout function to clear temporary credentials
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    bool tempLogin = prefs.getBool('tempLogin') ?? false;

    if (tempLogin) {
      await prefs.clear(); // Clear stored credentials if not remembered
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Login Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school_rounded, size: 100, color: Colors.blue[700]),
              SizedBox(height: 20),
              Text(
                "Welcome Back!",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue[700]),
              ),
              SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white.withOpacity(0.8),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                ),
                padding: EdgeInsets.symmetric(horizontal: 25, vertical: 40),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: emailController,
                      icon: Icons.email,
                      hint: "Email",
                    ),
                    SizedBox(height: 15),
                    _buildTextField(
                      controller: facultyIdController,
                      icon: Icons.lock,
                      hint: "Faculty ID",
                      obscureText: obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(() => obscurePassword = !obscurePassword),
                      ),
                    ),
                    SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: rememberMe,
                              onChanged: (value) => setState(() => rememberMe = value!),
                            ),
                            Text("Remember me"),
                          ],
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text("Forgot Password?", style: TextStyle(color: Colors.blue)),
                        ),
                      ],
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        padding: EdgeInsets.symmetric(vertical: 15),
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        elevation: 10,
                      ),
                      child: Text("SIGN IN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    if (loading) ...[SizedBox(height: 20), CircularProgressIndicator()],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: _inputBoxDecoration(),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blue[700]),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          suffixIcon: suffixIcon,
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
      ),
    );
  }

  BoxDecoration _inputBoxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
    );
  }
}
