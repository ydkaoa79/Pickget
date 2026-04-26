import 'dart:io';

void main() {
  final file = File('lib/main.dart');
  final lines = file.readAsLinesSync();

  int startIndex = -1;
  int endIndex = -1;

  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('class CategoryProductScreen')) {
      startIndex = i;
    }
    if (startIndex != -1 && lines[i].contains('class PointHistoryItem')) {
      endIndex = i;
      break;
    }
  }

  if (startIndex != -1 && endIndex != -1) {
    final newClass = [
      'class CategoryProductScreen extends StatelessWidget {',
      '  final String categoryName;',
      '  const CategoryProductScreen({super.key, required this.categoryName});',
      '',
      '  @override',
      '  Widget build(BuildContext context) {',
      '    final List<Map<String, String>> products = List.generate(12, (index) => {',
      "      'brand': '\$categoryName 브랜드 \${index + 1}',",
      "      'name': '\$categoryName 상품 \${index + 1}',",
      "      'price': '\${(index + 1) * 1000} P',",
      '    });',
      '',
      '    return Scaffold(',
      '      backgroundColor: Colors.black,',
      '      appBar: AppBar(',
      '        backgroundColor: Colors.black,',
      '        elevation: 0,',
      '        leading: IconButton(',
      '          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),',
      '          onPressed: () => Navigator.pop(context),',
      '        ),',
      '        title: Text(categoryName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),',
      '        centerTitle: true,',
      '      ),',
      '      body: GridView.builder(',
      '        padding: const EdgeInsets.all(20),',
      '        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(',
      '          crossAxisCount: 2,',
      '          mainAxisSpacing: 20,',
      '          crossAxisSpacing: 16,',
      '          childAspectRatio: 0.75,',
      '        ),',
      '        itemCount: products.length,',
      '        itemBuilder: (context, index) {',
      '          final item = products[index];',
      '          return Container(',
      '            padding: const EdgeInsets.all(12),',
      '            decoration: BoxDecoration(',
      '              color: const Color(0xFF1C1C1C).withOpacity(0.8),',
      '              borderRadius: BorderRadius.circular(24),',
      '              border: Border.all(color: Colors.white.withOpacity(0.03)),',
      '            ),',
      '            child: Column(',
      '              crossAxisAlignment: CrossAxisAlignment.start,',
      '              children: [',
      '                Expanded(',
      '                  child: Container(',
      '                    width: double.infinity,',
      '                    decoration: BoxDecoration(',
      '                      color: Colors.white.withOpacity(0.03),',
      '                      borderRadius: BorderRadius.circular(16),',
      '                    ),',
      '                    child: const Icon(Icons.redeem, color: Colors.white12, size: 40),',
      '                  ),',
      '                ),',
      '                const SizedBox(height: 12),',
      "                Text(item['brand']!, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),",
      '                const SizedBox(height: 4),',
      "                Text(item['name']!, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),",
      '                const SizedBox(height: 8),',
      '                Row(',
      '                  mainAxisAlignment: MainAxisAlignment.spaceBetween,',
      '                  children: [',
      "                    Text(item['price']!, style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold)),",
      '                    ElevatedButton(',
      "                      onPressed: () => _showPurchaseConfirmation(context, item['name']!, item['price']!),",
      '                      style: ElevatedButton.styleFrom(',
      '                        backgroundColor: Colors.cyanAccent.withOpacity(0.1),',
      '                        foregroundColor: Colors.cyanAccent,',
      '                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),',
      '                        minimumSize: Size.zero,',
      '                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,',
      '                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.cyanAccent, width: 0.5)),',
      '                        elevation: 0,',
      '                      ),',
      "                      child: const Text('교환', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),",
      '                    ),',
      '                  ],',
      '                ),',
      '              ],',
      '            ),',
      '          );',
      '        },',
      '      ),',
      '    );',
      '  }',
      '',
      '  void _showPurchaseConfirmation(BuildContext context, String productName, String price) {',
      '    showDialog(',
      '      context: context,',
      '      builder: (context) => AlertDialog(',
      '        backgroundColor: const Color(0xFF1C1C1C),',
      '        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),',
      "        title: const Text('상품 교환', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),",
      '        content: Text(',
      "          '[\$productName]\\n\\n이 상품을 \$price에 교환하시겠습니까?\\n교환 후 포인트가 즉시 차감됩니다.',",
      '          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),',
      '        ),',
      '        actions: [',
      '          TextButton(',
      '            onPressed: () => Navigator.pop(context),',
      "            child: const Text('취소', style: TextStyle(color: Colors.white38)),",
      '          ),',
      '          ElevatedButton(',
      '            onPressed: () {',
      '              Navigator.pop(context);',
      '              ScaffoldMessenger.of(context).showSnackBar(',
      "                SnackBar(content: Text('[\$productName] 교환 신청이 완료되었습니다.'), behavior: SnackBarBehavior.floating),",
      '              );',
      '            },',
      '            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),',
      "            child: const Text('교환하기', style: TextStyle(fontWeight: FontWeight.bold)),",
      '          ),',
      '        ],',
      '      ),',
      '    );',
      '  }',
      '}',
      ''
    ];

    lines.replaceRange(startIndex, endIndex, newClass);
    file.writeAsStringSync(lines.join('\n'));
    print('Fixed CategoryProductScreen.');
  } else {
    print('Could not find CategoryProductScreen or PointHistoryItem.');
  }
}
