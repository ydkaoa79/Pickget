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
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  bool _isAdultContent = false;
  bool _isAIContent = false;
  bool _allowComments = true;

  int _selectedHours = 24;
  int _selectedMinutes = 0;
  bool _useTargetGoal = false;
  final TextEditingController _targetVotesController = TextEditingController(text: '100');

  String? _imagePathA;
  String? _imagePathB;

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
            onPressed: () {
              final newPost = PostData(
                id: 'post_${DateTime.now().millisecondsSinceEpoch}',
                uploaderId: gNameText,
                uploaderImage: gProfileImage,
                title: _titleController.text,
                fullDescription: _descController.text,
                timeLocation: '방금 전 · 서울',
                imageA: _imagePathA ?? 'https://picsum.photos/seed/a/800/1000',
                imageB: _imagePathB ?? 'https://picsum.photos/seed/b/800/1000',
                descriptionA: '선택지 A',
                descriptionB: '선택지 B',
                shortDescA: _descAController.text,
                shortDescB: _descBController.text,
                tags: _tagsController.text.split(RegExp(r'[#,\s]+')).where((t) => t.isNotEmpty).toList(),
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
                  content: Text('"${_titleController.text}" 질문이 내 채널에 등록되었습니다!'),
                  backgroundColor: Colors.cyanAccent.withValues(alpha: 0.9),
                ),
              );
            },
            child: const Text('등록', style: TextStyle(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _contentBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('질문 제목', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: '무엇이 더 나은지 물어보세요',
                      hintStyle: TextStyle(color: Colors.white24, fontSize: 16),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _imagePickerBlock('A', _imagePathA, (path) => setState(() => _imagePathA = path))),
                const SizedBox(width: 12),
                Expanded(child: _imagePickerBlock('B', _imagePathB, (path) => setState(() => _imagePathB = path))),
              ],
            ),
            const SizedBox(height: 16),
             _contentBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('상세 설명 (선택)', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                  TextField(
                    controller: _descController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: const InputDecoration(
                      hintText: '질문에 대해 더 자세히 알려주세요...',
                      hintStyle: TextStyle(color: Colors.white24, fontSize: 15),
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _contentBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('태그', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                  TextField(
                    controller: _tagsController,
                    style: const TextStyle(color: Colors.cyanAccent, fontSize: 15),
                    decoration: const InputDecoration(
                      hintText: '#데일리룩 #패션 #추천',
                      hintStyle: TextStyle(color: Colors.white24, fontSize: 15),
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _settingsBlock(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _contentBlock({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }

  Widget _imagePickerBlock(String label, String? path, Function(String) onPick) {
    return GestureDetector(
      onTap: () => onPick('https://picsum.photos/seed/${label.toLowerCase()}/800/1000'),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          image: path != null ? DecorationImage(image: NetworkImage(path), fit: BoxFit.cover) : null,
        ),
        child: path == null ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_photo_alternate_outlined, color: Colors.white38, size: 32),
            const SizedBox(height: 8),
            Text('이미지 $label', style: const TextStyle(color: Colors.white38, fontSize: 14)),
          ],
        ) : null,
      ),
    );
  }

  Widget _settingsBlock() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _settingItem(Icons.timer_outlined, '진행 기간', '${_selectedHours}시간 00분'),
          _settingItem(Icons.ads_click_outlined, '목표 참여수', _useTargetGoal ? '${_targetVotesController.text}명' : '무제한'),
          _settingItem(Icons.comment_outlined, '댓글 허용', _allowComments ? '예' : '아니오', isToggle: true, toggleValue: _allowComments, onChanged: (v) => setState(() => _allowComments = v)),
          _settingItem(Icons.psychology_outlined, 'AI 생성 콘텐츠', _isAIContent ? '예' : '아니오', isToggle: true, toggleValue: _isAIContent, onChanged: (v) => setState(() => _isAIContent = v)),
          _settingItem(Icons.explicit_outlined, '성인 콘텐츠', _isAdultContent ? '예' : '아니오', isToggle: true, toggleValue: _isAdultContent, onChanged: (v) => setState(() => _isAdultContent = v)),
        ],
      ),
    );
  }

  Widget _settingItem(IconData icon, String title, String displayValue, {bool isToggle = false, bool toggleValue = false, Function(bool)? onChanged}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white60, size: 20),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      trailing: isToggle ? Switch(
        value: toggleValue, 
        onChanged: onChanged,
        activeColor: Colors.cyanAccent,
      ) : Text(displayValue, style: const TextStyle(color: Colors.white38, fontSize: 14)),
    );
  }
}
