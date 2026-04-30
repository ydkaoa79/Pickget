import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import '../services/supabase_service.dart';
import '../services/cloudflare_service.dart';
import '../core/app_state.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentId;
  final String currentBio;
  final String currentImage;

  const EditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentId,
    required this.currentBio,
    required this.currentImage,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _name;
  late TextEditingController _id;
  late TextEditingController _bio;
  late String _img;
  final CloudflareService _cloudflareService = CloudflareService();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.currentName);
    _id = TextEditingController(text: widget.currentId);
    _bio = TextEditingController(text: widget.currentBio);
    _img = widget.currentImage;
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      // 1. Crop Image first
      final String? croppedPath = await _cropImage(pickedFile.path);
      if (croppedPath == null) return; // User cancelled crop

      setState(() => _isUploading = true);
      try {
        final String fileName = 'profile_${gUserInternalId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String? url = await _cloudflareService.uploadFile(File(croppedPath), fileName);
        if (url != null) {
          setState(() {
            _img = url;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('이미지 업로드 실패: $e'), backgroundColor: Colors.redAccent),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  Future<String?> _cropImage(String path) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '프로필 사진 편집',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.cyanAccent,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true, 
          activeControlsWidgetColor: Colors.cyanAccent,
        ),
        IOSUiSettings(
          title: '프로필 사진 편집',
          aspectRatioLockEnabled: true,
        ),
      ],
    );
    return croppedFile?.path;
  }

  @override
  void dispose() {
    _name.dispose();
    _id.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('프로필 편집', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            GestureDetector(
              onTap: _isUploading ? null : _pickAndUploadImage,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF151515),
                        border: Border.all(color: Colors.white10, width: 2),
                        image: DecorationImage(
                          image: _img.startsWith('http') 
                            ? NetworkImage(_img) 
                            : AssetImage(_img) as ImageProvider, 
                          fit: BoxFit.cover, 
                          opacity: _isUploading ? 0.3 : 0.8
                        ),
                      ),
                    ),
                    if (_isUploading)
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 2),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            _field('이름', _name),
            const SizedBox(height: 20),
            _field('아이디', _id),
            const SizedBox(height: 20),
            _field('자기소개', _bio, lines: 5),
            const SizedBox(height: 60),
            
            // 💾 저장하기 버튼 섹션
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF00B0FF)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    
                    // 로딩 표시
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
                    );

                    try {
                      // 0. 아이디 중복 체크
                      if (_id.text != widget.currentId) {
                        final existing = await SupabaseService.client
                            .from('user_profiles')
                            .select('user_id')
                            .eq('user_id', _id.text)
                            .maybeSingle();
                        
                        if (existing != null) {
                          if (mounted) {
                            Navigator.pop(context); // 로딩 닫기
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('이미 사용 중인 아이디입니다. 다른 아이디를 입력해주세요! 😅'),
                                backgroundColor: Colors.orangeAccent,
                              ),
                            );
                          }
                          return;
                        }
                      }

                      // 주민번호(User ID) 최종 확인 (이미 Auth 세션에서 설정되어 있어야 함)
                      if (gUserInternalId == null) {
                        throw Exception('로그인 세션이 만료되었습니다. 다시 로그인해주세요.');
                      }

                      // 1. 프로필 업데이트 (주민번호 기준!)
                      await SupabaseService.client
                          .from('user_profiles')
                          .update({
                            'nickname': _name.text,
                            'bio': _bio.text,
                            'profile_image': _img,
                            'user_id': _id.text,
                          })
                          .eq('id', gUserInternalId!);

                      // 2. 글로벌 상태 변수 즉시 동기화 (진짜 정석!)
                      gNameText = _name.text;
                      gIdText = _id.text;
                      gProfileImage = _img;

                      // 3. 게시물/댓글 이름표 동기화 (주민번호 기반으로 더 확실하게!)
                      await SupabaseService.client
                          .from('posts')
                          .update({'uploader_id': _id.text})
                          .eq('uploader_internal_id', gUserInternalId!);
                      
                      await SupabaseService.client
                          .from('comments')
                          .update({
                            'user_id': _id.text,
                            'user_name': _name.text,
                            'user_image': _img,
                          })
                          .eq('user_internal_id', gUserInternalId!);

                      if (mounted) {
                        Navigator.pop(context); // 로딩 닫기
                        Navigator.pop(context, {
                          'name': _name.text,
                          'id': _id.text,
                          'bio': _bio.text,
                          'image': _img
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        Navigator.pop(context); // 로딩 닫기
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('저장 실패: $e'), backgroundColor: Colors.redAccent),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('저장하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: lines,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF151515),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }
}
