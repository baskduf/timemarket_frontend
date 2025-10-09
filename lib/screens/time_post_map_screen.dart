// lib/screens/time_post_map_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../providers/post_provider.dart';
import 'post_detail_screen.dart';

class TimePostMapScreen extends StatefulWidget {
  const TimePostMapScreen({super.key});

  @override
  State<TimePostMapScreen> createState() => _TimePostMapScreenState();
}

class _TimePostMapScreenState extends State<TimePostMapScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  static const CameraPosition _initialCamera = CameraPosition(
    target: LatLng(37.5665, 126.9780),
    zoom: 16.0,
  );

  @override
  void initState() {
    super.initState();
    // Provider의 위치를 업데이트하고 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final postProvider = Provider.of<PostProvider>(context, listen: false);
        postProvider.updateLocation(
          _initialCamera.target.latitude,
          _initialCamera.target.longitude,
        );
      }
    });
  }

  Set<Marker> _buildMarkers(List<dynamic> posts) {
    final Set<Marker> markers = {};

    for (final post in posts) {
      try {
        final lat = (post['latitude'] as num).toDouble();
        final lng = (post['longitude'] as num).toDouble();
        final title = post['title'] as String? ?? '제목 없음';
        final price = post['price'] as int? ?? 0;
        final type = post['type'] as String? ?? 'sale';
        final String markerId = post['id']?.toString() ?? 'marker_${markers.length}';
        final authorName = post['user']?['username'] as String? ?? '알 수 없음';

        if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
          print('잘못된 좌표값으로 인해 마커를 건너뜁니다: 위도=$lat, 경도=$lng');
          continue;
        }

        // 게시글 타입에 따른 마커 색상 설정
        BitmapDescriptor markerIcon = type == 'sale' 
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);

        markers.add(
          Marker(
            markerId: MarkerId(markerId),
            position: LatLng(lat, lng),
            icon: markerIcon,
            infoWindow: InfoWindow(
              title: title,
              snippet: '${type == 'sale' ? '판매' : '구인'} • ${price}TC • $authorName',
              onTap: () {
                // InfoWindow 클릭 시 게시글 상세 페이지로 이동
                print('InfoWindow 클릭됨: $title (ID: $markerId)');
                _navigateToPostDetail(post);
              },
            ),
          ),
        );
      } catch (e) {
        print('게시물 데이터 처리 중 오류 발생: $post, 오류: $e');
        continue;
      }
    }
    return markers;
  }

  // 게시글 상세 페이지로 이동하는 함수
  void _navigateToPostDetail(dynamic postData) {
    try {
      // 동적 데이터를 Post 모델로 변환
      final post = Post.fromJson(postData);
      
      // MainScreen의 컨텍스트를 찾아서 네비게이션 실행
      final navigator = Navigator.of(context, rootNavigator: true);
      navigator.push(
        MaterialPageRoute(
          builder: (context) => PostDetailScreen(post: post),
        ),
      );
    } catch (e) {
      print('게시글 상세 페이지 이동 중 오류 발생: $e');
      print('게시글 데이터: $postData');
      
      // 에러 메시지도 rootNavigator 사용
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('게시글을 불러올 수 없습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PostProvider>(
      builder: (context, postProvider, child) {
        if (postProvider.loading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6F00)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '지도를 불러오는 중...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        try {
          return GoogleMap(
            initialCameraPosition: _initialCamera,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            markers: _buildMarkers(postProvider.posts),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
            compassEnabled: true,
          );
        } catch (e) {
          print('Google Maps 로딩 오류: $e');
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  '지도를 불러올 수 없습니다',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '페이지를 새로고침해주세요',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}