// lib/screens/edit_post_screen.dart
import 'package:flutter/material.dart';
import '../services/time_post_service.dart';

class EditPostScreen extends StatefulWidget {
  final int postId;
  final Map<String, dynamic> initialData;

  const EditPostScreen({Key? key, required this.postId, required this.initialData}) : super(key: key);

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  final TimePostService _service = TimePostService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialData['title'] ?? '');
    _descController = TextEditingController(text: widget.initialData['description'] ?? '');
  }

  void _submit() async {
    setState(() { _isLoading = true; });

    final success = await _service.updatePost(widget.postId, {
      'title': _titleController.text,
      'description': _descController.text,
    });

    setState(() { _isLoading = false; });

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('수정 실패')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('게시물 수정')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: InputDecoration(labelText: '제목')),
            TextField(controller: _descController, decoration: InputDecoration(labelText: '내용')),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(onPressed: _submit, child: Text('수정하기')),
          ],
        ),
      ),
    );
  }
}
