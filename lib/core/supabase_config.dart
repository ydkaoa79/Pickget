class SupabaseConfig {
  static const String url = 'https://otstiqndmoyzkurrjobb.supabase.co';
  static const String anonKey = 'sb_publishable_Gb0aPbRFQ6uVSM_Lt8uvDw_CF9xKrhm';
}

class CloudflareConfig {
  // 🔥 accessKey와 secretKey를 완전히 삭제했다! 
  // 이제 워커(Worker)가 보안을 전담합니다.
  static const String workerUrl = 'https://pickget-uploader.ydkaoa79.workers.dev/';
  static const String cdnUrl = 'https://cdn.pickget.net/';
}
