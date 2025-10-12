# 거래 시스템 가이드

## 개요
TimeMarket의 거래 시스템은 사용자 간에 시간을 안전하게 거래할 수 있도록 합니다. 양쪽 사용자가 모두 수락했을 때만 거래가 성사되며, 잔액이 부족한 경우 자동으로 거래가 거절됩니다.

## 거래 흐름

### 1. 거래 요청 생성
```http
POST /api/chat/rooms/{room_id}/trade/
```

**요청 데이터:**
```json
{
    "proposed_price": 15000,
    "proposed_hours": 3.5,
    "message": "도움 요청드립니다"
}
```

### 2. 거래 수락
```http
PATCH /api/chat/trade/{trade_id}/
```

**요청자가 수락:**
```json
{
    "requester_accepted": true
}
```

**수신자가 수락:**
```json
{
    "receiver_accepted": true
}
```

### 3. 거래 성사
양쪽 모두 수락하면 자동으로 거래가 처리됩니다.

## 거래 타입

### Sale (시간 판매)
- **제공자:** 게시글 작성자 (판매자)
- **수혜자:** 거래 요청자 (구매자)
- **흐름:** 판매자의 시간 → 구매자에게 전달

**예시:**
```
게시글 작성자(user1) - balance: 10시간
거래 요청자(user2) - balance: 5시간
거래 시간: 3시간

거래 후:
user1 - balance: 7시간 (10 - 3)
user2 - balance: 8시간 (5 + 3)
```

### Request (구인)
- **제공자:** 거래 요청자
- **수혜자:** 게시글 작성자
- **흐름:** 요청자의 시간 → 게시글 작성자에게 전달

**예시:**
```
게시글 작성자(user1) - balance: 5시간
거래 요청자(user2) - balance: 10시간
거래 시간: 4시간

거래 후:
user1 - balance: 9시간 (5 + 4)
user2 - balance: 6시간 (10 - 4)
```

## 잔액 검증

### 충분한 잔액
제공자의 잔액이 요청 시간 이상일 경우:
- ✅ 거래 성사
- 지갑 잔액 자동 차감/증가
- 거래 내역 기록
- 상태: `completed`

### 부족한 잔액
제공자의 잔액이 요청 시간 미만일 경우:
- ❌ 거래 거절
- 지갑 잔액 변화 없음
- 상태: `rejected`

**응답 예시:**

#### 1. Sale 타입 - 판매자 잔액 부족
판매자가 제공할 시간이 부족한 경우:
```json
{
    "error": [
        "판매자(user1)님의 잔액이 부족하여 거래가 거절되었습니다. 필요: 5.00시간, 현재 잔액: 2.00시간"
    ],
    "error_code": "INSUFFICIENT_BALANCE",
    "error_details": {
        "provider": "user1",
        "required_hours": 5.00,
        "current_balance": 2.00,
        "shortage": 3.00
    }
}
```

#### 2. Request 타입 - 요청자 잔액 부족
요청자가 제공할 시간이 부족한 경우:
```json
{
    "error": [
        "요청자(user2)님의 잔액이 부족하여 거래가 거절되었습니다. 필요: 4.00시간, 현재 잔액: 1.50시간"
    ],
    "error_code": "INSUFFICIENT_BALANCE",
    "error_details": {
        "provider": "user2",
        "required_hours": 4.00,
        "current_balance": 1.50,
        "shortage": 2.50
    }
}
```

## 거래 실패 응답

다양한 실패 시나리오에 대한 상세한 응답 예시입니다.

### 1. 권한 없음
다른 사용자의 거래를 수정하려고 시도하는 경우:
```json
{
    "error": "이 거래를 수정할 권한이 없습니다.",
    "error_code": "PERMISSION_DENIED",
    "status": 403
}
```

### 2. 이미 완료된 거래
완료된 거래를 다시 수락하려는 경우:
```json
{
    "error": "이미 완료된 거래입니다.",
    "error_code": "ALREADY_COMPLETED",
    "status": 400,
    "trade_status": "completed"
}
```

### 3. 이미 거절된 거래
거절된 거래를 수정하려는 경우:
```json
{
    "error": "거절된 거래는 수정할 수 없습니다.",
    "error_code": "ALREADY_REJECTED",
    "status": 400,
    "trade_status": "rejected",
    "rejection_reason": "잔액 부족"
}
```

