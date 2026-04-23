

import 'package:flutter/material.dart';

class AppLanguage extends ChangeNotifier {
  // ── Singleton ─────────────────────────────────────────────────────────────
  AppLanguage._internal();
  static final AppLanguage _instance = AppLanguage._internal();
  factory AppLanguage() => _instance;

  // ── State ──────────────────────────────────────────────────────────────────
  String _languageCode = 'en'; // 'en' or 'ar'

  String get languageCode => _languageCode;
  bool get isArabic => _languageCode == 'ar';

  /// e.g.  AppLanguage().setLanguage('ar')   or   ('en')
  void setLanguage(String code) {
    if (_languageCode == code) return;
    _languageCode = code;
    notifyListeners();
  }

  // ── Translation map ────────────────────────────────────────────────────────
  Map<String, String> get t => _languageCode == 'ar' ? _ar : _en;

  // ── English strings ────────────────────────────────────────────────────────
  static const Map<String, String> _en = {
    // App name
    'appName': 'QatarSale',
    'tagline': 'THE MARKET AT YOUR HOME',

    // Bottom nav
    'nav_home': 'Home',
    'nav_categories': 'Categories',
    'nav_post_ad': 'Post Ad',
    'nav_saved': 'Saved',
    'nav_chat': 'Chat',
    'nav_account': 'Account',

    // Home
    'search_hint': 'Search in QatarSale...',
    'categories': 'Categories',
    'featured': 'Featured',
    'recent': 'Recent Listings',
    'see_all': 'See All',

    // Account – guest
    'welcome': 'Welcome to QatarSale',
    'login_prompt': 'Login to manage your ads, favorites and messages',
    'login': 'Login',
    'register': 'Register',
    'browse': 'BROWSE',
    'search_listings': 'Search Listings',
    'all_categories': 'All Categories',
    'featured_ads': 'Featured Ads',
    'job_center': 'JOB CENTER',
    'browse_jobs': 'Browse Jobs',
    'upload_cv': 'Upload CV',
    'information': 'INFORMATION',
    'language': 'Language',
    'help_support': 'Help & Support',
    'about': 'About QatarSale',
    'privacy_policy': 'Privacy Policy',

    // Account – logged in
    'my_ads': 'My Ads',
    'favorites': 'Favorites',
    'settings': 'Settings',
    'active_ads': 'Active Ads',
    'views': 'Views',
    'rating': 'Rating',
    'post_new_ad': 'Post a New Ad',
    'reach_buyers': 'Reach thousands of buyers in Qatar',
    'edit': 'Edit',
    'boost': 'Boost',
    'delete': 'Delete',
    'view': 'View',

    // Settings
    'account_section': 'ACCOUNT',
    'edit_profile': 'Edit Profile',
    'change_password': 'Change Password',
    'verify_phone': 'Verify Phone Number',
    'email': 'Email',
    'notifications_section': 'NOTIFICATIONS',
    'push_notifications': 'Push Notifications',
    'price_alerts': 'Price Drop Alerts',
    'message_alerts': 'Message Alerts',
    'email_notifications': 'Email Notifications',
    'preferences': 'PREFERENCES',
    'default_location': 'Default Location',
    'currency': 'Currency',
    'privacy_legal': 'PRIVACY & LEGAL',
    'privacy_settings': 'Privacy Settings',
    'terms': 'Terms of Service',
    'app_version': 'App Version',
    'account_actions': 'ACCOUNT ACTIONS',
    'logout': 'Logout',
    'delete_account': 'Delete Account',

    // Common
    'cancel': 'Cancel',
    'save': 'Save',
    'done': 'Done',
    'close': 'Close',
    'update': 'Update',
    'verify': 'Verify',
    'call': 'Call',
    'chat': 'Chat',
    'share': 'Share',
    'unverified': 'Unverified',
    'current_lang': 'English',

    // About
    'about_content':
    'QatarSale is Qatar\'s leading classified marketplace. Buy, sell and advertise products & services across multiple categories. Our platform connects buyers and sellers across the entire country.\n\nVersion: 1.0.0\nDeveloped by: JH IT Zone\nContact: info@jhitzone.com',

    // Privacy
    'privacy_content':
    'We respect your privacy. Your personal data is never sold to third parties. All data is encrypted and stored securely. You can request data deletion at any time from the Settings screen.\n\nWe collect: name, email, phone number, and listing details. This data is used only to operate the marketplace service.',

    // Terms
    'terms_content':
    'By using QatarSale you agree to:\n\n• Post only genuine listings\n• Respect other users\n• Not engage in fraudulent activity\n• Comply with Qatar law\n\nWe reserve the right to remove any listing that violates these terms. Repeated violations will result in account suspension.',

    // Help
    'help_q1': 'How do I post an ad?',
    'help_a1': 'Tap "Post Ad" at the bottom, select a category, fill in details and photos, then submit.',
    'help_q2': 'How do I contact a seller?',
    'help_a2': 'Open any listing and use the Call, WhatsApp, or Chat buttons at the bottom.',
    'help_q3': 'How do I save a listing?',
    'help_a3': 'Tap the ❤️ heart icon on any listing to save it to your Favorites.',
    'help_q4': 'How do I compare items?',
    'help_a4': 'Tap "+ Compare" on listings, then tap the Compare FAB that appears.',

    // CV upload
    'cv_title': 'Upload Your CV',
    'cv_body': 'Upload your CV to apply for jobs directly within QatarSale. Employers can find your profile and contact you.\n\nFormats accepted: PDF, DOCX\nMax size: 5 MB',
  };

