import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  // 서울 시청을 기본 위치로 설정
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.5665, 126.9780),
    zoom: 16.0,
  );

  // 당근마켓 스타일 컬러
  static const Color carrotOrange = Color(0xFFFF6F00);
  static const Color carrotLightOrange = Color(0xFFFFE0B2);

  LatLng? _selectedPosition;
  final Set<Marker> _markers = {};
  
  // 구글맵 컨트롤러와 현재 위치 관리
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    // initState에서는 호출하지 않음 (지도 로드 후 자동 이동)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          '지도에서 위치 선택',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          // 위치가 선택되었을 때만 '완료' 버튼 표시
          if (_selectedPosition != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop(_selectedPosition);
                },
                icon: const Icon(
                  Icons.check_circle,
                  color: carrotOrange,
                  size: 20,
                ),
                label: const Text(
                  '완료',
                  style: TextStyle(
                    color: carrotOrange,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: carrotLightOrange,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            myLocationButtonEnabled: false, // 커스텀 버튼 사용
            myLocationEnabled: true,
            zoomControlsEnabled: false, // 기본 줌 컨트롤 비활성화
            mapToolbarEnabled: false,
            padding: const EdgeInsets.only(bottom: 100, right: 16), // 버튼이 보이도록 패딩 추가
            onMapCreated: (GoogleMapController controller) {
              if (!_controller.isCompleted) {
                _controller.complete(controller);
                // 지도 로드 완료 후 현재 위치로 이동
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    _moveToCurrentLocation();
                  }
                });
              }
            },
            // 지도를 탭했을 때 호출되는 콜백
            onTap: (LatLng position) {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedPosition = position;
                _markers.clear();
                _markers.add(
                  Marker(
                    markerId: const MarkerId('selected-location'),
                    position: position,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueOrange,
                    ),
                  ),
                );
              });
            },
            markers: _markers,
          ),
          // 안내 메시지
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildInfoCard(),
          ),
          // 현재 위치로 이동 버튼
          Positioned(
            bottom: 90, // 더 위로 올림
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 현재 위치 버튼
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _moveToCurrentLocation();
                      },
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: carrotOrange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 현재 위치로 카메라 이동
  Future<void> _moveToCurrentLocation() async {
    try {
      // 위치 서비스 사용 가능 여부 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('위치 서비스가 비활성화되어 있습니다. 위치를 활성화해주세요.'),
              backgroundColor: carrotOrange,
            ),
          );
        }
        return;
      }

      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('위치 권한이 거부되었습니다. 앱 설정에서 권한을 허용해주세요.'),
                backgroundColor: carrotOrange,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 변경하세요.'),
              backgroundColor: carrotOrange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // 캐시된 위치가 있으면 우선 사용, 없으면 새로 가져오기
      Position? pos = _currentPosition;
      if (pos == null) {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _currentPosition = pos;
      }

      if (!mounted) return;

      // 카메라를 현재 위치로 이동
      final controller = await _controller.future;
      final target = LatLng(pos.latitude, pos.longitude);
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 16.0),
        ),
      );

      // 햅틱 피드백
      HapticFeedback.mediumImpact();
      
    } catch (e) {
      print('현재 위치로 이동 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('현재 위치로 이동하는 데 실패했습니다.'),
            backgroundColor: carrotOrange,
          ),
        );
      }
    }
  }

  Widget _buildInfoCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _selectedPosition == null ? Colors.white : carrotLightOrange,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _selectedPosition == null 
                  ? Colors.grey[100] 
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _selectedPosition == null 
                  ? Icons.touch_app_rounded 
                  : Icons.location_on_rounded,
              color: _selectedPosition == null 
                  ? Colors.grey[600] 
                  : carrotOrange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _selectedPosition == null
                  ? '지도를 탭하여 위치를 선택하세요'
                  : '위치가 선택되었습니다. 완료 버튼을 눌러주세요',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _selectedPosition == null 
                    ? Colors.grey[700] 
                    : carrotOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}