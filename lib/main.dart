// main.dart

import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:js/js.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';
import 'providers/post_provider.dart';

// JavaScript의 window 객체에 접근하기 위한 설정
@JS()
@anonymous
class FlutterConfiguration {
  external String get GOOGLE_MAPS_API_KEY;
}

@JS('window.flutterConfiguration')
external FlutterConfiguration? get flutterConfiguration;

void main() async {
  // 1. 환경변수 로드
  await dotenv.load(fileName: ".env");
  
  // 2. API 키 가져오기
  final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // 3. API 키가 있을 경우 스크립트 동적 삽입
  if (apiKey.isNotEmpty) {
    final script =
        html.ScriptElement()
          ..src = 'https://maps.googleapis.com/maps/api/js?key=$apiKey&loading=async'
          ..async = true
          ..defer = true;
    html.document.head?.append(script);
  } else {
    print('Google Maps API key is not defined in .env file');
  }

  // 4. 앱 실행
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PostProvider()..initialize(),
      child: MaterialApp(
        title: 'Time Market',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          // ✅ 앱 전체에 일관된 앱 바 디자인을 적용합니다.
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        home: FutureBuilder<String?>(
          // 앱 시작 시 저장된 토큰이 있는지 확인합니다.
          future: _authService.getToken(),
          builder: (context, snapshot) {
            // 로딩 중일 때 로딩 스피너를 보여줍니다.
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // 토큰이 존재하면(로그인 상태) 메인 화면으로 이동합니다.
            if (snapshot.hasData && snapshot.data != null) {
              return const MainScreen();
            } else {
              // 토큰이 없으면 로그인 화면을 보여줍니다.
              return LoginScreen();
            }
          },
        ),
      ),
    );
  }
}
