import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/listing_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/post_ad_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/compare_screen.dart';
import '../screens/search_filter_screen.dart';
import '../main.dart';
import 'common_widgets.dart';

// ── AppDrawer ─────────────────────────────────────────────────────────────────
// Converted to StatefulWidget so it can listen to AppState and reactively
// update the compare count badge without needing a rebuild from the parent.
class AppDrawer extends StatefulWidget {
  final Function(String) onItemTap;
  const AppDrawer({super.key, required this.onItemTap});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  // ── Language state (persists while app is running) ─────────────────────────
  static String _currentLanguage = 'English';

  @override
  void initState() {
    super.initState();
    // Listen to AppState so the compare badge updates in real-time
    AppState().addListener(_onStateChange);
  }

  @override
  void dispose() {
    AppState().removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() => setState(() {});

  // ── Helpers ────────────────────────────────────────────────────────────────
  void _close() => Navigator.pop(context);

  void _push(Widget screen) {
    _close();
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _switchTab(String key) {
    _close();
    widget.onItemTap(key);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.primaryDark,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Language picker ────────────────────────────────────────────────────────
  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primaryDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Choose Language',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ...['English', 'عربي'].map((lang) {
                final selected = _currentLanguage == lang;
                return ListTile(
                  leading: Text(
                    lang == 'English' ? '🇬🇧' : '🇶🇦',
                    style: const TextStyle(fontSize: 22),
                  ),
                  title: Text(lang,
                      style: const TextStyle(color: Colors.white, fontSize: 15)),
                  trailing: selected
                      ? const Icon(Icons.check_circle, color: AppColors.gold)
                      : null,
                  onTap: () {
                    setState(() => _currentLanguage = lang);
                    setModal(() {});
                    Navigator.pop(ctx);
                    _snack('Language changed to $lang');
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ── CV Bottom Sheet ────────────────────────────────────────────────────────
  void _showCVSheet() {
    final nameCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final skillsCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.primaryDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My CV',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Fill in your details to create your profile',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 16),
            _SheetField(label: 'Full Name', hint: 'e.g. Ahmed Al-Mansoori', ctrl: nameCtrl),
            const SizedBox(height: 12),
            _SheetField(label: 'Job Title', hint: 'e.g. Software Engineer', ctrl: titleCtrl),
            const SizedBox(height: 12),
            _SheetField(label: 'Key Skills', hint: 'e.g. Flutter, React, Python', ctrl: skillsCtrl),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _snack('CV saved successfully! ✅');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save CV',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Saved Filters Sheet ────────────────────────────────────────────────────
  void _showSavedFiltersSheet() {
    final filters = <Map<String, String>>[
      {'name': 'iPhones under 2K', 'desc': 'Mobile • Sale • Max 2,000 Q.R', 'icon': '📱'},
      {'name': 'Cars in Doha', 'desc': 'Vehicles • Sale • Location: Doha', 'icon': '🚗'},
      {'name': 'Furnished Apartments', 'desc': 'Properties • Rent • Furnished', 'icon': '🏠'},
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primaryDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Saved Filters',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Tap a filter to search with it',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 16),
            ...filters.map((f) => ListTile(
              leading: Text(f['icon']!, style: const TextStyle(fontSize: 22)),
              title: Text(f['name']!,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
              subtitle: Text(f['desc']!,
                  style:
                  const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _push(const ListingScreen());
                  },
                  child: const Icon(Icons.search, color: AppColors.gold, size: 20),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _snack('Filter "${f['name']}" deleted'),
                  child: const Icon(Icons.delete_outline,
                      color: AppColors.textMuted, size: 20),
                ),
              ]),
            )),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _push(const SearchFilterScreen());
              },
              icon: const Icon(Icons.add, color: AppColors.gold),
              label: const Text('Create New Filter',
                  style: TextStyle(color: AppColors.gold)),
            ),
          ],
        ),
      ),
    );
  }

  // ── My Products Sheet ──────────────────────────────────────────────────────
  void _showMyProductsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primaryDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        final myAds = AppState().myAds;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (_, ctrl) => Column(children: [
            Container(
              width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Text('My Products',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: myAds.isEmpty
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.post_add,
                      size: 60, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  const Text("You haven't posted any ads yet",
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _switchTab('post_ad');
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold),
                    child: const Text('Post an Ad',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              )
                  : ListView.builder(
                controller: ctrl,
                itemCount: myAds.length,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemBuilder: (_, i) {
                  final p = myAds[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.divider.withOpacity(0.4)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.image,
                            color: AppColors.textMuted, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                              Text('${p.price} ${p.currency}',
                                  style: const TextStyle(
                                      color: AppColors.gold,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                            ]),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Active',
                            style: TextStyle(
                                color: AppColors.green, fontSize: 10)),
                      ),
                    ]),
                  );
                },
              ),
            ),
          ]),
        );
      },
    );
  }

  // ── Winnings Sheet ─────────────────────────────────────────────────────────
  void _showWinningsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primaryDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Winnings',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          Icon(Icons.emoji_events_outlined,
              size: 60, color: AppColors.gold.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text('No auction winnings yet',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 8),
          const Text('Participate in auctions to see your winnings here',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  // ── Post a Job Sheet ───────────────────────────────────────────────────────
  void _showPostJobSheet() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String jobType = 'Full Time';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.primaryDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: const [
                Text('Post a Job',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                _NewBadge(),
              ]),
              const SizedBox(height: 16),
              _SheetField(label: 'Job Title *', hint: 'e.g. Flutter Developer', ctrl: titleCtrl),
              const SizedBox(height: 12),
              // Job type chips
              const Text('Job Type',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Full Time', 'Part Time', 'Freelance', 'Remote']
                    .map((t) {
                  final sel = jobType == t;
                  return GestureDetector(
                    onTap: () => setModal(() => jobType = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel
                                ? AppColors.gold
                                : AppColors.divider),
                      ),
                      child: Text(t,
                          style: TextStyle(
                              color:
                              sel ? AppColors.gold : AppColors.textSecondary,
                              fontSize: 12)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              _SheetField(
                  label: 'Description',
                  hint: 'Describe the role and requirements…',
                  ctrl: descCtrl,
                  maxLines: 3),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                          content: Text('Please enter a job title'),
                          backgroundColor: AppColors.orange));
                      return;
                    }
                    Navigator.pop(ctx);
                    _snack('Job posted successfully! ✅');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Post Job',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Favorite Jobs Sheet ────────────────────────────────────────────────────
  void _showFavoriteJobsSheet() {
    final jobs = <Map<String, String>>[
      {'title': 'Senior Flutter Developer', 'company': 'TechQatar', 'salary': '15K–20K Q.R', 'type': 'Remote'},
      {'title': 'UI/UX Designer', 'company': 'CreativeHub', 'salary': '10K–14K Q.R', 'type': 'Full Time'},
      {'title': 'Project Manager', 'company': 'Qatar Projects', 'salary': '18K–25K Q.R', 'type': 'Full Time'},
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primaryDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        builder: (_, ctrl) => Column(children: [
          Container(
              width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Favorite Jobs / Talents',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: jobs.map((j) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider.withOpacity(0.3)),
                ),
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.work_outline, color: AppColors.gold, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(j['title']!, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                      Text('${j['company']} • ${j['type']}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      Text(j['salary']!, style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  GestureDetector(
                    onTap: () => _snack('Removed from favorites'),
                    child: const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
                  ),
                ]),
              )).toList(),
            ),
          ),
        ]),
      ),
    );
  }

  // ── My Job Posts Sheet ─────────────────────────────────────────────────────
  void _showMyJobPostsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primaryDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('My Job Posts',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          const Icon(Icons.work_off_outlined, size: 56, color: AppColors.textMuted),
          const SizedBox(height: 12),
          const Text('No job posts yet',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _showPostJobSheet(); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
            child: const Text('Post a Job', style: TextStyle(color: Colors.white)),
          ),
        ]),
      ),
    );
  }

  // ── Applied Jobs Sheet ─────────────────────────────────────────────────────
  void _showAppliedJobsSheet() {
    final applied = <Map<String, dynamic>>[
      {'title': 'Senior Flutter Developer', 'company': 'TechQatar', 'status': 'Under Review', 'color': AppColors.gold},
      {'title': 'Mobile App Developer', 'company': 'AppFactory', 'status': 'Shortlisted', 'color': AppColors.green},
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primaryDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        builder: (_, ctrl) => Column(children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Applied Jobs', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: applied.map((j) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.assignment_outlined, color: AppColors.textMuted, size: 28),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(j['title']!, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                    Text(j['company']!, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (j['color'] as Color).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(j['status']!, style: TextStyle(color: j['color'] as Color, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ]),
              )).toList(),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cmpCount = AppState().compareList.length;

    return Drawer(
      backgroundColor: AppColors.primaryDark,
      width: MediaQuery.of(context).size.width * 0.88,
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              color: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    GestureDetector(
                      onTap: _close,
                      child: const Icon(Icons.close, color: Colors.white, size: 24),
                    ),
                    const Spacer(),
                    const AppLogo(),
                    const Spacer(),
                    // Notification bell
                    GestureDetector(
                      onTap: () => _push(const NotificationsScreen()),
                      child: Stack(children: [
                        const Icon(Icons.notifications_outlined, color: Colors.white),
                        Positioned(
                          top: 0, right: 0,
                          child: Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                          ),
                        ),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  // Login / Register
                  Row(children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _close();
                          widget.onItemTap('account');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          elevation: 0,
                        ),
                        child: const Text('Login',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _close();
                          widget.onItemTap('account');
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        child: const Text('Register',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  // Theme + sound buttons
                  Row(children: [
                    _ThemeBtn(label: '☀️ Light', isActive: false,
                        onTap: () => _snack('Light theme coming soon!')),
                    const SizedBox(width: 6),
                    _ThemeBtn(label: '🌙 Classic', isActive: true, onTap: () {}),
                    const SizedBox(width: 6),
                    _ThemeBtn(label: '🌑 Dark', isActive: false,
                        onTap: () => _snack('Dark theme coming soon!')),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _snack('Sound settings'),
                      child: Container(
                        width: 36, height: 34,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, border: Border.all(color: Colors.white38)),
                        child: const Icon(Icons.volume_up, color: Colors.white70, size: 16),
                      ),
                    ),
                  ]),
                ],
              ),
            ),

            // ── Menu ────────────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // MY ACCOUNT
                  const _SectionHeader(title: 'MY ACCOUNT'),
                  _DrawerItem(
                    icon: Icons.bookmark_outline,
                    label: 'Saved Filters',
                    onTap: _showSavedFiltersSheet,
                  ),
                  _DrawerItem(
                    icon: Icons.search,
                    label: 'Search',
                    trailing: 'Classic',
                    onTap: () => _push(const SearchFilterScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.favorite_outline,
                    label: 'Favorites',
                    onTap: () => _switchTab('favorites'),
                  ),
                  // Compare — badge updates reactively
                  _DrawerItem(
                    icon: Icons.compare_arrows,
                    label: 'Compare',
                    trailing: cmpCount > 0 ? '$cmpCount' : '0',
                    trailingHighlight: cmpCount > 0,
                    onTap: () {
                      if (cmpCount > 0) {
                        _push(CompareScreen(selectedProducts: AppState().compareList));
                      } else {
                        _snack('Add items to compare first');
                      }
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.language,
                    label: 'عربي / English',
                    trailing: _currentLanguage,
                    onTap: _showLanguagePicker,
                  ),
                  _DrawerItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () => _push(const NotificationsScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.chat_bubble_outline,
                    label: 'Messages',
                    onTap: () => _switchTab('chat'),
                  ),

                  // MARKET AND AUCTION
                  const _SectionHeader(title: 'MARKET AND AUCTION'),
                  _DrawerItem(
                    icon: Icons.shopping_bag_outlined,
                    label: 'My Products',
                    onTap: _showMyProductsSheet,
                  ),
                  _DrawerItem(
                    icon: Icons.emoji_events_outlined,
                    label: 'Winnings',
                    onTap: _showWinningsSheet,
                  ),

                  // JOB CENTER
                  const _SectionHeader(title: 'JOB CENTER'),
                  _DrawerItem(
                    icon: Icons.work_outline,
                    label: 'Post a Job',
                    isNew: true,
                    onTap: _showPostJobSheet,
                  ),
                  _DrawerItem(
                    icon: Icons.description_outlined,
                    label: 'My CV',
                    isNew: true,
                    onTap: _showCVSheet,
                  ),
                  _DrawerItem(
                    icon: Icons.favorite_border,
                    label: 'Favorite Jobs/Talents',
                    onTap: _showFavoriteJobsSheet,
                  ),
                  _DrawerItem(
                    icon: Icons.business_center_outlined,
                    label: 'My job posts',
                    onTap: _showMyJobPostsSheet,
                  ),
                  _DrawerItem(
                    icon: Icons.assignment_outlined,
                    label: 'Applied Jobs',
                    onTap: _showAppliedJobsSheet,
                  ),

                  // SHORTCUTS
                  const _SectionHeader(title: 'SHORTCUTS'),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                    child: Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        {'l': '🏠 Home Page', 'cat': ''},
                        {'l': '🛒 Market', 'cat': 'Market'},
                        {'l': '🚗 Vehicles', 'cat': 'Vehicles'},
                        {'l': '🏘️ Real Estate', 'cat': 'Properties'},
                        {'l': '💼 Jobs Center', 'cat': 'Jobs Center'},
                        {'l': '💎 Jewellery', 'cat': 'Jewellery'},
                        {'l': '⛵ WaterCrafts', 'cat': 'WaterCrafts'},
                        {'l': '💻 Computers', 'cat': 'Computers & Parts'},
                        {'l': '🎮 Video Games', 'cat': 'Video Games'},
                        {'l': '📺 Home Appliances', 'cat': 'Home Appliances'},
                        {'l': '🏗️ Heavy Equipments', 'cat': 'Heavy Equipments'},
                        {'l': '🔧 Services', 'cat': 'Services'},
                        {'l': '🪑 Furniture & Décor', 'cat': 'Furniture & Décor'},
                        {'l': '⌚ Wrist Watches', 'cat': 'Wrist Watches'},
                      ].map((s) {
                        return _ShortcutChip(
                          label: s['l']!,
                          onTap: () {
                            _close();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => s['cat']!.isEmpty
                                    ? const ListingScreen()
                                    : ListingScreen(categoryTitle: s['cat']),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),

                  // All Categories
                  _DrawerItem(
                    icon: Icons.grid_view_outlined,
                    label: 'All Categories',
                    onTap: () => _push(const CategoriesScreen()),
                  ),

                  // App version
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(children: const [
                      Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
                      SizedBox(width: 8),
                      Text('App version', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      Spacer(),
                      Text('1.0.0', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    ]),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _NewBadge extends StatelessWidget {
  const _NewBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(8)),
    child: const Text('New', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
  );
}

class _SheetField extends StatelessWidget {
  final String label, hint;
  final TextEditingController ctrl;
  final int maxLines;
  const _SheetField({required this.label, required this.hint, required this.ctrl, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.card,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
    ]);
  }
}

class _ThemeBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _ThemeBtn({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: isActive ? AppColors.gold : AppColors.surface,
          borderRadius: BorderRadius.circular(17),
          border: isActive ? null : Border.all(color: Colors.white24),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  color: isActive ? Colors.white : Colors.white70,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
        ),
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    color: AppColors.surface,
    child: Text(title,
        style: const TextStyle(
            color: AppColors.textMuted, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
  );
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final bool trailingHighlight;
  final bool isNew;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    this.trailing,
    this.trailingHighlight = false,
    this.isNew = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.3))),
        child: Row(children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14))),
          if (isNew)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(10)),
              child: const Text('New',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          if (trailing != null)
            Text(trailing!,
                style: TextStyle(
                    color: trailingHighlight ? AppColors.gold : AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: trailingHighlight ? FontWeight.w600 : FontWeight.normal)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
        ]),
      ),
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ShortcutChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider.withOpacity(0.4)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    ),
  );
}