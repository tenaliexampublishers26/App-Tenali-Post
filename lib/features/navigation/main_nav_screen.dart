import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../shared/custom_app_drawer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lms_admin_provider.dart';
import '../home/home_screen.dart';
import '../videos/videos_screen.dart';
import '../live_tests/live_tests_screen.dart';
import '../mcq/exam_list_screen.dart';
import '../notes/notes_screen.dart';

class MainNavScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final lms = Provider.of<LmsAdminProvider>(context, listen: false);
      lms.loadStudentPortalData(isAdmin: auth.isAdmin);
      lms.startRealtimeSync(isAdmin: auth.isAdmin);
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final lms = Provider.of<LmsAdminProvider>(context);

    // Profile Completion & Auth Guard: Ensure no unauthenticated or incomplete profile user accesses app
    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      });
    } else if (auth.needsProfileCompletion) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pushReplacementNamed(context, '/profile-completion');
      });
    }

    // Reflect Maintenance Mode immediately for non-admin students
    if (lms.settings.maintenanceMode && !auth.isAdmin) {
      return Scaffold(
        backgroundColor: AppTheme.bgWarm,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.build_circle_rounded,
                    size: 64, color: AppTheme.secondaryMaroon),
                const SizedBox(height: 16),
                const Text(
                  'Portal Under Maintenance',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The administrator has temporarily paused student access for maintenance. Please check back shortly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Check Again'),
                  onPressed: () => lms.loadPublicSettings(),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () async {
                    await auth.signOut();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final List<Widget> pages = [
      HomeScreen(onNavigateTab: _onTabTapped),
      const VideosScreen(),
      const LiveTestsScreen(),
      const ExamListScreen(asTab: true),
      const NotesScreen(),
    ];

    final int safeIndex = _currentIndex.clamp(0, pages.length - 1);

    return Scaffold(
      drawer: CustomAppDrawer(onSelectTab: _onTabTapped),
      body: IndexedStack(
        index: safeIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceWarmWhite,
          border: Border(
            top: BorderSide(color: AppTheme.borderWarmSubtle, width: 1.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x0A0B2545),
              blurRadius: 12,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: safeIndex,
          onTap: _onTabTapped,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.play_circle_outline_rounded),
              activeIcon: Icon(Icons.play_circle_fill_rounded),
              label: 'Videos',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.timer_outlined),
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.secondaryMaroon,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              activeIcon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.timer_rounded),
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.secondaryMaroon,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              label: 'Live Tests',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.quiz_outlined),
              activeIcon: Icon(Icons.quiz_rounded),
              label: 'MCQs',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book_rounded),
              label: 'Notes',
            ),
          ],
        ),
      ),
    );
  }
}
