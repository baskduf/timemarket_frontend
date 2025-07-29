import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'profile_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatelessWidget {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('로그인')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _username, decoration: InputDecoration(labelText: 'Username')),
            TextField(controller: _password, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
            ElevatedButton(
              onPressed: () async {
                bool success = await _authService.login(_username.text, _password.text);
                if (success) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProfileScreen()));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("로그인 실패")));
                }
              },
              child: Text('로그인'),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SignupScreen())),
              child: Text('회원가입'),
            ),
          ],
        ),
      ),
    );
  }
}
