class AppConstants {
  static const String appName = 'Tenali Post';
  static const String appTagline = 'Learn • Prepare • Succeed';
  static const String appSubtext = 'Excellence in Postal & Competitive Exams';
  static const String logoAsset = 'assets/images/tenali_post_logo.png';
  
  // Intended initial admin email (backend-provisioned)
  static const String initialAdminEmail = 'tenaliexamspublishers26@gmail.com';

  // Supported India Post Departmental Exam Categories
  static const List<Map<String, String>> exams = [
    {
      'id': 'mts',
      'title': 'MTS Examination',
      'subtitle': 'Multi-Tasking Staff (Departmental)',
      'code': 'MTS',
      'icon': 'school',
    },
    {
      'id': 'postman',
      'title': 'Postman & Mail Guard',
      'subtitle': 'Postman / Mail Guard Cadre Examination',
      'code': 'PMG',
      'icon': 'local_post_office',
    },
    {
      'id': 'pasa',
      'title': 'PA / SA Examination',
      'subtitle': 'Postal Assistant & Sorting Assistant',
      'code': 'PASA',
      'icon': 'badge',
    },
    {
      'id': 'lgo',
      'title': 'LGO Examination',
      'subtitle': 'Lower Grade Official Promotion',
      'code': 'LGO',
      'icon': 'workspace_premium',
    },
    {
      'id': 'inspector',
      'title': 'Inspector Posts (IP)',
      'subtitle': 'Departmental Examination for IP Cadre',
      'code': 'IP',
      'icon': 'military_tech',
    },
  ];

  // Supported Multilingual Languages
  static const List<Map<String, String>> languages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'te', 'name': 'Telugu', 'nativeName': 'తెలుగు'},
    {'code': 'hi', 'name': 'Hindi', 'nativeName': 'हिन्दी'},
  ];

  // Safe Supabase configuration
  // You can paste your Supabase Project URL and Anon Public Key below:
  static const String supabaseUrl = '';
  static const String supabaseAnonKey = '';
  
  static const String supabaseUrlPlaceholder = 'https://your-tenali-post-project.supabase.co';
  static const String supabaseAnonKeyPlaceholder = 'your-anon-public-key';
}
