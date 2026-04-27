import 'package:flutter/material.dart';

class StoreScreen extends StatefulWidget {
  final int userPoints;
  const StoreScreen({super.key, required this.userPoints});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _bankController = TextEditingController();
  final TextEditingController _holderController = TextEditingController();
  String _selectedCategory = '커피';
  
  bool _isWithdrawalPending = false;
  int _pendingAmount = 0;

  final Map<String, List<Map<String, String>>> _categoryProducts = {
    '커피': [
      {'title': '[스타벅스] 아메리카노 T', 'price': '4,500 P', 'brand': '스타벅스'},
      {'title': '[투썸플레이스] 카페라떼 R', 'price': '5,000 P', 'brand': '투썸플레이스'},
      {'title': '[메가커피] 아메리카노(HOT)', 'price': '1,500 P', 'brand': '메가커피'},
    ],
    '편의점': [
      {'title': '[GS25] 모바일 상품권 5,000원', 'price': '5,000 P', 'brand': 'GS25'},
      {'title': '[CU] 모바일 상품권 3,000원', 'price': '3,000 P', 'brand': 'CU'},
      {'title': '[7-Eleven] 바나나우유', 'price': '1,700 P', 'brand': '7-Eleven'},
    ],
    '상품권': [
      {'title': '문화상품권 5,000원권', 'price': '5,000 P', 'brand': '컬쳐랜드'},
      {'title': '구글 기프트카드 1만원', 'price': '10,000 P', 'brand': 'Google'},
    ],
    '문화': [
      {'title': 'CGV 1인 영화관람권', 'price': '13,000 P', 'brand': 'CGV'},
      {'title': '롯데시네마 영화예매권', 'price': '12,000 P', 'brand': '롯데시네마'},
      {'title': '교보문고 기프트카드 1만원', 'price': '10,000 P', 'brand': '교보문고'},
    ],
    '외식': [
      {'title': '[아웃백] 5만원권', 'price': '50,000 P', 'brand': '아웃백'},
      {'title': '[VIPS] 평일 런치 1인', 'price': '32,000 P', 'brand': 'VIPS'},
    ],
    '기타': [
      {'title': '네이버페이 포인트 5,000원', 'price': '5,000 P', 'brand': '네이버'},
      {'title': '카카오톡 이모티콘 구매권', 'price': '2,500 P', 'brand': '카카오'},
    ],
  };

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    _bankController.dispose();
    _holderController.dispose();
    super.dispose();
  }

  void _showWithdrawalDialog() {
    String? localError; // 팝업 내부용 에러 메시지 변수

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            decoration: const BoxDecoration(
              color: Color(0xFF1C1C1C),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('현금 인출 신청', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white38, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 입력 필드들 (간격 축소)
                  Row(
                    children: [
                      Expanded(child: _inputFieldCompact('은행명', _bankController, '예: 카카오뱅크', TextInputType.text)),
                      const SizedBox(width: 12),
                      Expanded(child: _inputFieldCompact('예금주', _holderController, '실명 입력', TextInputType.text)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _inputFieldCompact('계좌번호', _accountController, '하이픈(-) 없이 입력', TextInputType.number),
                  const SizedBox(height: 12),
                  _inputFieldCompact('인출 포인트 (최소 10,000P)', _amountController, '5,000P 단위로 입력', TextInputType.number),
                  
                  const SizedBox(height: 16),
                  
                  // 주의사항 (더 컴팩트하게)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '• 본인 명의 계좌 필수 / 승인까지 최대 3일 소요\n• 5,000P 단위 신청 가능 (최대 30,000P)',
                      style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.5),
                    ),
                  ),

                  const SizedBox(height: 20),
                  
                  // 내부 에러 메시지 표시 영역
                  if (localError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Center(
                        child: Text(
                          localError!, 
                          style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)
                        ),
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        final int? amount = int.tryParse(_amountController.text);
                        String? error;

                        if (_amountController.text.isEmpty || _holderController.text.isEmpty || _accountController.text.isEmpty || _bankController.text.isEmpty) {
                          error = '모든 정보를 입력해주세요.';
                        } else if (amount == null || amount < 10000) {
                          error = '최소 10,000P부터 인출 가능합니다.';
                        } else if (amount % 5000 != 0) {
                          error = '5,000P 단위로만 신청 가능합니다.';
                        } else if (amount > widget.userPoints) {
                          error = '보유하신 포인트가 부족합니다.';
                        }

                        if (error != null) {
                          setSheetState(() => localError = error);
                          return;
                        }

                        setState(() {
                          _isWithdrawalPending = true;
                          _pendingAmount = amount!;
                        });
                        
                        Navigator.pop(context);

                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF1E1E1E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text('신청 완료', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            content: const Text('현금 인출 신청이 완료되었습니다.\n관리자 확인 후 최대 3일 이내에 입금됩니다.', style: TextStyle(color: Colors.white70)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('확인', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('신청하기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                  SizedBox(height: 20 + MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputFieldCompact(String label, TextEditingController controller, String hint, TextInputType type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: type,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white12, fontSize: 13),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('포인트 스토어', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFF0F0F0F),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1C),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _isWithdrawalPending ? Colors.cyanAccent.withValues(alpha: 0.5) : Colors.cyanAccent.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(_isWithdrawalPending ? Icons.sync : Icons.stars, color: Colors.cyanAccent, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isWithdrawalPending ? '인출 신청 진행 중' : '현금 인출하기', 
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isWithdrawalPending ? '신청금액: ${_pendingAmount}P (승인 대기)' : '보유 포인트를 현금으로 전환', 
                                style: TextStyle(color: _isWithdrawalPending ? Colors.cyanAccent : Colors.white38, fontSize: 12)
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _isWithdrawalPending ? null : _showWithdrawalDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isWithdrawalPending ? Colors.grey[800] : Colors.cyanAccent,
                            foregroundColor: _isWithdrawalPending ? Colors.white24 : Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            minimumSize: const Size(0, 36),
                          ),
                          child: Text(
                            _isWithdrawalPending ? '신청중' : '인출신청', 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1C),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MyCouponsScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Icon(Icons.confirmation_num_outlined, color: Colors.cyanAccent, size: 20),
                            SizedBox(width: 12),
                            Expanded(child: Text('내 쿠폰함', style: TextStyle(color: Colors.white70, fontSize: 14))),
                            Row(
                              children: [
                                Text('2', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                                Icon(Icons.chevron_right, color: Colors.white24, size: 20),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: _categoryProducts.keys.map((cat) => _categoryTab(cat)).toList(),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _categoryProducts[_selectedCategory]!.length,
                itemBuilder: (context, index) {
                  final product = _categoryProducts[_selectedCategory]![index];
                  return _productCard(product);
                },
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _categoryTab(String label) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label, 
          style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)
        ),
      ),
    );
  }

  Widget _productCard(Map<String, String> product) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Center(child: Icon(Icons.redeem, color: Colors.white10, size: 40)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['brand']!, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                const SizedBox(height: 4),
                Text(product['title']!, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text(product['price']!, style: const TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MyCouponsScreen extends StatefulWidget {
  const MyCouponsScreen({super.key});

  @override
  State<MyCouponsScreen> createState() => _MyCouponsScreenState();
}

class _MyCouponsScreenState extends State<MyCouponsScreen> {
  final List<Map<String, dynamic>> _coupons = [
    {'title': '[GS25] 모바일 상품권 5,000원', 'date': '2026.12.31까지', 'brand': 'GS25', 'isUsed': false, 'type': 'barcode'},
    {'title': '[CU] 모바일 상품권 3,000원', 'date': '2026.11.15까지', 'brand': 'CU', 'isUsed': false, 'type': 'qr'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('내 쿠폰함', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _coupons.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final coupon = _coupons[index];
          final bool isUsed = coupon['isUsed'];

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Opacity(
                  opacity: isUsed ? 0.3 : 1.0,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      coupon['type'] == 'barcode' ? Icons.barcode_reader : Icons.qr_code_2,
                      color: Colors.cyanAccent,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(coupon['title']!,
                          style: TextStyle(
                            color: isUsed ? Colors.white38 : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            decoration: isUsed ? TextDecoration.lineThrough : null,
                          )),
                      const SizedBox(height: 6),
                      Text('유효기간: ${coupon['date']}',
                          style: TextStyle(color: Colors.white.withValues(alpha: isUsed ? 0.2 : 0.4), fontSize: 12)),
                    ],
                  ),
                ),
                if (isUsed)
                  const Text('사용완료', style: TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.bold))
                else
                  ElevatedButton(
                    onPressed: () => _showBarcodeDialog(context, index, coupon['title']!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('사용하기', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showBarcodeDialog(BuildContext context, int index, String title) {
    final coupon = _coupons[index];
    final String type = coupon['type'] ?? 'barcode';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black12),
              ),
              child: type == 'barcode' 
                ? Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(20, (index) => Container(
                          width: index % 3 == 0 ? 4 : 2,
                          height: 80,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          color: Colors.black,
                        )),
                      ),
                      const SizedBox(height: 10),
                      const Text('1234 - 5678 - 9012', style: TextStyle(color: Colors.black, letterSpacing: 2, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  )
                : Column(
                    children: [
                      const Icon(Icons.qr_code_2, size: 100, color: Colors.black),
                      const SizedBox(height: 10),
                      const Text('QR-9876-5432-10', style: TextStyle(color: Colors.black, letterSpacing: 1, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
            ),
            const SizedBox(height: 20),
            Text(
              type == 'barcode' ? '매장 점원에게 바코드를 보여주세요.' : '매장 스캐너에 QR코드를 스캔해주세요.',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.black.withValues(alpha: 0.1)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showConfirmUsedDialog(context, index);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('사용 완료 처리하기', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmUsedDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('사용 완료 처리', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('정말로 사용 완료 처리하시겠습니까?\n한 번 완료하면 되돌릴 수 없습니다.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () {
              setState(() {
                _coupons[index]['isUsed'] = true;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('사용 완료 처리되었습니다.'), duration: Duration(seconds: 2)),
              );
            },
            child: const Text('확인', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
