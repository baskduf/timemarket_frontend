import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // LatLng 사용을 위해 임포트
import 'package:provider/provider.dart';
import '../services/time_post_service.dart';
import '../providers/post_provider.dart';
import 'map_picker_screen.dart'; // 방금 만든 화면 임포트

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

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

  String _selectedType = 'sale';
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

  // ✅ 1. 지도 선택 화면을 띄우는 함수 추가
  Future<void> _openMapPicker() async {
  // MapPickerScreen으로 이동하고, 결과를 LatLng 타입으로 받기를 기다림
    final LatLng? result = await Navigator.of(context).push(
      // MapPickerScreen() 앞의 const를 제거하여 오류 해결
      MaterialPageRoute(builder: (context) => MapPickerScreen()),
    );

    // 사용자가 위치를 선택하고 돌아왔다면 (null이 아니라면)
    if (result != null) {
      setState(() {
        // 컨트롤러의 텍스트를 선택된 위도와 경도로 업데이트
        _latitudeController.text = result.latitude.toString();
        _longitudeController.text = result.longitude.toString();
      });
    }
  }

  Future<void> _submit() async {
    // ... (기존 _submit 함수는 변경 없음) ...
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

    if (success && mounted) {
      // Provider를 통해 전역 상태 업데이트 - 모든 화면에 자동 반영
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      await postProvider.onPostCreated();
      
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('게시글이 성공적으로 등록되었습니다.')));
        Navigator.pop(context, true);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('게시글 등록에 실패했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('게시글 작성')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ... (제목, 설명 입력 필드는 변경 없음) ...
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: '제목'),
                validator:
                    (value) =>
                        (value == null || value.isEmpty) ? '제목을 입력해주세요.' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: '설명'),
                maxLines: 3,
                validator:
                    (value) =>
                        (value == null || value.isEmpty) ? '설명을 입력해주세요.' : null,
              ),
              const SizedBox(height: 16),
              // ✅ 2. 위도/경도 입력란을 수정하고 지도 선택 버튼 추가
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      // 사용자가 직접 수정하지 못하도록 readOnly 설정
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: '위도',
                        hintText: '지도에서 선택하세요',
                      ),
                      validator: (value) =>
                          (value == null || value.isEmpty) ? '위도를 선택해주세요.' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      // 사용자가 직접 수정하지 못하도록 readOnly 설정
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: '경도',
                        hintText: '지도에서 선택하세요',
                      ),
                      validator: (value) =>
                          (value == null || value.isEmpty) ? '경도를 선택해주세요.' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 지도 선택 버튼
              ElevatedButton.icon(
                onPressed: _openMapPicker,
                icon: const Icon(Icons.map),
                label: const Text('지도에서 위치 선택'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87
                ),
              ),
              
              // ... (타입, 가격, 등록 버튼은 변경 없음) ...
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: '타입'),
                items: const [
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
                decoration: const InputDecoration(labelText: '가격'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return '가격을 입력해주세요.';
                  final val = int.tryParse(value);
                  if (val == null) return '유효한 숫자를 입력해주세요.';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(onPressed: _submit, child: const Text('등록')),
            ],
          ),
        ),
      ),
    );
  }
}