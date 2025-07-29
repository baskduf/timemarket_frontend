import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatelessWidget {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('회원가입')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _username, decoration: InputDecoration(labelText: 'Username')),
            TextField(controller: _email, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: _password, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
            ElevatedButton(
              onPressed: () async {
                bool success = await _authService.signup(_username.text, _email.text, _password.text);
                if (success) {
                  Navigator.pop(context); // 로그인 화면으로 돌아가기
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("회원가입 실패")));
                }
              },
              child: Text('회원가입'),
            ),
          ],
        ),
      ),
    );
  }
}
