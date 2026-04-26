import 'dart:io';

void main() {
  final file = File('lib/main.dart');
  final lines = file.readAsLinesSync();

  int startIndex = -1;
  int endIndex = -1;

  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('Widget _buildTopFixedUI() {')) {
      startIndex = i;
    }
    if (startIndex != -1 && lines[i].contains('Widget _buildBottomFixedUI() {')) {
      endIndex = i;
      break;
    }
  }

  if (startIndex != -1 && endIndex != -1) {
    final newUI = [
      '  Widget _buildTopFixedUI() {',
      '    return SafeArea(',
      '      child: Column(',
      '        mainAxisSize: MainAxisSize.min,',
      '        children: [',
      '          Padding(',
      '            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),',
      '            child: Row(',
      '              mainAxisAlignment: MainAxisAlignment.spaceBetween,',
      '              children: [',
      '                Image.asset(',
      "                  'assets/logo.png',",
      '                  height: 28,',
      "                  errorBuilder: (context, error, stackTrace) => const Text('PickGet', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 24, fontStyle: FontStyle.italic)),",
      '                ),',
      '                Row(',
      '                  children: [',
      '                    GestureDetector(',
      '                      onTap: () {',
      '                        Navigator.push(',
      '                          context,',
      '                          MaterialPageRoute(builder: (context) => PointScreen(currentPoints: _userPoints)),',
      '                        );',
      '                      },',
      '                      child: Container(',
      '                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),',
      '                        decoration: BoxDecoration(',
      '                          color: Colors.black.withOpacity(0.5),',
      '                          borderRadius: BorderRadius.circular(20),',
      '                        ),',
      '                        child: Row(',
      '                          children: [',
      "                            const Text('P', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16)),",
      '                            const SizedBox(width: 4),',
      '                            Text(_formatPoints(_userPoints), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),',
      '                          ],',
      '                        ),',
      '                      ),',
      '                    ),',
      '                    const SizedBox(width: 12),',
      '                    GestureDetector(',
      '                      onTap: () {',
      '                        Navigator.push(',
      '                          context,',
      '                          MaterialPageRoute(builder: (context) => SearchScreen(posts: _allPosts)),',
      '                        );',
      '                      },',
      '                      child: const Icon(Icons.search, color: Colors.white, size: 28),',
      '                    ),',
      '                  ],',
      '                ),',
      '              ],',
      '            ),',
      '          ),',
      '          const SizedBox(height: 10),',
      '          Row(',
      '            mainAxisAlignment: MainAxisAlignment.center,',
      '            children: [',
      "              _buildTabButton('추천', FeedTab.recommend),",
      '              const SizedBox(width: 8),',
      "              _buildTabButton('팔로잉', FeedTab.following),",
      '              const SizedBox(width: 8),',
      "              _buildTabButton('최근', FeedTab.bookmark),",
      '              const SizedBox(width: 8),',
      "              _buildTabButton('Pick', FeedTab.pick),",
      '            ],',
      '          ),',
      '        ],',
      '      ),',
      '    );',
      '  }',
      '',
      '  Widget _buildTabButton(String text, FeedTab tab) {',
      '    bool isSelected = _currentTab == tab;',
      '    return GestureDetector(',
      '      onTap: () => _onTabTapped(tab),',
      '      child: Column(',
      '        mainAxisSize: MainAxisSize.min,',
      '        children: [',
      '          Container(',
      '            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),',
      '            decoration: BoxDecoration(',
      '              color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,',
      '              borderRadius: BorderRadius.circular(20),',
      '            ),',
      '            child: Text(',
      '              text,',
      '              style: TextStyle(',
      '                color: isSelected ? Colors.white : Colors.white60,',
      '                fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,',
      '                fontSize: 15,',
      '              ),',
      '            ),',
      '          ),',
      '          const SizedBox(height: 4),',
      '          AnimatedContainer(',
      '            duration: const Duration(milliseconds: 200),',
      '            width: isSelected ? 20 : 0,',
      '            height: 3,',
      '            decoration: BoxDecoration(',
      '              color: Colors.cyanAccent,',
      '              borderRadius: BorderRadius.circular(2),',
      '              boxShadow: [',
      '                if (isSelected) BoxShadow(color: Colors.cyanAccent.withOpacity(0.5), blurRadius: 4, spreadRadius: 1),',
      '              ],',
      '            ),',
      '          ),',
      '        ],',
      '      ),',
      '    );',
      '  }',
      ''
    ];

    lines.replaceRange(startIndex, endIndex, newUI);
    file.writeAsStringSync(lines.join('\n'));
    print('Fixed top UI and tab buttons.');
  } else {
    print('Could not find _buildTopFixedUI or _buildBottomFixedUI.');
  }
}
