import 'dart:io';

void main() {
  final file = File('lib/main.dart');
  var content = file.readAsStringSync();

  // Fix _showPurchaseConfirmation
  final purchaseConfirmStart = content.indexOf('void _showPurchaseConfirmation');
  if (purchaseConfirmStart != -1) {
    final purchaseConfirmEnd = content.indexOf('  }', purchaseConfirmStart + 100) + 3;
    final newMethod = '''  void _showPurchaseConfirmation(BuildContext context, String productName, String price) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('상품 교환', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          '[\$productName]\\n\\n이 상품을 \$price에 교환하시겠습니까?\\n교환 후 포인트가 즉시 차감됩니다.',
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('[\$productName] 교환 신청이 완료되었습니다.'), behavior: SnackBarBehavior.floating),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
            child: const Text('교환하기', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }''';
    
    // We need to be careful with the replacement.
    // I'll use a more surgical approach.
  }
  
  // Actually, I'll just use a simpler script that replaces the whole file content if it can.
  // But wait, I'll just fix the corrupted strings specifically.
  
  // Fix the multi-line string in _showPurchaseConfirmation specifically.
  content = content.replaceAll(RegExp(r"content: Text\(\s+'\[\$productName\]\s+[\s\S]+?교환\?시겠습\?까\?\s+교환 \?\?\?인\?\?\s+즉시 차감\?니\?\?',"), 
    "content: Text('[\$productName]\\n\\n이 상품을 \$price에 교환하시겠습니까?\\n교환 후 포인트가 즉시 차감됩니다.',");

  file.writeAsStringSync(content);
  print('Fixed purchase confirmation dialog.');
}