  // ── Arabic strings ─────────────────────────────────────────────────────────
  static const Map<String, String> _ar = {
    // App name
    'appName': 'قطر سيل',
    'tagline': 'السوق في بيتك',

    // Bottom nav
    'nav_home': 'الرئيسية',
    'nav_categories': 'الفئات',
    'nav_post_ad': 'إضافة إعلان',
    'nav_saved': 'المحفوظات',
    'nav_chat': 'الدردشة',
    'nav_account': 'حسابي',

    // Home
    'search_hint': 'ابحث في قطر سيل...',
    'categories': 'الفئات',
    'featured': 'مميزة',
    'recent': 'أحدث الإعلانات',
    'see_all': 'عرض الكل',

    // Account – guest
    'welcome': 'مرحباً في قطر سيل',
    'login_prompt': 'سجّل دخولك لإدارة إعلاناتك ومفضلتك ورسائلك',
    'login': 'تسجيل الدخول',
    'register': 'إنشاء حساب',
    'browse': 'تصفح',
    'search_listings': 'البحث في الإعلانات',
    'all_categories': 'جميع الفئات',
    'featured_ads': 'الإعلانات المميزة',
    'job_center': 'مركز الوظائف',
    'browse_jobs': 'تصفح الوظائف',
    'upload_cv': 'رفع السيرة الذاتية',
    'information': 'معلومات',
    'language': 'اللغة',
    'help_support': 'المساعدة والدعم',
    'about': 'عن قطر سيل',
    'privacy_policy': 'سياسة الخصوصية',

    // Account – logged in
    'my_ads': 'إعلاناتي',
    'favorites': 'المفضلة',
    'settings': 'الإعدادات',
    'active_ads': 'إعلانات نشطة',
    'views': 'المشاهدات',
    'rating': 'التقييم',
    'post_new_ad': 'إضافة إعلان جديد',
    'reach_buyers': 'تواصل مع آلاف المشترين في قطر',
    'edit': 'تعديل',
    'boost': 'تعزيز',
    'delete': 'حذف',
    'view': 'عرض',

    // Settings
    'account_section': 'الحساب',
    'edit_profile': 'تعديل الملف الشخصي',
    'change_password': 'تغيير كلمة المرور',
    'verify_phone': 'التحقق من رقم الهاتف',
    'email': 'البريد الإلكتروني',
    'notifications_section': 'الإشعارات',
    'push_notifications': 'إشعارات الجوال',
    'price_alerts': 'تنبيهات انخفاض السعر',
    'message_alerts': 'تنبيهات الرسائل',
    'email_notifications': 'إشعارات البريد الإلكتروني',
    'preferences': 'التفضيلات',
    'default_location': 'الموقع الافتراضي',
    'currency': 'العملة',
    'privacy_legal': 'الخصوصية والقانون',
    'privacy_settings': 'إعدادات الخصوصية',
    'terms': 'شروط الخدمة',
    'app_version': 'إصدار التطبيق',
    'account_actions': 'إجراءات الحساب',
    'logout': 'تسجيل الخروج',
    'delete_account': 'حذف الحساب',

    // Common
    'cancel': 'إلغاء',
    'save': 'حفظ',
    'done': 'تم',
    'close': 'إغلاق',
    'update': 'تحديث',
    'verify': 'تحقق',
    'call': 'اتصال',
    'chat': 'دردشة',
    'share': 'مشاركة',
    'unverified': 'غير مُحقَّق',
    'current_lang': 'العربية',

    // About
    'about_content':
    'قطر سيل هو السوق الإلكتروني الرائد في قطر. اشترِ وبِع وأعلن عن المنتجات والخدمات في مختلف الفئات. يربط منصتنا المشترين والبائعين في جميع أنحاء البلاد.\n\nالإصدار: 1.0.0\nالمطوّر: JH IT Zone\nالتواصل: info@jhitzone.com',

    // Privacy
    'privacy_content':
    'نحن نحترم خصوصيتك. لا نبيع بياناتك الشخصية لأطراف ثالثة. جميع البيانات مشفرة ومحفوظة بأمان. يمكنك طلب حذف بياناتك في أي وقت من شاشة الإعدادات.\n\nنجمع: الاسم والبريد الإلكتروني ورقم الهاتف وتفاصيل الإعلانات. تُستخدم هذه البيانات فقط لتشغيل خدمة السوق.',

    // Terms
    'terms_content':
    'باستخدامك لقطر سيل، فإنك توافق على:\n\n• نشر إعلانات حقيقية فقط\n• احترام المستخدمين الآخرين\n• عدم الانخراط في أنشطة احتيالية\n• الامتثال لقوانين قطر\n\nنحتفظ بالحق في إزالة أي إعلان ينتهك هذه الشروط. قد يؤدي الانتهاك المتكرر إلى تعليق الحساب.',

    // Help
    'help_q1': 'كيف أنشر إعلانًا؟',
    'help_a1': 'اضغط على "إضافة إعلان" في الأسفل، اختر الفئة، أدخل التفاصيل والصور، ثم أرسل.',
    'help_q2': 'كيف أتواصل مع البائع؟',
    'help_a2': 'افتح أي إعلان واستخدم أزرار الاتصال أو واتساب أو الدردشة في الأسفل.',
    'help_q3': 'كيف أحفظ إعلانًا؟',
    'help_a3': 'اضغط على أيقونة ❤️ في أي إعلان لحفظه في المفضلة.',
    'help_q4': 'كيف أقارن بين المنتجات؟',
    'help_a4': 'اضغط على "+ مقارنة" في الإعلانات، ثم اضغط زر المقارنة الذي يظهر.',

    // CV upload
    'cv_title': 'رفع السيرة الذاتية',
    'cv_body': 'ارفع سيرتك الذاتية للتقدم للوظائف مباشرةً من قطر سيل. يمكن لأصحاب العمل العثور على ملفك الشخصي والتواصل معك.\n\nالصيغ المقبولة: PDF، DOCX\nالحجم الأقصى: 5 ميجابايت',
  };
}