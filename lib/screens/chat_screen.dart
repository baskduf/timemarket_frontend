// lib/screens/chat_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/chat_service.dart';
import '../services/trade_service.dart';
import '../models/post_model.dart';
import '../models/trade_model.dart';
import '../widgets/trade_widgets.dart';

class ChatScreen extends StatefulWidget {
  final int roomId;
  final String otherUserName;
  final int currentUserId;
  final Post? post; // 게시글 정보 추가

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.otherUserName,
    required this.currentUserId,
    this.post, // 선택적 매개변수로 추가
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TradeManager _tradeManager = TradeManager();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  WebSocketChannel? _channel;

  List<Map<String, dynamic>> _messages = [];
  List<TradeRequest> _tradeRequests = [];
  bool _isLoading = true;
  bool _isLoadingTradeRequests = true;

  @override
  void initState() {
    super.initState();
    print('ChatScreen - Post 정보: ${widget.post}'); // 디버그 출력
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    print(_chatService.debugInfo); // 디버그 정보 출력
    
    // TradeManager 콜백 설정
    _tradeManager.setOnTradeRequestsChanged((requests) {
      if (mounted) {
        setState(() {
          _tradeRequests = List.from(requests);
          _isLoadingTradeRequests = false; // 거래 요청 로딩 완료
        });
        _scrollToBottom();
      }
    });

    _tradeManager.setOnError((error) {
      if (mounted) {
        setState(() {
          _isLoadingTradeRequests = false; // 에러 발생 시에도 로딩 완료 처리
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
    
    try {
      // 메시지 히스토리 로드
      final messageHistory = await _chatService.getMessages(widget.roomId);
      if (messageHistory != null && messageHistory.isNotEmpty) {
        // 디버깅: 히스토리에서 불러온 첫 메시지 구조 확인
        if (messageHistory.isNotEmpty) {
          print('📜 [메시지 히스토리] 첫 번째 메시지:');
          print('   - 전체 데이터: ${messageHistory[0]}');
          print('   - sender: ${messageHistory[0]['sender']}');
          print('   - sender profile_image: ${messageHistory[0]['sender']?['profile_image']}');
        }
        
        setState(() {
          _messages = List<Map<String, dynamic>>.from(messageHistory);
        });
      } else {
        setState(() {
          _messages = [];
        });
      }

      // 거래 요청 히스토리 로드 (콜백을 통해 자동으로 UI 업데이트됨)
      await _tradeManager.loadTradeRequests(widget.roomId);
      
      // 로딩 완료
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      print('채팅 초기화 오류: $e');
      setState(() {
        _messages = [];
        _tradeRequests = [];
        _isLoading = false;
        _isLoadingTradeRequests = false; // 에러 시에도 로딩 완료 처리
      });
      
      // 사용자에게 오류 알림
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('채팅을 불러오는데 실패했습니다. 새로고침해주세요.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }

    // WebSocket 연결
    _channel = await _chatService.connect(widget.roomId);
    
    if (_channel == null) {
      print('❌ 웹소켓 연결 실패 - 채팅을 사용할 수 없습니다.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('채팅 서버 연결에 실패했습니다. 네트워크를 확인해주세요.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    
    _tradeManager.setWebSocketChannel(_channel);

    // 거래 관련 핸들러 등록 (WebSocket용)
    _tradeManager.addTradeRequestHandler(_handleNewTradeRequest);
    _tradeManager.addTradeUpdateHandler(_handleTradeUpdate);
    _tradeManager.addErrorHandler(_handleTradeError);

    _channel?.stream.listen(
      (message) {
        try {
          print('📥 수신된 WebSocket 메시지: $message');
          final messageData = jsonDecode(message);
          
          // 메시지 타입 확인
          if (messageData['type'] == 'chat_message' && messageData['data'] != null) {
            // 디버깅: 웹소켓으로 받은 메시지 데이터 구조 확인
            print('💬 [WebSocket] 받은 메시지 데이터:');
            print('   - 전체 데이터: ${messageData['data']}');
            print('   - sender: ${messageData['data']['sender']}');
            print('   - sender profile_image: ${messageData['data']['sender']?['profile_image']}');
            
            // 일반 채팅 메시지 처리
            bool isDuplicate = _messages.any((m) => 
              m['id'] != null && messageData['data']['id'] != null && 
              m['id'] == messageData['data']['id']);
            if (!isDuplicate) {
              setState(() {
                _messages.add(messageData['data']);
              });
              _scrollToBottom();
              print('✅ 새 메시지 추가됨: ${messageData['data']['message']}');
            } else {
              print('⚠️ 중복 메시지 무시됨');
            }
          } else {
            // 거래 관련 메시지 처리
            _tradeManager.handleWebSocketMessage(message);
          }
        } catch (e) {
          print('❌ WebSocket 메시지 처리 오류: $e');
          print('❌ 문제가 된 메시지: $message');
        }
      },
      onError: (error) {
        print('❌ WebSocket 스트림 오류: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('채팅 연결에 문제가 발생했습니다. 새로고침해주세요.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
      onDone: () {
        print('⚠️ WebSocket 연결이 종료되었습니다.');
        // dispose 중에는 ScaffoldMessenger 사용하지 않음
      },
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) {
      print('⚠️ 빈 메시지는 전송할 수 없습니다.');
      return;
    }
    
    if (_channel == null) {
      print('❌ 웹소켓 연결이 없습니다. 메시지를 전송할 수 없습니다.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('채팅 서버에 연결되지 않았습니다. 잠시 후 다시 시도해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final messageText = _messageController.text.trim();
    final message = {
      'type': 'chat',
      'message': messageText
    };
    
    try {
      final encodedMessage = jsonEncode(message);
      print('📤 메시지 전송 시도: $encodedMessage');
      _channel!.sink.add(encodedMessage);
      print('✅ 메시지 전송 완료: "$messageText"');
      _messageController.clear();
    } catch (e) {
      print('❌ 메시지 전송 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('메시지 전송에 실패했습니다. 다시 시도해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 거래 관련 핸들러 메서드들 (WebSocket 전용)
  void _handleNewTradeRequest(TradeRequest request) {
    // 상태 업데이트는 TradeManager의 콜백에서 처리됨
    _scrollToBottom();
    
    // 알림 표시
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('새로운 거래 요청이 도착했습니다'),
          backgroundColor: Color(0xFF4A90E2),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleTradeUpdate(TradeRequest updatedRequest) {
    // 상태 업데이트는 TradeManager의 콜백에서 처리됨
    
    // 거래 완료/거절 알림
    if (mounted) {
      if (updatedRequest.isCompleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('거래가 성사되었습니다! 🎉'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else if (updatedRequest.isRejected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('거래가 거절되었습니다'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _handleTradeError(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // 거래 요청 생성
  void _showCreateTradeRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateTradeRequestDialog(
        initialPrice: widget.post?.price.toDouble(),
        onSubmit: (price, hours, message) {
          _tradeManager.createTradeRequest(
            widget.roomId,
            price,
            hours,
            message,
          );
        },
      ),
    );
  }

  // 거래 수락
  void _acceptTrade(TradeRequest request) {
    _tradeManager.acceptTrade(request.id, message: '거래를 수락합니다.');
  }

  // 거래 거절
  void _rejectTrade(TradeRequest request) {
    _tradeManager.rejectTrade(request.id, message: '거래를 거절합니다.');
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _tradeManager.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          widget.otherUserName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // 더보기 메뉴 (신고, 차단 등)
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 게시글 정보 카드 (항상 표시)
                _buildPostInfoCard(),
                
                // 메시지 및 거래 요청 목록
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    itemCount: _getCombinedItemCount(),
                    itemBuilder: (context, index) {
                      return _buildCombinedItem(index);
                    },
                  ),
                ),
                _buildMessageInput(),
              ],
            ),
    );
  }

  // 메시지와 거래 요청을 시간순으로 정렬하여 통합 표시
  int _getCombinedItemCount() {
    try {
      final messagesCount = _messages.length;
      final tradeRequestsCount = _tradeRequests.length;
      final loadingIndicatorCount = _isLoadingTradeRequests && (messagesCount > 0 || tradeRequestsCount > 0) ? 1 : 0;
      return messagesCount + tradeRequestsCount + loadingIndicatorCount;
    } catch (e) {
      print('_getCombinedItemCount 오류: $e');
      return 0;
    }
  }

  Widget _buildCombinedItem(int index) {
    try {
      // 모든 아이템을 시간순으로 정렬
      final allItems = <Map<String, dynamic>>[];
      
      // 메시지 추가
      if (_messages.isNotEmpty) {
        for (final message in _messages) {
          if (message['timestamp'] != null) {
            try {
              allItems.add({
                'type': 'message',
                'data': message,
                'timestamp': DateTime.parse(message['timestamp']),
              });
            } catch (e) {
              print('메시지 타임스탬프 파싱 오류: $e');
              // 파싱 실패 시 현재 시간 사용
              allItems.add({
                'type': 'message',
                'data': message,
                'timestamp': DateTime.now(),
              });
            }
          }
        }
      }
      
      // 거래 요청 추가
      if (_tradeRequests.isNotEmpty) {
        for (final trade in _tradeRequests) {
          // createdAt은 DateTime이므로 항상 존재
          allItems.add({
            'type': 'trade',
            'data': trade,
            'timestamp': trade.createdAt,
          });
        }
      }
      
      // 거래 요청 로딩 중일 때 로딩 인디케이터 추가
      if (_isLoadingTradeRequests && allItems.isNotEmpty) {
        allItems.add({
          'type': 'loading_trade',
          'data': null,
          'timestamp': DateTime.now(),
        });
      }
      
      // 시간순 정렬
      allItems.sort((a, b) => (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime));
      
      if (index >= allItems.length) return const SizedBox.shrink();
      
      final item = allItems[index];
      
      if (item['type'] == 'message') {
        final message = item['data'] as Map<String, dynamic>;
        final isMe = message['sender'] != null && message['sender']['id'] == widget.currentUserId;
        final timestamp = item['timestamp'] as DateTime;
        final profileImageUrl = message['sender']?['profile_image'] as String?;
        
        // 디버깅: 메시지 렌더링 시 프로필 이미지 URL 확인
        if (index % 20 == 0) { // 20개마다 한 번씩만 로그 출력
          print('🎨 [메시지 렌더링] 인덱스 $index:');
          print('   - sender: ${message['sender']}');
          print('   - profile_image: $profileImageUrl');
          print('   - isMe: $isMe');
        }
        
        return _buildMessageBubble(
          isMe,
          message['message'] ?? '',
          timestamp,
          profileImageUrl,
        );
      } else if (item['type'] == 'loading_trade') {
        return _buildTradeLoadingIndicator();
      } else {
        final tradeRequest = item['data'] as TradeRequest;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: TradeRequestCard(
            tradeRequest: tradeRequest,
            currentUserId: widget.currentUserId,
            onAccept: () => _acceptTrade(tradeRequest),
            onReject: () => _rejectTrade(tradeRequest),
          ),
        );
      }
    } catch (e) {
      print('_buildCombinedItem 오류: $e');
      return const SizedBox.shrink();
    }
  }

  Widget _buildTradeLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '거래 요청을 불러오는 중...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostInfoCard() {
    final post = widget.post;
    
    // 게시글 정보가 없을 때 기본 카드 표시
    if (post == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: Colors.grey[400],
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${widget.otherUserName}님과의 대화',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    final priceText = '${post.price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}원';
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: 타입 배지와 가격
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: post.type == 'sale' 
                      ? const Color(0xFFF0F8FF) 
                      : const Color(0xFFFFF8F0),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: post.type == 'sale'
                        ? const Color(0xFF4A90E2)
                        : const Color(0xFFFF8C00),
                    width: 1,
                  ),
                ),
                child: Text(
                  post.type == 'sale' ? '판매' : '구매',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: post.type == 'sale'
                        ? const Color(0xFF4A90E2)
                        : const Color(0xFFFF8C00),
                  ),
                ),
              ),
              Text(
                priceText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFF6B35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 제목
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          
          // 설명
          Text(
            post.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          
          // 하단: 작성자와 작성일
          Row(
            children: [
              Icon(
                Icons.person,
                size: 16,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                post.author.username,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.schedule,
                size: 16,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('MM.dd HH:mm').format(post.createdAt.toLocal()),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(bool isMe, String text, DateTime timestamp, String? profileImageUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isMe) ...[
            // 내 메시지의 시간
            Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 2),
              child: Text(
                DateFormat('HH:mm').format(timestamp),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ],
          
          if (!isMe) ...[
            // 상대방 프로필 이미지
            Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 2),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[200],
                backgroundImage: profileImageUrl != null
                    ? NetworkImage(profileImageUrl)
                    : null,
                child: profileImageUrl == null
                    ? Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.grey[400],
                      )
                    : null,
              ),
            ),
          ],
          
          // 메시지 버블
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFFF6B35) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 15,
                  height: 1.3,
                ),
              ),
            ),
          ),
          
          if (!isMe) ...[
            // 상대방 메시지의 시간
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 2),
              child: Text(
                DateFormat('HH:mm').format(timestamp),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 거래 요청 버튼
            TradeRequestButton(
              onPressed: _showCreateTradeRequestDialog,
            ),
            const SizedBox(width: 8.0),
            
            // 메시지 입력 필드
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: '메시지를 입력하세요',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 10.0,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            
            // 전송 버튼
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFFF6B35),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.send,
                  size: 18,
                  color: Colors.white,
                ),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
