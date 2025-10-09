// lib/providers/post_provider.dart

import 'package:flutter/foundation.dart';
import '../services/time_post_service.dart';

/// 게시글 상태를 전역으로 관리하는 Provider
class PostProvider with ChangeNotifier {
  final TimePostService _postService = TimePostService();

  List<dynamic> _posts = [];
  bool _loading = false;
  String? _error;

  // 현재 위치 정보 (기본값: 서울 시청)
  double _currentLat = 37.5665;
  double _currentLng = 126.9780;

  // 게터
  List<dynamic> get posts => _posts;
  bool get loading => _loading;
  String? get error => _error;
  double get currentLat => _currentLat;
  double get currentLng => _currentLng;

  /// 위치 정보 업데이트
  void updateLocation(double lat, double lng) {
    _currentLat = lat;
    _currentLng = lng;
    notifyListeners();
  }

  /// 게시글 목록을 서버에서 가져오기
  Future<void> fetchPosts({String? type}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final postsData = await _postService.fetchNearbyPosts(
        lat: _currentLat,
        lng: _currentLng,
        type: type,
      );

      if (postsData != null) {
        _posts = postsData;
      } else {
        _posts = [];
      }
      _error = null;
    } catch (e) {
      _error = '게시글을 불러오는데 실패했습니다: $e';
      _posts = [];
      if (kDebugMode) {
        print('PostProvider fetchPosts 오류: $e');
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 게시글이 생성되었을 때 호출 - 전체 목록 새로고침
  Future<void> onPostCreated() async {
    if (kDebugMode) {
      print('PostProvider: 새 게시글 생성됨, 목록 새로고침 시작');
    }
    await fetchPosts();
  }

  /// 특정 게시글 삭제 후 새로고침
  Future<void> onPostDeleted() async {
    if (kDebugMode) {
      print('PostProvider: 게시글 삭제됨, 목록 새로고침 시작');
    }
    await fetchPosts();
  }

  /// 수동 새로고침
  Future<void> refresh() async {
    await fetchPosts();
  }

  /// Provider 초기화 시 자동으로 데이터 로드
  void initialize() {
    fetchPosts();
  }
}
