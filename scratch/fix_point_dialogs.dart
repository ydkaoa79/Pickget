import 'dart:io';

void main() {
  final file = File('lib/main.dart');
  final lines = file.readAsLinesSync();

  int startIndex = -1;
  int endIndex = -1;

  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('void _showPointPolicyDialog()')) {
      startIndex = i;
    }
    if (startIndex != -1 && lines[i].contains('Widget _buildStoreSection()')) {
      endIndex = i;
      break;
    }
  }

  if (startIndex != -1 && endIndex != -1) {
    final newMethods = [
      '  void _showPointPolicyDialog() {',
      '    showDialog(',
      '      context: context,',
      '      builder: (context) => AlertDialog(',
      '        backgroundColor: const Color(0xFF1C1C1C),',
      '        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),',
      "        title: const Text('포인트 유효기간 및 자동 소멸 정책 안내', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),",
      '        content: const SingleChildScrollView(',
      '          child: Column(',
      '            mainAxisSize: MainAxisSize.min,',
      '            crossAxisAlignment: CrossAxisAlignment.start,',
      '            children: [',
      '              Text(',
      "                '안녕하세요. 서비스를 이용해 주시는 회원님께 감사의 말씀을 드립니다.\\n\\n' ",
      "                '회원님의 소중한 포인트 관리 및 원활한 서비스 제공을 위해 포인트 유효기간 정책을 아래와 같이 안내드립니다.\\n\\n' ",
      "                '• 유효기간: 각 포인트 적립일로부터 1년 (365일)\\n\\n' ",
      "                '• 소멸 방식: 유효기간이 경과한 포인트는 해당 일자 자정에 자동으로 소멸됩니다.\\n\\n' ",
      "                '• 사용 원칙: 먼저 적립된 포인트가 먼저 사용되는 \\'선입선출\\' 방식으로 차감됩니다.\\n\\n' ",
      "                '• 사전 안내: 포인트 소멸 30일 전과 7일 전에 앱 알림을 통해 소멸 예정 포인트를 미리 안내해 드립니다.\\n\\n' ",
      "                '소멸된 포인트는 복구가 불가능하오니, 유효기간 내에 현금전환이나 상품 구매 등으로 알뜰하게 사용하시길 바랍니다.',",
      '                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),',
      '              ),',
      '            ],',
      '          ),',
      '        ),',
      '        actions: [',
      '          TextButton(',
      '            onPressed: () => Navigator.pop(context),',
      "            child: const Text('확인', style: TextStyle(color: Colors.cyanAccent)),",
      '          ),',
      '        ],',
      '      ),',
      '    );',
      '  }',
      '',
      '  void _showWithdrawalDialog() {',
      '    showDialog(',
      '      context: context,',
      '      builder: (context) => AlertDialog(',
      '        backgroundColor: const Color(0xFF1C1C1C),',
      '        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),',
      '        title: const Row(',
      '          children: [',
      '            Icon(Icons.account_balance_wallet, color: Colors.cyanAccent, size: 24),',
      '            SizedBox(width: 8),',
      "            Text('출금 신청', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),",
      '          ],',
      '        ),',
      '        content: SingleChildScrollView(',
      '          child: Column(',
      '            mainAxisSize: MainAxisSize.min,',
      '            children: [',
      "              _buildStoreTextField('출금 액수 (5,000원 단위)'),",
      '              const SizedBox(height: 12),',
      "              _buildStoreTextField('은행명'),",
      '              const SizedBox(height: 12),',
      "              _buildStoreTextField('계좌번호'),",
      '              const SizedBox(height: 12),',
      "              _buildStoreTextField('예금주 성함'),",
      '              const SizedBox(height: 16),',
      '              Container(',
      '                padding: const EdgeInsets.all(12),',
      '                decoration: BoxDecoration(',
      '                  color: Colors.white.withOpacity(0.05),',
      '                  borderRadius: BorderRadius.circular(12),',
      '                ),',
      '                child: Column(',
      '                  crossAxisAlignment: CrossAxisAlignment.start,',
      '                  children: [',
      "                    const Text('[현금 출금 안내]', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),",
      '                    const SizedBox(height: 6),',
      "                    _buildNoticeText('• 1회 최대 신청 금액: 30,000원'),",
      "                    _buildNoticeText('• 신청 횟수: 하루에 1회만 신청 가능합니다.'),",
      "                    _buildNoticeText('• 입금 소요 기간: 신청일로부터 영업일 기준 1~3일 이내에 입금됩니다.'),",
      '                  ],',
      '                ),',
      '              ),',
      '              const SizedBox(height: 20),',
      '              SizedBox(',
      '                width: double.infinity,',
      '                height: 50,',
      '                child: ElevatedButton(',
      '                  onPressed: () {',
      '                    Navigator.pop(context);',
      '                    ScaffoldMessenger.of(context).showSnackBar(',
      "                      const SnackBar(content: Text('출금 신청이 완료되었습니다.'), behavior: SnackBarBehavior.floating),",
      '                    );',
      '                  },',
      '                  style: ElevatedButton.styleFrom(',
      '                    backgroundColor: Colors.cyanAccent,',
      '                    foregroundColor: Colors.black,',
      '                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),',
      '                  ),',
      "                  child: const Text('출금 신청하기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),",
      '                ),',
      '              ),',
      '            ],',
      '          ),',
      '        ),',
      '      ),',
      '    );',
      '  }',
      ''
    ];

    lines.replaceRange(startIndex, endIndex, newMethods);
    file.writeAsStringSync(lines.join('\n'));
    print('Fixed PointScreen dialogs.');
  } else {
    print('Could not find _showPointPolicyDialog or _buildStoreSection.');
  }
}
