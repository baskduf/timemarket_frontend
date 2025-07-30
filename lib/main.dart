import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/time_post_list_screen.dart';
import 'screens/time_post_map_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Market',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FutureBuilder<String?>(
        future: _authService.getToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (snapshot.data != null)
            return LoginScreen();
          else
            return LoginScreen();
        },
      ),
    );
  }
}
