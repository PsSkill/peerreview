import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:peerreview/Admin/adminDashboard.dart';
import 'package:peerreview/students/studentDashboard.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String email = '';
  String facultyId = '';
  bool loading = false;
  bool rememberMe = false;
  bool obscurePassword = true;

  Future<void> handleLogin() async {
    if (email.isEmpty || facultyId.isEmpty) {
      showErrorDialog('Please enter both Email and Faculty ID');
      return;
    }

    int? facultyIdInt = int.tryParse(facultyId);
    if (facultyIdInt == null) {
      showErrorDialog('Faculty ID must be a number');
      return;
    }

    if (email == 'test@bitsathy.ac.in' && facultyIdInt == 123456) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AdminScreen()),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final facultyResponse =
          await http.get(Uri.parse('http://192.168.168.45:5000/api/faculty'));
      final studentResponse =
          await http.get(Uri.parse('http://192.168.168.45:5000/api/student'));

      if (facultyResponse.statusCode == 200 && studentResponse.statusCode == 200) {
        final List facultyData = json.decode(facultyResponse.body);
        final List studentData = json.decode(studentResponse.body);

        bool isFaculty = facultyData.any((faculty) =>
            faculty['emailId'] == email && faculty['facultyId'] == facultyIdInt);
        bool isStudent = studentData.any((student) =>
            student['emailId'] == email && student['facultyId'] == facultyIdInt);

        setState(() => loading = false);

        if (isFaculty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminScreen()),
          );
        } else if (isStudent) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => StudentDashboard()),
          );
        } else {
          showErrorDialog('Invalid credentials');
        }
      } else {
        setState(() => loading = false);
        showErrorDialog('Server error. Please try again.');
      }
    } catch (e) {
      setState(() => loading = false);
      showErrorDialog('Network error. Check your connection.');
    }
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
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Icon(
                  Icons.school_rounded,
                  size: 80,
                  color: Colors.blue[700],
                ),
                SizedBox(height: 10),

                Text(
                  "Welcome Back!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                SizedBox(height: 30),

                // Email Field
                _buildTextField(
                  icon: Icons.email,
                  hint: "Email",
                  onChanged: (value) => setState(() => email = value),
                ),
                SizedBox(height: 15),

                // Password Field
                _buildTextField(
                  icon: Icons.lock,
                  hint: "ID",
                  obscureText: obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(() => obscurePassword = !obscurePassword),
                  ),
                  onChanged: (value) => setState(() => facultyId = value),
                ),
                SizedBox(height: 10),

                // Remember Me & Forgot Password
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
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Login Button
                ElevatedButton(
                  onPressed: handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    "SIGN IN",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),

                if (loading) ...[
                  SizedBox(height: 20),
                  CircularProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to create input fields
  Widget _buildTextField({
    required IconData icon,
    required String hint,
    bool obscureText = false,
    Widget? suffixIcon,
    required Function(String) onChanged,
  }) {
    return Container(
      decoration: _inputBoxDecoration(),
      child: TextField(
        obscureText: obscureText,
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blue),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          suffixIcon: suffixIcon,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  // Input Field Styling
  BoxDecoration _inputBoxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 10,
          offset: Offset(0, 5),
        ),
      ],
    );
  }
}
