// lib/screens/time_post_list_screen.dart

import 'package:flutter/material.dart';
import '../services/time_post_service.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';
import '../models/post_model.dart';

class TimePostListScreen extends StatefulWidget {
  const TimePostListScreen({super.key});

  @override
  State<TimePostListScreen> createState() => _TimePostListScreenState();
}

class _TimePostListScreenState extends State<TimePostListScreen> {
  final TimePostService _timePostService = TimePostService();

  List<Post> _posts = [];
  bool _loading = true;

  String? _currentPostType;
  final List<bool> _isSelected = [true, false, false];

  final double _lat = 37.5;
  final double _lng = 127.0;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _loading = true;
    });

    final postsData = await _timePostService.fetchNearbyPosts(
      lat: _lat,
      lng: _lng,
      type: _currentPostType,
    );

    if (postsData != null) {
      final parsedPosts = postsData
              .map<Post>((postJson) => Post.fromJson(postJson))
              .toList();

      parsedPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _posts = parsedPosts;
      });
    }

    setState(() {
      _loading = false;
    });
  }


  // 당근마켓 스타일의 오렌지 컬러 테마
  static const Color carrotOrange = Color(0xFFFF6F00);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text(
          '시간 거래',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 18,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: carrotOrange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () async {
                final created = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                );
                if (created == true) _loadPosts();
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 당근마켓 스타일의 필터 탭
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('전체', 0),
                const SizedBox(width: 8),
                _buildFilterChip('시간 판매', 1),
                const SizedBox(width: 8),
                _buildFilterChip('구인', 2),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(carrotOrange),
                    ),
                  )
                : _posts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '게시글이 없습니다',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  final postObj = _posts[index];

                  Color getBadgeColor(String type) {
                    return type == 'sale' ? carrotOrange : Colors.blue[600]!;
                  }

                  String getBadgeText(String type) {
                    return type == 'sale' ? '시간 판매' : '구인';
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      elevation: 2,
                      shadowColor: Colors.black.withOpacity(0.1),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PostDetailScreen(post: postObj),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 상단 - 제목과 타입 배지
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      postObj.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: getBadgeColor(postObj.type),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      getBadgeText(postObj.type),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // 설명 (간략하게)
                              if (postObj.description.isNotEmpty)
                                Text(
                                  postObj.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              
                              const SizedBox(height: 12),
                              
                              // 하단 - 가격, 작성자, 시간
                              Row(
                                children: [
                                  // 가격
                                  Text(
                                    '${postObj.price} TC',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: carrotOrange,
                                    ),
                                  ),
                                  
                                  const Spacer(),
                                  
                                  // 작성자 정보
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.grey[200],
                                        backgroundImage: postObj.author.profileImageUrl != null
                                            ? NetworkImage(postObj.author.profileImageUrl!)
                                            : null,
                                        child: postObj.author.profileImageUrl == null
                                            ? Icon(
                                                Icons.person,
                                                size: 14,
                                                color: Colors.grey[600],
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        postObj.author.username,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatTimeAgo(postObj.createdAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _isSelected[index];
    return GestureDetector(
      onTap: () {
        setState(() {
          for (int i = 0; i < _isSelected.length; i++) {
            _isSelected[i] = i == index;
          }
          if (index == 0) {
            _currentPostType = null;
          } else if (index == 1) {
            _currentPostType = 'sale';
          } else {
            _currentPostType = 'request';
          }
        });
        _loadPosts();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? carrotOrange : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? carrotOrange : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}
