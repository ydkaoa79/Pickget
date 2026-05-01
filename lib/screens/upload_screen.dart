import 'package:flutter/material.dart';
import '../models/post_data.dart';
import '../core/app_state.dart';
import 'channel_screen.dart';
import 'video_trim_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../services/cloudflare_service.dart';
import '../services/supabase_service.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/media_compressor.dart';
import 'package:path/path.dart' as p;

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
  String? _thumbPathA; // 🎬 영상 썸네일 경로 추가!
  String? _thumbPathB;
  int _selectedHours = 24;
  int _selectedMinutes = 0;
  bool _useTargetPick = false;
  final TextEditingController _targetPickController = TextEditingController(text: '100');
  
  bool _isAdult = false; // 🔞 성인 콘텐츠 여부
  bool _isAI = false;    // 🤖 AI 생성 여부
  
  final ImagePicker _picker = ImagePicker();
  final CloudflareService _cloudflareService = CloudflareService();
  bool _isUploading = false;

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
          _isUploading 
            ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent))))
            : TextButton(
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

            // 🔞 성인/AI 콘텐츠 설정 (주의사항 바로 위!)
            _cardBlock(
              title: '콘텐츠 설정',
              child: _safetyOptions(),
            ),
            const SizedBox(height: 16),

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

  Future<void> _handleUpload() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('제목을 입력해주세요.')));
      return;
    }
    
    if (_imagePathA == null || _imagePathB == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('두 개의 이미지를 모두 업로드해주세요.')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      // 🚀 1. 이미지/영상 압축 (파일 성격에 맞춰서!)
      File fileA = File(_imagePathA!);
      File fileB = File(_imagePathB!);

      bool isVideoA = _isVideo(_imagePathA!);
      bool isVideoB = _isVideo(_imagePathB!);

      File? compressedA = isVideoA ? await MediaCompressor.compressVideo(fileA) : await MediaCompressor.compressImage(fileA);
      File? compressedB = isVideoB ? await MediaCompressor.compressVideo(fileB) : await MediaCompressor.compressImage(fileB);

      // 2. R2 업로드 (확장자 똑똑하게 챙기기!)
      final String timestamp = DateTime.now().microsecondsSinceEpoch.toString();
      final String randomStr = (DateTime.now().millisecond % 1000).toString().padLeft(3, '0');
      
      String extA = p.extension(_imagePathA!).toLowerCase();
      String extB = p.extension(_imagePathB!).toLowerCase();

      String? urlA = await _cloudflareService.uploadFile(
        compressedA ?? fileA, 
        'post_${timestamp}_${randomStr}_A$extA'
      );
      String? urlB = await _cloudflareService.uploadFile(
        compressedB ?? fileB, 
        'post_${timestamp}_${randomStr}_B$extB'
      );

      // 🚀 썸네일 업로드 추가 (존재할 경우)
      String? thumbUrlA;
      if (_thumbPathA != null) {
        thumbUrlA = await _cloudflareService.uploadFile(File(_thumbPathA!), 'post_${timestamp}_${randomStr}_thumbA.jpg');
      }
      String? thumbUrlB;
      if (_thumbPathB != null) {
        thumbUrlB = await _cloudflareService.uploadFile(File(_thumbPathB!), 'post_${timestamp}_${randomStr}_thumbB.jpg');
      }

      if (urlA == null || urlB == null) {
        throw Exception('파일 업로드 실패');
      }

      // 2. Insert into Supabase
      final int totalMinutes = (_selectedHours * 60) + _selectedMinutes;
      final int? targetCount = _useTargetPick ? (int.tryParse(_targetPickController.text) ?? 100) : null;
      final List<String> finalTags = _tagsController.text.split(RegExp(r'[#,\s]+')).where((t) => t.isNotEmpty).toList();
      // Trick: Store duration and target count in tags since columns are missing
      finalTags.add('duration:$totalMinutes');
      if (targetCount != null) finalTags.add('target:$targetCount');
      if (_isAdult) finalTags.add('adult:true'); // 🔞 성인 태그 추가
      if (_isAI) finalTags.add('ai:true');       // 🤖 AI 태그 추가

      final response = await SupabaseService.client.from('posts').insert({
        'title': _titleController.text,
        'uploader_id': gIdText,
        'uploader_internal_id': gUserInternalId, // 주민번호 시스템 도입!
        'image_a': urlA,
        'image_b': urlB,
        if (thumbUrlA != null) 'thumb_a': thumbUrlA,
        if (thumbUrlB != null) 'thumb_b': thumbUrlB,
        'description_a': _descAController.text.isEmpty ? '선택지 A' : _descAController.text,
        'description_b': _descBController.text.isEmpty ? '선택지 B' : _descBController.text,
        'tags': finalTags,
      }).select().single();

      final newPost = PostData(
        id: response['id'].toString(),
        uploaderId: gIdText,
        uploaderInternalId: gUserInternalId, // 🆔 등록 시 주민번호 기록!
        uploaderName: gNameText,
        uploaderImage: gProfileImage,
        title: _titleController.text,
        fullDescription: _descController.text,
        timeLocation: '방금 전',
        imageA: urlA,
        imageB: urlB,
        thumbA: thumbUrlA,
        thumbB: thumbUrlB,
        descriptionA: _descAController.text.isEmpty ? '선택지 A' : _descAController.text,
        descriptionB: _descBController.text.isEmpty ? '선택지 B' : _descBController.text,
        tags: finalTags,
        durationMinutes: totalMinutes,
        targetPickCount: targetCount,
        likesCount: 0,
        commentsCount: 0,
        voteCountA: '0',
        voteCountB: '0',
        percentA: '0%',
        percentB: '0%',
      );

      if (mounted) {
        // Return the new post to the previous screen (ChannelScreen) so it can be added to the list
        Navigator.pop(context, newPost);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${_titleController.text}" 질문이 등록되었습니다!'),
            backgroundColor: Colors.cyanAccent.withValues(alpha: 0.9),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('등록 실패: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  bool _isVideo(String url) {
    final path = url.toLowerCase();
    return path.endsWith('.mp4') || 
           path.endsWith('.mov') || 
           path.endsWith('.m4v') || 
           path.endsWith('.avi') || 
           path.endsWith('.wmv') || 
           path.endsWith('.mkv') || 
           path.endsWith('.3gp');
  }

  void _showImageSourceActionSheet(String label, Function(String) onPick) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('업로드 방식 선택', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.cyanAccent),
              title: const Text('사진 찍기 (카메라)', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                if (image != null) _handlePickedMedia(image.path, label, onPick, isVideo: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.cyanAccent),
              title: const Text('갤러리에서 사진 선택', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                if (image != null) _handlePickedMedia(image.path, label, onPick, isVideo: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.redAccent),
              title: const Text('갤러리에서 영상 선택', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
                if (video != null) _handlePickedMedia(video.path, label, onPick, isVideo: true);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePickedMedia(String path, String label, Function(String) onPick, {required bool isVideo}) async {
    if (isVideo) {
      // 🎬 영상 트림 화면으로 이동 (6초 이내 조절 + 압축 + 오디오 삭제)
      final File? trimmedFile = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => VideoTrimScreen(file: File(path))),
      );

      if (trimmedFile == null) return; // 취소 시 중단

      final String finalPath = trimmedFile.path;

      // 🖼️ 트림된 영상으로 썸네일 생성
      final thumbFile = await MediaCompressor.generateThumbnail(finalPath);
      
      if (mounted) {
        setState(() {
          if (label == 'A') {
            _imagePathA = finalPath;
            _thumbPathA = thumbFile?.path;
          } else {
            _imagePathB = finalPath;
            _thumbPathB = thumbFile?.path;
          }
        });
        onPick(finalPath);
      }
    } else {
      // 📸 사진일 경우 기존처럼 크롭 로직 가동!
      setState(() {
        if (label == 'A') _thumbPathA = null;
        else _thumbPathB = null;
      });
      final String? croppedPath = await _cropImage(path);
      if (croppedPath != null) onPick(croppedPath);
    }
  }

  Future<String?> _cropImage(String path) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '이미지 편집',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.cyanAccent,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false, 
          activeControlsWidgetColor: Colors.cyanAccent,
        ),
        IOSUiSettings(
          title: '이미지 편집',
          aspectRatioLockEnabled: false,
        ),
      ],
    );
    return croppedFile?.path;
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
    String? thumbPath = (label == 'A') ? _thumbPathA : _thumbPathB;
    
    return GestureDetector(
      onTap: () => _showImageSourceActionSheet(label, onPick),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            image: (path != null || thumbPath != null)
              ? DecorationImage(
                  image: thumbPath != null 
                    ? FileImage(File(thumbPath)) 
                    : (path!.startsWith('http') 
                        ? NetworkImage(path) 
                        : FileImage(File(path)) as ImageProvider), 
                  fit: BoxFit.cover
                ) 
              : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (path == null && thumbPath == null) ...[
                Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.03), fontSize: 80, fontWeight: FontWeight.w900)),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_circle_outline, color: Colors.cyanAccent, size: 32),
                    const SizedBox(height: 8),
                    Text('$label 업로드', style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
              if (thumbPath != null) // 영상일 경우 플레이 아이콘 표시
                const Icon(Icons.play_circle_outline, color: Colors.white70, size: 40),
              if (path != null || thumbPath != null)
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

  Widget _safetyOptions() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.explicit_outlined, color: Colors.redAccent, size: 20),
                SizedBox(width: 8),
                Text('성인 콘텐츠 표시', style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
            Switch(
              value: _isAdult, 
              onChanged: (v) => setState(() => _isAdult = v),
              activeTrackColor: Colors.redAccent.withValues(alpha: 0.3),
              activeThumbColor: Colors.redAccent,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.psychology_outlined, color: Colors.cyanAccent, size: 20),
                SizedBox(width: 8),
                Text('AI 생성 콘텐츠 표시', style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
            Switch(
              value: _isAI, 
              onChanged: (v) => setState(() => _isAI = v),
              activeTrackColor: Colors.cyanAccent.withValues(alpha: 0.3),
              activeThumbColor: Colors.cyanAccent,
            ),
          ],
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