### 4. 취소된 거래
취소된 거래를 수정하려는 경우:
```json
{
    "error": "취소된 거래는 수정할 수 없습니다.",
    "error_code": "ALREADY_CANCELLED",
    "status": 400,
    "trade_status": "cancelled"
}
```

### 5. 거래를 찾을 수 없음
존재하지 않는 거래 ID로 요청한 경우:
```json
{
    "error": "거래를 찾을 수 없습니다.",
    "error_code": "TRADE_NOT_FOUND",
    "status": 404
}
```

### 6. 잘못된 요청 데이터
필수 필드가 누락되거나 잘못된 경우:
```json
{
    "error": {
        "proposed_hours": ["이 필드는 필수입니다."],
        "proposed_price": ["유효한 숫자를 입력하세요."]
    },
    "error_code": "INVALID_REQUEST",
    "status": 400
}
```

### 7. 음수 또는 0 값
시간이나 금액이 0 이하인 경우:
```json
{
    "error": "거래 시간은 0보다 커야 합니다.",
    "error_code": "INVALID_HOURS",
    "status": 400,
    "provided_value": -1.5
}
```

### 8. 지갑이 없는 경우
사용자 지갑이 생성되지 않은 경우:
```json
{
    "error": "user1님의 지갑을 찾을 수 없습니다. 관리자에게 문의하세요.",
    "error_code": "WALLET_NOT_FOUND",
    "status": 404,
    "user": "user1"
}
```

### 9. 서버 오류
예상치 못한 서버 오류 발생:
```json
{
    "error": "거래 처리 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.",
    "error_code": "SERVER_ERROR",
    "status": 500
}
```

### 10. 동시 거래 충돌
같은 거래를 동시에 수정하려는 경우:
```json
{
    "error": "다른 사용자가 이미 이 거래를 처리하고 있습니다. 잠시 후 다시 시도해주세요.",
    "error_code": "CONCURRENT_MODIFICATION",
    "status": 409
}
```

## 에러 코드 정리

| 에러 코드 | HTTP 상태 | 설명 |
|----------|-----------|------|
| `INSUFFICIENT_BALANCE` | 400 | 잔액 부족 |
| `PERMISSION_DENIED` | 403 | 권한 없음 |
| `ALREADY_COMPLETED` | 400 | 이미 완료된 거래 |
| `ALREADY_REJECTED` | 400 | 이미 거절된 거래 |
| `ALREADY_CANCELLED` | 400 | 이미 취소된 거래 |
| `TRADE_NOT_FOUND` | 404 | 거래를 찾을 수 없음 |
| `INVALID_REQUEST` | 400 | 잘못된 요청 데이터 |
| `INVALID_HOURS` | 400 | 잘못된 시간 값 |
| `WALLET_NOT_FOUND` | 404 | 지갑을 찾을 수 없음 |
| `SERVER_ERROR` | 500 | 서버 오류 |
| `CONCURRENT_MODIFICATION` | 409 | 동시 수정 충돌 |

## 프론트엔드 처리 가이드

### 에러 핸들링 예시 (Flutter/Dart)
```dart
Future<void> acceptTrade(int tradeId) async {
  try {
    final response = await tradeService.acceptTrade(tradeId);
    // 성공 처리
    showSuccessMessage('거래가 성공적으로 완료되었습니다.');
  } catch (e) {
    if (e is ApiException) {
      switch (e.errorCode) {
        case 'INSUFFICIENT_BALANCE':
          final details = e.errorDetails;
          showErrorDialog(
            title: '잔액 부족',
            message: '${details['provider']}님의 잔액이 부족합니다.\n'
                    '필요: ${details['required_hours']}시간\n'
                    '현재: ${details['current_balance']}시간\n'
                    '부족: ${details['shortage']}시간',
          );
          break;
        case 'PERMISSION_DENIED':
          showErrorMessage('이 거래를 수정할 권한이 없습니다.');
          break;
        case 'ALREADY_COMPLETED':
          showInfoMessage('이미 완료된 거래입니다.');
          refreshTradeStatus();
          break;
        case 'ALREADY_REJECTED':
          showInfoMessage('거절된 거래입니다.');
          refreshTradeStatus();
          break;
        case 'CONCURRENT_MODIFICATION':
          showWarningMessage('다른 사용자가 처리 중입니다. 잠시 후 다시 시도해주세요.');
          await Future.delayed(Duration(seconds: 2));
          refreshTradeStatus();
          break;
        default:
          showErrorMessage(e.message);
      }
    }
  }
}
```

