import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://otstiqndmoyzkurrjobb.supabase.co', 
    'sb_publishable_Gb0aPbRFQ6uVSM_Lt8uvDw_CF9xKrhm'
  ); 
  
  final fakeIds = ['@나의픽겟', '나의 픽겟', '나의_픽겟', '@나의_픽겟', '나의픽겟 '];
  
  print('서버에서 가짜 게시물 대청소 중...');
  
  for (var id in fakeIds) {
    try {
      await supabase.from('posts').delete().eq('uploader_id', id);
      print('✓ $id 삭제 완료');
    } catch (e) {
      print('✗ $id 삭제 실패: $e');
    }
  }
  print('========================');
  print('청소가 끝났습니다! 주인님! ✨');
}
