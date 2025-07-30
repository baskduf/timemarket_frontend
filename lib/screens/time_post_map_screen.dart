import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/time_post_service.dart';  // 위에 제공하신 서비스
import '../services/auth_service.dart';       // 로그인, 로그아웃 처리 서비스
import 'time_post_list_screen.dart';  // 게시글 목록 화면
import 'login_screen.dart';           // 로그인 화면

class TimePostMapScreen extends StatefulWidget {
  const TimePostMapScreen({super.key});

  @override
  State<TimePostMapScreen> createState() => _TimePostMapScreenState();
}

class _TimePostMapScreenState extends State<TimePostMapScreen> {
  final TimePostService _postService = TimePostService();
  final AuthService _authService = AuthService();

  List<dynamic> _posts = [];
  bool _loading = true;
  String _postType = 'sale'; // 기본: 판매 목록

  final LatLng _initialCenter = LatLng(37.5665, 126.9780); // 서울 시청 좌표
  double _zoom = 16; // 300% 확대 비슷한 값

  @override
  void initState() {
    super.initState();
    _loadNearbyPosts();
  }

  Future<void> _loadNearbyPosts() async {
    // 실제로는 GPS 받아와야 하지만 일단 서울 시청 기준으로 호출
    final posts = await _postService.fetchNearbyPosts(
      lat: _initialCenter.latitude,
      lng: _initialCenter.longitude,
      type: _postType,
    );

    if (posts != null) {
      setState(() {
        _posts = posts;
        _loading = false;
      });
    } else {
      // 에러 처리 등 필요
      setState(() {
        _loading = false;
      });
    }
  }

  List<Marker> _buildMarkers() {
    return _posts.where((post) {
      final lat = post['latitude'] as double;
      final lng = post['longitude'] as double;

      // 위도 경도 범위 체크
      if (lat < -90 || lat > 90) return false;
      if (lng < -180 || lng > 180) return false;

      return true;
    }).map((post) {
      final lat = post['latitude'] as double;
      final lng = post['longitude'] as double;
      final title = post['title'] as String? ?? '제목 없음';

      return Marker(
        width: 80,
        height: 80,
        point: LatLng(lat, lng),
        builder: (ctx) => GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(title),
                content: Text('위도: $lat\n경도: $lng'),
                actions: [
                  TextButton(
                    child: const Text('닫기'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          },
          child: const Icon(
            Icons.location_pin,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
    }).toList();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('시간 거래 지도'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: '게시글 목록',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TimePostListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () async {
              await _authService.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
        options: MapOptions(
          center: _initialCenter,
          zoom: _zoom,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: _buildMarkers(),
          ),
        ],
      ),
    );
  }
}