### 사용자 친화적 메시지
에러 응답을 받았을 때 사용자에게 보여줄 수 있는 친화적인 메시지 예시:

| 에러 코드 | 사용자 메시지 |
|----------|--------------|
| `INSUFFICIENT_BALANCE` | "💰 상대방의 시간이 부족하여 거래를 완료할 수 없습니다." |
| `PERMISSION_DENIED` | "🚫 이 거래를 수정할 수 없습니다." |
| `ALREADY_COMPLETED` | "✅ 이미 완료된 거래입니다." |
| `ALREADY_REJECTED` | "❌ 거절된 거래입니다." |
| `ALREADY_CANCELLED` | "🚫 취소된 거래입니다." |
| `TRADE_NOT_FOUND` | "🔍 거래를 찾을 수 없습니다." |
| `INVALID_HOURS` | "⚠️ 거래 시간은 0보다 커야 합니다." |
| `WALLET_NOT_FOUND` | "💼 지갑 정보를 찾을 수 없습니다. 고객센터에 문의해주세요." |
| `SERVER_ERROR` | "⚠️ 일시적인 오류가 발생했습니다. 잠시 후 다시 시도해주세요." |
| `CONCURRENT_MODIFICATION` | "⏳ 다른 사용자가 처리 중입니다. 잠시만 기다려주세요." |

## 거래 상태

| 상태 | 설명 |
|------|------|
| `pending` | 대기중 - 수락 대기 |
| `accepted` | 수락됨 - 한쪽만 수락 |
| `rejected` | 거절됨 - 잔액 부족 등의 이유로 거절 |
| `completed` | 완료됨 - 양쪽 수락 및 거래 완료 |
| `cancelled` | 취소됨 - 사용자가 취소 |

## 안전장치

### 1. 트랜잭션 보장
- 데이터베이스 트랜잭션으로 원자성 보장
- 거래 중 오류 발생 시 자동 롤백

### 2. 동시성 제어
- `select_for_update()`를 사용한 락 처리
- 동시 거래 시도 시 안전하게 처리

### 3. 거래 내역 기록
모든 거래는 Transaction 테이블에 기록됩니다:
```python
{
    "wallet": wallet_id,
    "transaction_type": "withdraw" | "deposit",
    "amount": proposed_hours,
    "note": "거래 내역 설명",
    "timestamp": "2025-10-12T12:00:00Z"
}
```

### 4. 상태 검증
- 이미 완료/거절/취소된 거래는 수정 불가
- 권한이 없는 사용자는 거래 수정 불가

## API 응답 예시

### 성공적인 거래
```json
{
    "id": 1,
    "room": 5,
    "post": {
        "id": 10,
        "title": "컴퓨터 수리 도움",
        "type": "sale"
    },
    "requester": {
        "id": 2,
        "nickname": "user2",
        "email": "user2@example.com"
    },
    "receiver": {
        "id": 1,
        "nickname": "user1",
        "email": "user1@example.com"
    },
    "proposed_price": "15000.00",
    "proposed_hours": "3.00",
    "message": "도움 요청드립니다",
    "status": "completed",
    "requester_accepted": true,
    "receiver_accepted": true,
    "created_at": "2025-10-12T10:00:00Z",
    "updated_at": "2025-10-12T12:00:00Z"
}
```

## 테스트

거래 시스템의 모든 기능은 테스트로 검증됩니다:

```bash
python manage.py test chat.tests.test_trade_views
```

**테스트 커버리지:**
- ✅ 잔액이 충분한 경우 거래 성사
- ✅ 잔액이 부족한 경우 거래 거절
- ✅ Sale 타입 거래
- ✅ Request 타입 거래
- ✅ 완료된 거래 수정 불가
- ✅ 거래 내역 기록
- ✅ 권한 검증

## 주의사항

1. **지갑이 없는 경우:** 첫 거래 시도 시 자동으로 지갑이 생성됩니다 (초기 잔액: 0)
2. **초기 잔액:** 관리자가 사용자에게 초기 시간을 부여해야 거래가 가능합니다
3. **동시 거래:** 한 사용자가 여러 거래를 동시에 수락하면 잔액이 부족할 수 있습니다
4. **취소 불가:** 거래가 완료되면 취소할 수 없습니다

## 향후 개선 사항

- [ ] 거래 취소 기능
- [ ] 거래 이의 제기 시스템
- [ ] 자동 환불 시스템
- [ ] 거래 평가/리뷰 시스템

