import 'package:flutter/material.dart';
import '../models/post_data.dart';
import '../core/app_state.dart';
import 'channel_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descAController = TextEditingController();
  final TextEditingController _descBController = TextEditingController();
  final TextEditingController _descController = TextEditingController(); // 상세설명 그대로 유지
  final TextEditingController _tagsController = TextEditingController();

  String? _imagePathA;
  String? _imagePathB;
  int _selectedHours = 24;
  int _selectedMinutes = 0;
  bool _useTargetPick = false;
  final TextEditingController _targetPickController = TextEditingController(text: '100');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('새 질문 하기', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _handleUpload,
            child: const Text('등록', style: TextStyle(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 질문 제목 블록
              _cardBlock(
                title: '질문 제목',
                child: _inputField(_titleController, '무엇이 더 나은지 물어보세요'),
              ),
              const SizedBox(height: 16),

            // 비교 대상 및 설명 블록
            _cardBlock(
              title: '비교 대상 업로드',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _abUploadCard('A', _imagePathA, (path) => setState(() => _imagePathA = path))),
                      const SizedBox(width: 12),
                      Expanded(child: _abUploadCard('B', _imagePathB, (path) => setState(() => _imagePathB = path))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _inputField(_descAController, 'A 설명 (예: 빨강)', isSmall: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _inputField(_descBController, 'B 설명 (예: 파랑)', isSmall: true)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 상세 설명 블록
            _cardBlock(
              title: '상세 설명 (선택)',
              child: _inputField(_descController, '질문에 대해 더 자세히 알려주세요...', maxLines: 3),
            ),
            const SizedBox(height: 16),

            // 진행 시간 및 목표 Pick 블록 (중요 설정 덩어리)
            _cardBlock(
              title: '진행 설정',
              child: Column(
                children: [
                  _durationPicker(),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: Colors.white10, height: 1),
                  ),
                  _targetPickSelector(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 태그 블록
            _cardBlock(
              title: '태그',
              child: _inputField(_tagsController, '#데일리룩 #패션 #추천 (내부 검색용)'),
            ),
            const SizedBox(height: 32),

            _precautionsBlock(),
            const SizedBox(height: 32),

            // 하단 대형 등록 버튼
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _handleUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('질문 등록하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  );
}

  Widget _cardBlock({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  void _handleUpload() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('제목을 입력해주세요.')));
      return;
    }
    
    final int totalMinutes = (_selectedHours * 60) + _selectedMinutes;
    final int? targetCount = _useTargetPick ? (int.tryParse(_targetPickController.text) ?? 100) : null;

    final newPost = PostData(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      uploaderId: gNameText,
      uploaderImage: gProfileImage,
      title: _titleController.text,
      fullDescription: _descController.text,
      timeLocation: '방금 전 · 서울',
      imageA: _imagePathA ?? 'https://picsum.photos/seed/a/800/1000',
      imageB: _imagePathB ?? 'https://picsum.photos/seed/b/800/1000',
      descriptionA: _descAController.text.isEmpty ? '선택지 A' : _descAController.text,
      descriptionB: _descBController.text.isEmpty ? '선택지 B' : _descBController.text,
      tags: _tagsController.text.split(RegExp(r'[#,\s]+')).where((t) => t.isNotEmpty).toList(),
      durationMinutes: totalMinutes,
      targetPickCount: targetCount,
      likesCount: 0,
      commentsCount: 0,
      voteCountA: '0',
      voteCountB: '0',
      percentA: '0%',
      percentB: '0%',
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ChannelScreen(
        uploaderId: newPost.uploaderId,
        allPosts: [newPost], 
        initialPost: newPost,
      )),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${_titleController.text}" 질문이 등록되었습니다!'),
        backgroundColor: Colors.cyanAccent.withValues(alpha: 0.9),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title, 
      style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: -0.5)
    );
  }

  Widget _inputField(TextEditingController controller, String hint, {int maxLines = 1, bool isSmall = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(isSmall ? 15 : 20),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: Colors.white, fontSize: isSmall ? 13 : 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _abUploadCard(String label, String? path, Function(String) onPick) {
    return GestureDetector(
      onTap: () => onPick('https://picsum.photos/seed/${label.toLowerCase()}${DateTime.now().millisecondsSinceEpoch}/800/1000'),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            image: path != null ? DecorationImage(image: NetworkImage(path), fit: BoxFit.cover) : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (path == null) ...[
                Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.03), fontSize: 80, fontWeight: FontWeight.w900)),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo_outlined, color: Colors.cyanAccent, size: 32),
                    const SizedBox(height: 8),
                    Text('$label 업로드', style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
              if (path != null)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.refresh, color: Colors.white, size: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _durationPicker() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('시간 선택', style: TextStyle(color: Colors.white38, fontSize: 11)),
              DropdownButton<int>(
                value: _selectedHours,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E1E1E),
                underline: const SizedBox(),
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white24),
                items: List.generate(73, (i) => i).map((i) => DropdownMenuItem(
                  value: i,
                  child: Text('$i시간', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                )).toList(),
                onChanged: (val) => setState(() => _selectedHours = val ?? 0),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('분 선택', style: TextStyle(color: Colors.white38, fontSize: 11)),
              DropdownButton<int>(
                value: _selectedMinutes,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E1E1E),
                underline: const SizedBox(),
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white24),
                items: List.generate(60, (i) => i).map((i) => DropdownMenuItem(
                  value: i,
                  child: Text('$i분', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                )).toList(),
                onChanged: (val) => setState(() => _selectedMinutes = val ?? 0),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _targetPickSelector() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('목표 Pick 조기 마감', style: TextStyle(color: Colors.white, fontSize: 14)),
            Switch(
              value: _useTargetPick, 
              onChanged: (v) => setState(() => _useTargetPick = v),
              activeTrackColor: Colors.cyanAccent.withValues(alpha: 0.3),
              activeThumbColor: Colors.cyanAccent,
            ),
          ],
        ),
        if (_useTargetPick)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.ads_click_outlined, color: Colors.white38, size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _targetPickController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: '목표 숫자 입력',
                      hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const Text('Pick 도달 시 마감', style: TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _precautionsBlock() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white38, size: 16),
              SizedBox(width: 8),
              Text('업로드 시 주의사항', style: TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 8),
          Text('• 타인의 저작권을 침해하거나 불쾌감을 주는 콘텐츠는 제재될 수 있습니다.', style: TextStyle(color: Colors.white24, fontSize: 11)),
          Text('• 허위 사실 유포나 부적절한 태그 사용 시 게시물이 삭제될 수 있습니다.', style: TextStyle(color: Colors.white24, fontSize: 11)),
          Text('• 진행 시간은 등록 후 수정이 불가능하니 신중히 선택해주세요.', style: TextStyle(color: Colors.white24, fontSize: 11)),
        ],
      ),
    );
  }
}
