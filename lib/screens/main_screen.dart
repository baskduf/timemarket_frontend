// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timemarket_frontend/screens/profile_screen.dart';
import 'package:timemarket_frontend/screens/time_post_list_screen.dart';
import 'package:timemarket_frontend/screens/chat_list_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import 'time_post_map_screen.dart';
import 'create_post_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  int _currentIndex = 0;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  bool _isInitialized = false;

  // 당근마켓 스타일의 컬러 테마
  static const Color carrotOrange = Color(0xFFFF6F00);
  static const Color carrotLightOrange = Color(0xFFFFE0B2);
  static const Color carrotDarkOrange = Color(0xFFE65100);

  // 각 화면을 재생성하기 위한 Key
  Key _mapScreenKey = UniqueKey();
  Key _listScreenKey = UniqueKey();
  Key _chatScreenKey = UniqueKey();
  Key _profileScreenKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  List<Widget> _buildScreens() {
    return [
      TimePostMapScreen(key: _mapScreenKey),
      TimePostListScreen(key: _listScreenKey),
      ChatListScreen(key: _chatScreenKey),
      ProfileScreen(key: _profileScreenKey),
    ];
  }

  Future<void> _initializeApp() async {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    
    // 약간의 지연을 두어 UI가 안정적으로 로드되도록 함
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      _fabAnimationController.forward();
    }
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 초기화가 완료되지 않았으면 로딩 화면 표시
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6F00)),
          ),
        ),
      );
    }

    return Scaffold(
      // 당근마켓 스타일의 상단 바
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: _buildScreens(),
      ),
      // 당근마켓 스타일의 하단 네비게이션 바
      bottomNavigationBar: _buildBottomNavigationBar(),
      // 플로팅 액션 버튼 (게시글 작성)
      floatingActionButton: _currentIndex == 0 || _currentIndex == 1 
          ? ScaleTransition(
              scale: _fabAnimation,
              child: FloatingActionButton(
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreatePostScreen(),
                    ),
                  );
                  if (result == true) {
                    // 게시글이 생성되면 지도와 목록 화면 재생성
                    setState(() {
                      _mapScreenKey = UniqueKey();
                      _listScreenKey = UniqueKey();
                    });
                  }
                },
                backgroundColor: carrotOrange,
                elevation: 8,
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      title: Row(
        children: [
          // 앱 로고
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [carrotOrange, carrotDarkOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: carrotOrange.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.access_time_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // 앱 이름
          const Text(
            'TimeMarket',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      automaticallyImplyLeading: false,
      actions: [
        // 알림 버튼
        Container(
          margin: const EdgeInsets.only(right: 4),
          child: IconButton(
            icon: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: Colors.grey[700],
                    size: 22,
                  ),
                ),
                // 알림 배지 (예시)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: carrotOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('알림 기능은 준비 중입니다'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
        // 메뉴 버튼
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.menu_rounded,
                color: Colors.grey[700],
                size: 22,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 8,
            onSelected: (value) async {
              HapticFeedback.lightImpact();
              switch (value) {
                case 'profile':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileScreen()),
                  );
                  break;
                case 'logout':
                  await _showLogoutDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: Colors.grey[700], size: 20),
                    const SizedBox(width: 12),
                    const Text('내 정보'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_outlined, color: Colors.red[400], size: 20),
                    const SizedBox(width: 12),
                    Text('로그아웃', style: TextStyle(color: Colors.red[400])),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 108,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.map_outlined,
                activeIcon: Icons.map_rounded,
                label: '지도',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.format_list_bulleted_outlined,
                activeIcon: Icons.format_list_bulleted_rounded,
                label: '목록',
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.chat_bubble_outline_rounded,
                activeIcon: Icons.chat_bubble_rounded,
                label: '채팅',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: '내 정보',
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red[400], size: 24),
            const SizedBox(width: 8),
            const Text('로그아웃'),
          ],
        ),
        content: const Text(
          '정말 로그아웃하시겠습니까?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '취소',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              backgroundColor: carrotLightOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '로그아웃',
              style: TextStyle(
                color: carrotOrange,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    VoidCallback? onTap,
  }) {
    final isActive = _currentIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: onTap ?? () {
          HapticFeedback.lightImpact();
          
          // 같은 탭을 다시 누르면 해당 화면 새로고침
          if (_currentIndex == index) {
            setState(() {
              // 해당 화면의 Key를 변경하여 위젯 재생성
              switch (index) {
                case 0: // 지도
                  _mapScreenKey = UniqueKey();
                  break;
                case 1: // 목록
                  _listScreenKey = UniqueKey();
                  break;
                case 2: // 채팅
                  _chatScreenKey = UniqueKey();
                  break;
                case 3: // 마이페이지
                  _profileScreenKey = UniqueKey();
                  break;
              }
            });
          } else {
            // 다른 탭으로 전환하면서 해당 화면 새로고침
            setState(() {
              _currentIndex = index;
              // 전환되는 화면의 Key를 변경하여 새로고침
              switch (index) {
                case 0: // 지도
                  _mapScreenKey = UniqueKey();
                  break;
                case 1: // 목록
                  _listScreenKey = UniqueKey();
                  break;
                case 2: // 채팅
                  _chatScreenKey = UniqueKey();
                  break;
                case 3: // 마이페이지
                  _profileScreenKey = UniqueKey();
                  break;
              }
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 아이콘 컨테이너
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isActive ? carrotLightOrange : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? carrotOrange : Colors.grey[600],
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              // 라벨
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isActive ? carrotOrange : Colors.grey[600],
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
