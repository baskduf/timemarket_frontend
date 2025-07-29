import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;
  EditProfileScreen(this.user);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserService _userService = UserService();
  late TextEditingController _username;
  late TextEditingController _email;

  @override
  void initState() {
    super.initState();
    _username = TextEditingController(text: widget.user.username);
    _email = TextEditingController(text: widget.user.email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('정보 수정')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _username, decoration: InputDecoration(labelText: 'Username')),
            TextField(controller: _email, decoration: InputDecoration(labelText: 'Email')),
            ElevatedButton(
              onPressed: () async {
                bool success = await _userService.updateMyInfo(_username.text, _email.text);
                if (success) {
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("수정 실패")));
                }
              },
              child: Text('수정하기'),
            ),
          ],
        ),
      ),
    );
  }
}
