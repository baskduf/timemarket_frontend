import 'package:flutter/material.dart';
import 'package:timemarket_frontend/screens/login_screen.dart';
import 'package:timemarket_frontend/screens/time_post_map_screen.dart';
import '../services/time_post_service.dart';
import '../services/auth_service.dart';  // 추가
import 'create_post_screen.dart';
import 'edit_post_screen.dart';
import 'post_detail_screen.dart';
import '../models/post_model.dart';

class TimePostListScreen extends StatefulWidget {
  const TimePostListScreen({Key? key}) : super(key: key);

  @override
  State<TimePostListScreen> createState() => _TimePostListScreenState();
}

class _TimePostListScreenState extends State<TimePostListScreen> {
  final TimePostService _timePostService = TimePostService();
  final AuthService _authService = AuthService();  // 추가

  List<dynamic>? _posts;
  bool _loading = true;
  String _type = 'sale'; // 필요에 따라 'hire' 등 변경
  double _lat = 37.5;
  double _lng = 127.0;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final posts = await _timePostService.fetchNearbyPosts(lat: _lat, lng: _lng, type: _type);
    setState(() {
      _posts = posts ?? [];
      _loading = false;
    });
  }

  List<Widget> _buildActions() {
    return [
      IconButton(
        icon: Icon(Icons.map),
        tooltip: '지도',
        onPressed: () async {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => TimePostMapScreen()),
          );
        },
      ),
      IconButton(
        icon: Icon(Icons.add),
        tooltip: '게시물 작성',
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreatePostScreen()),
          );
          if (created == true) _loadPosts();
        },
      ),
      IconButton(
        icon: Icon(Icons.logout),
        tooltip: '로그아웃',
        onPressed: () async {
          await _authService.logout();  // 로그아웃 처리
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        },
      ),

    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('시간 판매/구인 목록'), actions: _buildActions()),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_posts == null || _posts!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('시간 판매/구인 목록'), actions: _buildActions()),
        body: Center(child: Text('게시글이 없습니다.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('시간 판매/구인 목록'), actions: _buildActions()),
      body: ListView.builder(
        itemCount: _posts!.length,
        itemBuilder: (context, index) {
          final post = _posts![index];
          final postObj = Post.fromJson(post); // Map → Post 변환
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostDetailScreen(post: postObj),
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 프로필 이미지 or 기본 아이콘
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: postObj.author.profileImageUrl != null
                        ? NetworkImage(postObj.author.profileImageUrl!)
                        : null,
                    child: postObj.author.profileImageUrl == null
                        ? Icon(Icons.person, size: 28, color: Colors.grey)
                        : null,
                  ),

                  SizedBox(width: 12),

                  // 작성자 이름 + 글 제목
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          postObj.author.username, // 작성자 이름
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          postObj.title, // 글 제목
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 편집/삭제 버튼
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () async {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditPostScreen(postId: postObj.id, initialData: post),
                            ),
                          );
                          if (updated == true) _loadPosts();
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('삭제 확인'),
                              content: Text('정말 삭제하시겠습니까?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: Text('취소')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: Text('삭제')),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            final success = await _timePostService.deletePost(postObj.id);
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('삭제 완료')));
                              _loadPosts();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('삭제 실패')));
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );

        },
      ),
    );
  }
}
