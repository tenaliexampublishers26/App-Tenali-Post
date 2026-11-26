class AppConstants {
  static const String appName = 'Tenali Post';
  static const String appTagline = 'Learn • Prepare • Succeed';
  static const String appSubtext = 'Excellence in Postal & Competitive Exams';
  static const String logoAsset = 'assets/images/tenali_post_logo.png';
  
  // The only authorized administrator email
  static const String authorizedAdminEmail = 'tenaliexampublishers26@gmail.com';
  static const String initialAdminEmail = 'tenaliexampublishers26@gmail.com';
  static const String legacyAdminEmail = 'tenaliexamspublishers26@gmail.com';

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

  // Supabase Project Configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://nrlsqwvpbrinbagwzrfk.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_KY5GqZ_BF7glQXNvg53RvQ_wVt_pSe_',
  );

  // Example Student & Admin Login Credentials for instant app access
  static const String exampleLoginEmail = 'student@example.com';
  static const String exampleLoginPassword = 'Password@123';
  static const String exampleAdminEmail = authorizedAdminEmail;
  static const String exampleAdminPassword = 'Admin@123';
}
