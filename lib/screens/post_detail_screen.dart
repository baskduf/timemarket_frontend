import 'package:flutter/material.dart';
import '../models/post_model.dart';

class PostDetailScreen extends StatelessWidget {
  final Post post;

  const PostDetailScreen({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('게시글 상세')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text("종류: ${post.type}", style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text("내용:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text(post.description, style: TextStyle(fontSize: 16)),
            SizedBox(height: 12),
            Text("위도: ${post.latitude}", style: TextStyle(fontSize: 14)),
            Text("경도: ${post.longitude}", style: TextStyle(fontSize: 14)),
            SizedBox(height: 8),
            Text("작성일: ${post.createdAt}", style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
