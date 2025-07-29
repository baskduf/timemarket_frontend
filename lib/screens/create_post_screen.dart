import 'package:flutter/material.dart';
import '../services/time_post_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String _selectedType = 'sale'; // 'sale' 또는 'help'

  final TimePostService _timePostService = TimePostService();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final latitude = double.tryParse(_latitudeController.text.trim()) ?? 0.0;
    final longitude = double.tryParse(_longitudeController.text.trim()) ?? 0.0;
    final price = int.tryParse(_priceController.text.trim()) ?? 0;
    final type = _selectedType;

    final success = await _timePostService.createPost({
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      'price': price,
    });


    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('게시글이 성공적으로 등록되었습니다.')));
      Navigator.pop(context, true); // 생성 성공 알림 후 이전 화면으로 돌아감
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('게시글 등록에 실패했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('게시글 작성')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: '제목'),
                validator: (value) => (value == null || value.isEmpty) ? '제목을 입력해주세요.' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: '설명'),
                maxLines: 3,
                validator: (value) => (value == null || value.isEmpty) ? '설명을 입력해주세요.' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      decoration: InputDecoration(labelText: '위도'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) return '위도를 입력해주세요.';
                        final val = double.tryParse(value);
                        if (val == null) return '유효한 숫자를 입력해주세요.';
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      decoration: InputDecoration(labelText: '경도'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) return '경도를 입력해주세요.';
                        final val = double.tryParse(value);
                        if (val == null) return '유효한 숫자를 입력해주세요.';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(labelText: '타입'),
                items: [
                  DropdownMenuItem(value: 'sale', child: Text('판매')),
                  DropdownMenuItem(value: 'request', child: Text('구인')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(labelText: '가격'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return '가격을 입력해주세요.';
                  final val = int.tryParse(value);
                  if (val == null) return '유효한 숫자를 입력해주세요.';
                  return null;
                },
              ),
              SizedBox(height: 20),
              _isSubmitting
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _submit,
                child: Text('등록'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
