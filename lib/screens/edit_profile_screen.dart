import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.currentName);
    _id = TextEditingController(text: widget.currentId);
    _bio = TextEditingController(text: widget.currentBio);
    _img = widget.currentImage;
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
              onTap: () => setState(() {
                int n = int.tryParse(_img.replaceAll(RegExp(r'[^0-9]'), '')) ?? 11;
                _img = 'assets/profiles/profile_${(n % 11) + 1}.jpg';
              }),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(image: AssetImage(_img), fit: BoxFit.cover, opacity: 0.6),
                      ),
                    ),
                    const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 30),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, {
                    'name': _name.text,
                    'id': _id.text,
                    'bio': _bio.text,
                    'image': _img
                  }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: const Text('저장하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
