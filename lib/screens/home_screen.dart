import 'package:flutter/material.dart';
import '../models/missing_person.dart';
import '../services/ai_vision_service.dart';
import '../services/auth_service.dart';
import '../services/missing_person_repository.dart';
import '../widgets/amber_alert_banner.dart';
import '../widgets/app_photo_view.dart';
import '../widgets/create_post_card.dart';
import '../widgets/social_post_card.dart';
import '../widgets/volunteer_badge_card.dart';
import 'admin/admin_dashboard_screen.dart';
import 'edit_profile_screen.dart';
import 'emergency_helplines_screen.dart';
import 'find_person_by_photo_screen.dart';
import 'login_screen.dart';
import 'matched_alerts_screen.dart';
import 'person_detail_screen.dart';
import 'report_found_person_screen.dart';
import 'report_missing_screen.dart';
import 'search_filter_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Urgent Alert',
    'Children',
    'Adults',
    'Seniors',
    'Verified',
    'Found',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToReportMissing() {
    if (AuthService().isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ReportMissingScreen(),
        ),
      );
    } else {
      _showLoginPrompt();
    }
  }

  void _navigateToReportFound() {
    if (AuthService().isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ReportFoundPersonScreen(),
        ),
      );
    } else {
      _showLoginPrompt();
    }
  }

  void _showLoginPrompt() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(
          onLoginSuccess: () {
            setState(() {});
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService(),
      builder: (context, _) {
        final isLoggedIn = AuthService().isLoggedIn;

        // If not logged in, show clean unified Login / Sign Up screen directly
        if (!isLoggedIn) {
          return const LoginScreen();
        }

        // Authenticated Experience with 4 Modern Tabs
        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          appBar: _buildAppBar(),
          body: IndexedStack(
            index: _currentTabIndex,
            children: [
              _buildFeedTab(),
              const MatchedAlertsScreen(),
              const FindPersonByPhotoScreen(),
              _buildProfileTab(),
            ],
          ),
          bottomNavigationBar: _buildBottomNavigation(),
          floatingActionButton: _buildFloatingQuickActions(),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.travel_explore_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'FindMissingPerson',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 0.2,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF0F172A),
      actions: [
        // Emergency SOS Helplines Quick Action
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmergencyHelplinesScreen(),
                ),
              );
            },
            icon: const Icon(Icons.emergency_rounded, size: 15, color: Colors.white),
            label: const Text(
              'SOS 112',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ),
        if (AuthService().isCurrentAdmin)
          IconButton(
            icon: const Icon(Icons.shield_rounded, color: Color(0xFF2563EB)),
            tooltip: 'Admin Panel',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminDashboardScreen(),
                ),
              );
            },
          ),
        IconButton(
          icon: const Icon(Icons.tune_rounded, color: Color(0xFF64748B)),
          tooltip: 'Advanced Filters',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SearchFilterScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return ListenableBuilder(
      listenable: MissingPersonRepository(),
      builder: (context, _) {
        final possibleMatchesCount = MissingPersonRepository()
            .reports
            .where((r) =>
                r.reportStatus.toLowerCase() == 'possible match' ||
                r.reportStatus.toLowerCase() == 'sighted')
            .length;

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: NavigationBar(
            selectedIndex: _currentTabIndex,
            onDestinationSelected: (idx) {
              setState(() {
                _currentTabIndex = idx;
              });
            },
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFF2563EB).withOpacity(0.12),
            elevation: 0,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.dynamic_feed_rounded),
                selectedIcon: Icon(Icons.dynamic_feed_rounded, color: Color(0xFF2563EB)),
                label: 'Community Feed',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: possibleMatchesCount > 0,
                  label: Text('$possibleMatchesCount'),
                  backgroundColor: const Color(0xFFEA580C),
                  child: const Icon(Icons.bolt_rounded),
                ),
                selectedIcon: Badge(
                  isLabelVisible: possibleMatchesCount > 0,
                  label: Text('$possibleMatchesCount'),
                  backgroundColor: const Color(0xFFEA580C),
                  child: const Icon(Icons.bolt_rounded, color: Color(0xFFEA580C)),
                ),
                label: 'Matched Alerts',
              ),
              const NavigationDestination(
                icon: Icon(Icons.camera_alt_outlined),
                selectedIcon: Icon(Icons.camera_alt_rounded, color: Color(0xFF2563EB)),
                label: 'Photo Match',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF2563EB)),
                label: 'Account',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeedTab() {
    return ListenableBuilder(
      listenable: MissingPersonRepository(),
      builder: (context, _) {
        final allReports = MissingPersonRepository().reports;
        final urgentReports = allReports
            .where((p) => p.isUrgent && p.reportStatus.toLowerCase() != 'found')
            .toList();
        final query = _searchController.text.trim().toLowerCase();

        var filtered = allReports;
        if (query.isNotEmpty) {
          filtered = filtered.where((p) {
            return p.fullName.toLowerCase().contains(query) ||
                p.lastSeenLocation.toLowerCase().contains(query) ||
                p.description.toLowerCase().contains(query) ||
                p.contactNumber.contains(query);
          }).toList();
        }

        if (_selectedCategory != 'All') {
          switch (_selectedCategory.toLowerCase()) {
            case 'urgent alert':
              filtered = filtered.where((p) => p.isUrgent).toList();
              break;
            case 'children':
              filtered = filtered.where((p) => p.age < 18).toList();
              break;
            case 'adults':
              filtered = filtered.where((p) => p.age >= 18 && p.age < 60).toList();
              break;
            case 'seniors':
              filtered = filtered.where((p) => p.age >= 60).toList();
              break;
            case 'verified':
              filtered = filtered.where((p) => p.isVerified).toList();
              break;
            case 'found':
              filtered = filtered.where((p) => p.reportStatus.toLowerCase() == 'found').toList();
              break;
          }
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
            children: [
              // Active Amber Alert for urgent cases
              if (urgentReports.isNotEmpty) ...[
                AmberAlertBanner(person: urgentReports.first),
              ],

              // Mission Hero Banner with Live Search Stats
              _buildFeedHeroBanner(
                totalCases: allReports.length,
                foundCount: MissingPersonRepository().foundCount,
              ),
              const SizedBox(height: 12),

              // 1. Facebook-Style Create Post Bar
              CreatePostCard(
                onReportMissingPressed: _navigateToReportMissing,
                onReportFoundPressed: _navigateToReportFound,
              ),

              // 2. Search Box
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by person name, city or location...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),

              // 3. Category Horizontal Pills Bar
              SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSel = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSel,
                        selectedColor: const Color(0xFF2563EB),
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : const Color(0xFF475569),
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                          fontSize: 12,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSel ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // If Found category is selected, show celebration banner
              if (_selectedCategory == 'Found') ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF047857)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF059669).withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.celebration_rounded, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reunited Loved Ones Gallery',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'These individuals were successfully located and safely reunited with their families.',
                              style: TextStyle(color: Color(0xFFD1FAE5), fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 4. Feed Posts Stream List (Facebook Style)
              if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.inbox_rounded, size: 48, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 12),
                      const Text(
                        'No posts found matching your criteria',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Try creating a new missing report post or clearing search filters.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                )
              else
                ...filtered.map((person) => SocialPostCard(person: person)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeedHeroBanner({required int totalCases, required int foundCount}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Citizen Search Network',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: 3.5, backgroundColor: Color(0xFF10B981)),
                    SizedBox(width: 5),
                    Text(
                      'AI ACTIVE',
                      style: TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Reuniting Missing Loved Ones With AI Face Matching & Community Power',
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildHeroStat('Active Cases', '$totalCases', const Color(0xFF38BDF8)),
              const SizedBox(width: 14),
              _buildHeroStat('Safely Reunited', '$foundCount', const Color(0xFF34D399)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => setState(() => _currentTabIndex = 2),
                icon: const Icon(Icons.camera_alt_rounded, size: 14),
                label: const Text('Scan Face'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _navigateToEditProfile() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );
    if (updated == true && mounted) {
      setState(() {});
    }
  }

  Widget _buildProfileTab() {
    final user = AuthService().currentUser;
    final displayName = AuthService().userDisplayName;
    final email = AuthService().userEmail;
    final isAdmin = AuthService().isCurrentAdmin;
    final isGuest = AuthService().isGuest;
    final currentUserId = AuthService().userId;

    return FutureBuilder<Map<String, dynamic>>(
      future: AuthService().getUserProfile(),
      builder: (context, snapshot) {
        final profile = snapshot.data ?? {};
        final profileName = (profile['displayName'] ?? '').toString().trim().isNotEmpty
            ? profile['displayName']
            : displayName;
        final profilePhoto = (profile['photoURL'] ?? '').toString().trim().isNotEmpty
            ? profile['photoURL']
            : AuthService().userPhotoUrl;
        final profilePhone = (profile['phoneNumber'] ?? '').toString();
        final profileCity = (profile['city'] ?? '').toString();
        final profileBio = (profile['bio'] ?? '').toString();
        final hideEmail = profile['hideEmail'] ?? true;
        final showPhone = profile['showPhone'] ?? true;
        final showCity = profile['showCity'] ?? true;

        return ListenableBuilder(
          listenable: MissingPersonRepository(),
          builder: (context, _) {
            final allReports = MissingPersonRepository().reports;
            final totalReports = allReports.length;
            final verifiedReports = MissingPersonRepository().verifiedCount;
            final foundReports = MissingPersonRepository().foundCount;

            // Filter ONLY the reports submitted by THIS user!
            final myReports = allReports.where((r) => r.reportedBy == currentUserId).toList();
            final myReportsCount = myReports.length;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
              children: [
                // 1. Distinct Violet & Indigo User Profile Card
                _buildUserProfileCard(
                  displayName: profileName,
                  email: email,
                  photoUrl: profilePhoto,
                  bio: profileBio,
                  phone: profilePhone,
                  city: profileCity,
                  userId: currentUserId,
                  isAdmin: isAdmin,
                  isGuest: isGuest,
                  hideEmail: hideEmail,
                  showPhone: showPhone,
                  showCity: showCity,
                ),
                const SizedBox(height: 14),

                // 2. Personal & Community Impact Stats
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('My Reports', '$myReportsCount', const Color(0xFF7C3AED)),
                      _buildStatItem('Verified', '$verifiedReports', const Color(0xFF059669)),
                      _buildStatItem('Community Total', '$totalReports', const Color(0xFF0F172A)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. User's Own Submitted Reports Section ("My Reports")
                _buildMyReportsSection(myReports, myReportsCount),
                const SizedBox(height: 16),

                // 4. Citizen Safety Volunteer Badges
                const VolunteerBadgeCard(),
                const SizedBox(height: 14),

                // 5. Admin Shortcut (if Admin)
                if (isAdmin) ...[
                  ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    leading: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF7C3AED)),
                    title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Review pending cases and manage verification'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],

                // 6. Emergency Helplines
                ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  leading: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFFDC2626)),
                  title: const Text('Emergency Helplines (SOS 112)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('National 112, Police 100, Childline 1098 & Checklist', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EmergencyHelplinesScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // 7. Action Shortcuts
                ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  leading: const Icon(Icons.campaign_rounded, color: Color(0xFFDC2626)),
                  title: const Text('Post Missing Person', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: _navigateToReportMissing,
                ),
                const SizedBox(height: 10),
                ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  leading: const Icon(Icons.visibility_rounded, color: Color(0xFF059669)),
                  title: const Text('Post Found Person', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: _navigateToReportFound,
                ),
                const SizedBox(height: 10),
                ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  leading: const Icon(Icons.face_retouching_natural_rounded, color: Color(0xFF7C3AED)),
                  title: const Text('Face++ Biometric AI Settings', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Face++ 106-Point Biometric Facial Recognition configuration', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => AiVisionService.showAiConfigDialog(context),
                ),
                const SizedBox(height: 20),

                // 8. Sign Out Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await AuthService().signOut();
                    },
                    icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
                    label: const Text(
                      'Log Out',
                      style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildUserProfileCard({
    required String displayName,
    required String email,
    String? photoUrl,
    required String bio,
    required String phone,
    required String city,
    required String userId,
    required bool isAdmin,
    required bool isGuest,
    required bool hideEmail,
    required bool showPhone,
    required bool showCity,
  }) {
    final friendlyId = userId.length >= 6 ? userId.substring(0, 6).toUpperCase() : 'CITIZEN';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Royal Violet & Indigo Gradient Cover Banner
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF7C3AED), Color(0xFF4C1D95)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shield_rounded, color: Colors.white, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            'ID: #$friendlyId',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Overlapping Profile Avatar
              Positioned(
                left: 16,
                bottom: -38,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: (photoUrl != null && photoUrl.trim().isNotEmpty)
                            ? AppPhotoView(
                                photoUrl: photoUrl,
                                width: 86,
                                height: 86,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: const Color(0xFFF3E8FF),
                                child: const Icon(
                                  Icons.person_rounded,
                                  size: 52,
                                  color: Color(0xFF7C3AED),
                                ),
                              ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _navigateToEditProfile,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 13, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 44),

          // 3. User Name, ID & Badges
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded, color: Color(0xFF7C3AED), size: 19),
                    if (isAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),

                // User Unique Volunteer ID Badge
                Container(
                  margin: const EdgeInsets.only(top: 2, bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Volunteer ID: #FMP-$friendlyId',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6D28D9),
                    ),
                  ),
                ),

                // Bio
                Text(
                  bio.isNotEmpty ? bio : 'Community Safety Volunteer · Helping locate lost loved ones',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),

                // 4. Action Buttons (Edit Profile + Post Report)
                Row(
                  children: [
                    // Edit Profile Button (Soft Violet Pill)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _navigateToEditProfile,
                        icon: const Icon(Icons.edit_rounded, size: 15),
                        label: const Text('Edit profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF5F3FF),
                          foregroundColor: const Color(0xFF6D28D9),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Add Report Button (Solid Royal Violet Pill)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _navigateToReportMissing,
                        icon: const Icon(Icons.add_rounded, size: 17),
                        label: const Text('Post Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 12),

                // 5. Details section with Privacy
                const Text(
                  'Details & Privacy',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 10),

                // Email Row (Shows Protected if hideEmail is true)
                if (hideEmail) ...[
                  _buildDetailRow(
                    Icons.lock_outline_rounded,
                    'Email: Private · Hidden from other users',
                    isProtected: true,
                  ),
                  const SizedBox(height: 8),
                ] else ...[
                  _buildDetailRow(Icons.mail_rounded, email),
                  const SizedBox(height: 8),
                ],

                // Phone Row (Only if user has permitted showPhone)
                if (phone.isNotEmpty && showPhone) ...[
                  _buildDetailRow(Icons.phone_rounded, 'Phone: $phone'),
                  const SizedBox(height: 8),
                ],

                // City Row (Only if user has permitted showCity)
                if (city.isNotEmpty && showCity) ...[
                  _buildDetailRow(Icons.location_on_rounded, 'Lives in $city'),
                  const SizedBox(height: 8),
                ],

                _buildDetailRow(Icons.volunteer_activism_rounded, 'Role: Citizen Responder & Search Volunteer'),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.access_time_filled_rounded, 'Joined FindMissingPerson Network'),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, {bool isProtected = false}) {
    return Row(
      children: [
        Icon(icon, size: 17, color: isProtected ? const Color(0xFF7C3AED) : const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isProtected ? const Color(0xFF6D28D9) : const Color(0xFF1E293B),
              fontWeight: isProtected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyReportsSection(List<MissingPerson> myReports, int myReportsCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.assignment_ind_rounded, color: Color(0xFF7C3AED), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'My Reports ($myReportsCount)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _navigateToReportMissing,
                child: const Text(
                  '+ New Report',
                  style: TextStyle(
                    color: Color(0xFF7C3AED),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (myReports.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.post_add_rounded, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  const Text(
                    'No reports posted yet',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Any missing person reports you create will be stored and tracked here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _navigateToReportMissing,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Post a Missing Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: myReports.length,
              separatorBuilder: (_, __) => const Divider(height: 16, color: Color(0xFFF1F5F9)),
              itemBuilder: (ctx, index) {
                final report = myReports[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PersonDetailScreen(personId: report.id),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        // Thumbnail Photo
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: const Color(0xFFF1F5F9),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: (report.photoUrl != null && report.photoUrl!.isNotEmpty)
                                ? AppPhotoView(
                                    photoUrl: report.photoUrl,
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.person_rounded, size: 28, color: Color(0xFF94A3B8)),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Report details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                report.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${report.age} yrs · ${report.gender} · ${report.lastSeenLocation}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  // Status badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: report.reportStatus.toLowerCase() == 'found'
                                          ? const Color(0xFFDCFCE7)
                                          : const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      report.reportStatus,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: report.reportStatus.toLowerCase() == 'found'
                                            ? const Color(0xFF15803D)
                                            : const Color(0xFFB91C1C),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Verification badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: report.isVerified
                                          ? const Color(0xFFEFF6FF)
                                          : const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      report.verificationStatus,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: report.isVerified
                                            ? const Color(0xFF1D4ED8)
                                            : const Color(0xFFB45309),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingQuickActions() {
    return FloatingActionButton.extended(
      onPressed: _showQuickActionSheet,
      backgroundColor: const Color(0xFF2563EB),
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.add_rounded, size: 22),
      label: const Text(
        'Quick Action',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  void _showQuickActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quick Citizen Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildQuickActionTile(
                icon: Icons.campaign_rounded,
                color: const Color(0xFFDC2626),
                title: 'Report Missing Person',
                subtitle: 'Submit new missing case with photos & details',
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateToReportMissing();
                },
              ),
              const SizedBox(height: 10),
              _buildQuickActionTile(
                icon: Icons.visibility_rounded,
                color: const Color(0xFF059669),
                title: 'Report Found / Sighted Person',
                subtitle: 'Notify community and authorities about someone found',
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateToReportFound();
                },
              ),
              const SizedBox(height: 10),
              _buildQuickActionTile(
                icon: Icons.camera_alt_rounded,
                color: const Color(0xFF7C3AED),
                title: 'AI Photo Face Match',
                subtitle: 'Scan a face to automatically find database matches',
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _currentTabIndex = 2);
                },
              ),
              const SizedBox(height: 10),
              _buildQuickActionTile(
                icon: Icons.emergency_rounded,
                color: const Color(0xFFEA580C),
                title: 'Emergency SOS & Helplines (112)',
                subtitle: 'National emergency directory and Golden Hour checklist',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EmergencyHelplinesScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
