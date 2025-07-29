import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

const String baseUrl = 'http://localhost:8000/api'; // 실제 주소로 변경

class TimePostService {
  final AuthService _authService = AuthService();

  // 주변 시간 판매/구인 목록 조회 (위도, 경도, type = sale or hire)
  Future<List<dynamic>?> fetchNearbyPosts({
    required double lat,
    required double lng,
    required String type, // 'sale' 또는 'hire'
  }) async {
    final token = await _authService.getToken();
    if (token == null) return null;

    final uri = Uri.parse('$baseUrl/time-posts/')
        .replace(queryParameters: {
      'lat': lat.toString(),
      'lng': lng.toString(),
      'type': type,
    });

    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return null;
  }

  // 시간 판매 or 구인 글 등록
  Future<bool> createPost(Map<String, dynamic> postData) async {
    final token = await _authService.getToken();
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/time-posts/create/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(postData),
    );

    return response.statusCode == 201;
  }

  // 개별 글 상세 보기
  Future<Map<String, dynamic>?> getPostDetail(int postId) async {
    final token = await _authService.getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/time-posts/$postId/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  // 글 수정
  Future<bool> updatePost(int postId, Map<String, dynamic> updateData) async {
    final token = await _authService.getToken();
    if (token == null) return false;

    final response = await http.patch(
      Uri.parse('$baseUrl/time-posts/$postId/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(updateData),
    );

    return response.statusCode == 200;
  }

  // 글 삭제
  Future<bool> deletePost(int postId) async {
    final token = await _authService.getToken();
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse('$baseUrl/time-posts/$postId/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 204;
  }

  // GPS 없이 게시판형 조회
  Future<List<dynamic>?> fetchBoardPosts() async {
    final token = await _authService.getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/time-posts/board/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return null;
  }
}
