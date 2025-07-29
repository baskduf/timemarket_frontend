import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _userService.getMyInfo(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        final user = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            title: Text('내 프로필'),
            actions: [
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: () async {
                  await _userService.authService.logout();
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
                },
              )
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("ID: ${user.id}"),
                Text("Username: ${user.username}"),
                Text("Email: ${user.email}"),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(user))),
                  child: Text('정보 수정'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
