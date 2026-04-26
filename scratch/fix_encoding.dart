import 'dart:io';
import 'dart:convert';

void main() {
  final file = File('lib/main.dart');
  final lines = file.readAsLinesSync();

  // Fix Point Policy Dialog (Lines 2181-2206 approx)
  // We need to find the lines based on content since numbers might shift.
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('title: const Text(') && lines[i].contains('?인?')) {
      lines[i] = "        title: const Text('포인트 유효기간 및 자동 소멸 정책 안내', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),";
    }
    if (lines[i].contains('?녕?세??')) {
       lines[i] = "                '안녕하세요. 서비스를 이용해 주시는 회원님께 감사의 말씀을 드립니다.\\n\\n' "
                  " '회원님의 소중한 포인트 관리 및 원활한 서비스 제공을 위해 포인트 유효기간 정책을 아래와 같이 안내드립니다.\\n\\n' "
                  " '• 유효기간: 각 포인트 적립일로부터 1년 (365일)\\n\\n' "
                  " '• 소멸 방식: 유효기간이 경과한 포인트는 해당 일자 자정에 자동으로 소멸됩니다.\\n\\n' "
                  " '• 사용 원칙: 먼저 적립된 포인트가 먼저 사용되는 \\'선입선출\\' 방식으로 차감됩니다.\\n\\n' "
                  " '• 사전 안내: 포인트 소멸 30일 전과 7일 전에 앱 알림을 통해 소멸 예정 포인트를 미리 안내해 드립니다.\\n\\n' "
                  " '소멸된 포인트는 복구가 불가능하오니, 유효기간 내에 현금전환이나 상품 구매 등으로 알뜰하게 사용하시길 바랍니다.',";
    }
    if (lines[i].contains('?인') && lines[i].contains('TextButton')) {
       lines[i] = "            child: const Text('확인', style: TextStyle(color: Colors.cyanAccent)),";
    }
    
    // Fix Withdrawal Dialog
    if (lines[i].contains('Text(') && lines[i].contains('출금 ?청')) {
       lines[i] = "            Text('출금 신청', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),";
    }
    if (lines[i].contains('buildStoreTextField(') && lines[i].contains('출금 ?수')) {
       lines[i] = "              _buildStoreTextField('출금 액수 (5,000원 단위)'),";
    }
    if (lines[i].contains('buildStoreTextField(') && lines[i].contains('??명')) {
       lines[i] = "              _buildStoreTextField('은행명'),";
    }
    if (lines[i].contains('buildStoreTextField(') && lines[i].contains('?금??함')) {
       lines[i] = "              _buildStoreTextField('예금주 성함'),";
    }
    if (lines[i].contains('Text(') && lines[i].contains('[?전 ?청 ?내]')) {
       lines[i] = "                    const Text('[현금 출금 안내]', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),";
    }
    if (lines[i].contains('buildNoticeText(') && lines[i].contains('최? ?청 금액')) {
       lines[i] = "                    _buildNoticeText('• 1회 최대 신청 금액: 30,000원'),";
    }
    if (lines[i].contains('buildNoticeText(') && lines[i].contains('?청 ?수')) {
       lines[i] = "                    _buildNoticeText('• 신청 횟수: 하루에 1회만 신청 가능합니다.'),";
    }
    if (lines[i].contains('buildNoticeText(') && lines[i].contains('?금 ?요 기간')) {
       lines[i] = "                    _buildNoticeText('• 입금 소요 기간: 신청일로부터 영업일 기준 1~3일 이내에 입금됩니다.'),";
    }
    if (lines[i].contains('SnackBar(') && lines[i].contains('출금 ?청???료')) {
       lines[i] = "                      const SnackBar(content: Text('출금 신청이 완료되었습니다.'), behavior: SnackBarBehavior.floating),";
    }
    if (lines[i].contains('child: const Text(') && lines[i].contains('출금 ?청?기')) {
       lines[i] = "                  child: const Text('출금 신청하기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),";
    }
  }

  file.writeAsStringSync(lines.join('\\n'));
  print('Fixed point and withdrawal sections.');
}
