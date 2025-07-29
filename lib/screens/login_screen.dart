import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'login_screen.dart'; // LoginScreen 경로 맞게 import 꼭 해주세요
import 'time_post_list_screen.dart'; // 새로 만든 화면 import

class LoginScreen extends StatelessWidget {
  final _username = TextEditingController();
  final _email = TextEditingController();
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
            TextField(controller: _email, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: _password, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
            ElevatedButton(
              onPressed: () async {
                bool success = await _authService.login(_username.text, _email.text, _password.text);
                if (success) {
                  // 로그인 성공 시 TimePostListScreen 으로 이동
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => TimePostListScreen()),
                  );
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
