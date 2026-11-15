import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/missing_person.dart';
import '../../services/auth_service.dart';
import '../../services/missing_person_repository.dart';
import '../../widgets/app_photo_view.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/verified_badge.dart';
import '../person_detail_screen.dart';
import 'admin_edit_report_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isAdminVerified = false;
  bool _isCheckingAuth = true;

  final List<String> _tabs = [
    'All',
    'Pending',
    'Approved',
    'Verified',
    'Rejected',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _verifyAdminAccess();
  }

  Future<void> _verifyAdminAccess() async {
    setState(() {
      _isCheckingAuth = true;
    });

    final isAuth = await AuthService().checkIsAdmin();

    if (mounted) {
      setState(() {
        _isAdminVerified = isAuth;
        _isCheckingAuth = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  Future<void> _updateVerificationStatus(
    MissingPerson person,
    String status, {
    String? reason,
  }) async {
    try {
      final currentAdmin = AuthService().currentUser?.email ?? 'admin';
      await MissingPersonRepository().updateVerificationStatus(
        person.id,
        status,
        rejectionReason: reason,
        verifiedBy: status.toLowerCase() == 'verified' ? currentAdmin : person.verifiedBy,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report for "${person.fullName}" marked as $status.'),
          backgroundColor: status.toLowerCase() == 'rejected'
              ? const Color(0xFFDC2626)
              : const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Action failed: $e'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showRejectDialog(MissingPerson person) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Reject Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rejecting report for "${person.fullName}". Please provide a reason for the record:',
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'e.g., Incomplete information, duplicate report, spam',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateVerificationStatus(
                person,
                'Rejected',
                reason: reasonController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject Report'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(MissingPerson person) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Delete Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete the report for "${person.fullName}"? This action cannot be undone.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await MissingPersonRepository().deleteReport(person.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Report for "${person.fullName}" has been deleted.'),
                      backgroundColor: const Color(0xFFDC2626),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete report: $e'),
                      backgroundColor: const Color(0xFFDC2626),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _showVerifyConfirmation(MissingPerson person) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: Color(0xFF059669)),
            SizedBox(width: 8),
            Text('Mark as Verified', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to verify "${person.fullName}"? This will display the official Verified Case badge on all public listings.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateVerificationStatus(person, 'Verified');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Verification'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF2563EB)),
              SizedBox(height: 16),
              Text(
                'Checking administrator permissions...',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isAdminVerified) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 56,
                    color: Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Access Denied',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'You do not have administrator permissions to access this dashboard. Only authorized administrators can view and manage verification reports.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Return to Home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFF2563EB), size: 22),
            SizedBox(width: 8),
            Text(
              'Admin Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: StreamBuilder<List<MissingPerson>>(
        stream: MissingPersonRepository().reportsStream,
        builder: (context, snapshot) {
          final allReports = snapshot.data ?? MissingPersonRepository().reports;

          // Stats calculation
          final totalCount = allReports.length;
          final pendingCount = allReports.where((r) => r.isPending).length;
          final verifiedCount = allReports.where((r) => r.isVerified).length;
          final approvedCount = allReports.where((r) => r.verificationStatus.toLowerCase() == 'approved').length;
          final rejectedCount = allReports.where((r) => r.isRejected).length;

          // Tab-based filtered reports
          final activeTabIndex = _tabController.index;
          List<MissingPerson> tabReports;

          switch (activeTabIndex) {
            case 1: // Pending
              tabReports = allReports.where((r) => r.isPending).toList();
              break;
            case 2: // Approved
              tabReports = allReports.where((r) => r.verificationStatus.toLowerCase() == 'approved').toList();
              break;
            case 3: // Verified
              tabReports = allReports.where((r) => r.isVerified).toList();
              break;
            case 4: // Rejected
              tabReports = allReports.where((r) => r.isRejected).toList();
              break;
            case 0: // All
            default:
              tabReports = allReports;
              break;
          }

          // Search filtering
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase().trim();
            tabReports = tabReports.where((r) {
              return r.fullName.toLowerCase().contains(q) ||
                  r.lastSeenLocation.toLowerCase().contains(q) ||
                  r.contactNumber.contains(q) ||
                  r.description.toLowerCase().contains(q);
            }).toList();
          }

          return Column(
            children: [
              // Top Stats Cards
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatCard('Total Cases', '$totalCount', const Color(0xFF0F172A), Icons.folder_outlined),
                      const SizedBox(width: 8),
                      _buildStatCard('Pending', '$pendingCount', const Color(0xFFB45309), Icons.hourglass_top_rounded, bg: const Color(0xFFFFFBEB)),
                      const SizedBox(width: 8),
                      _buildStatCard('Verified', '$verifiedCount', const Color(0xFF047857), Icons.verified_rounded, bg: const Color(0xFFECFDF5)),
                      const SizedBox(width: 8),
                      _buildStatCard('Approved', '$approvedCount', const Color(0xFF1D4ED8), Icons.check_circle_outline, bg: const Color(0xFFEFF6FF)),
                      const SizedBox(width: 8),
                      _buildStatCard('Rejected', '$rejectedCount', const Color(0xFFB91C1C), Icons.cancel_outlined, bg: const Color(0xFFFEF2F2)),
                    ],
                  ),
                ),
              ),

              // Search Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search cases by name, location or contact...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),

              // Tab Bar
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: const Color(0xFF2563EB),
                  unselectedLabelColor: const Color(0xFF64748B),
                  indicatorColor: const Color(0xFF2563EB),
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    Tab(text: 'All ($totalCount)'),
                    Tab(text: 'Pending ($pendingCount)'),
                    Tab(text: 'Approved ($approvedCount)'),
                    Tab(text: 'Verified ($verifiedCount)'),
                    Tab(text: 'Rejected ($rejectedCount)'),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Reports List View
              Expanded(
                child: tabReports.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No cases match your search.'
                                  : 'No reports in this category.',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: tabReports.length,
                        itemBuilder: (context, index) {
                          final report = tabReports[index];
                          return _buildAdminReportCard(report);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String count,
    Color textColor,
    IconData icon, {
    Color bg = const Color(0xFFF1F5F9),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: textColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminReportCard(MissingPerson report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: report.isVerified
              ? const Color(0xFF10B981).withOpacity(0.4)
              : const Color(0xFFE2E8F0),
          width: report.isVerified ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Info Row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 72,
                    height: 84,
                    color: const Color(0xFFF1F5F9),
                    child: AppPhotoView(
                      photoUrl: report.photoUrl,
                      width: 72,
                      height: 84,
                      fit: BoxFit.cover,
                      placeholderIcon: Icons.person_rounded,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badges Row
                      Row(
                        children: [
                          VerificationStatusBadge(
                            status: report.verificationStatus,
                            isSmall: true,
                          ),
                          const SizedBox(width: 6),
                          StatusBadge(
                            status: report.status,
                            isSmall: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Name & Age
                      Text(
                        report.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${report.age} yrs • ${report.gender}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),

                      // Location & Date
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFFEF4444)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              report.lastSeenLocation,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatDate(report.missingDate),
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Rejection Reason Alert if Rejected
          if (report.isRejected && report.rejectionReason != null && report.rejectionReason!.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Color(0xFFDC2626)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Rejection reason: ${report.rejectionReason}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 1),

          // Action Buttons Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(13),
                bottomRight: Radius.circular(13),
              ),
            ),
            child: Row(
              children: [
                // View Details
                IconButton(
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 18, color: Color(0xFF64748B)),
                  tooltip: 'View Case',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PersonDetailScreen(personId: report.id),
                      ),
                    );
                  },
                ),

                // Edit Details
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2563EB)),
                  tooltip: 'Edit Details',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminEditReportScreen(report: report),
                      ),
                    );
                  },
                ),

                // Delete
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                  tooltip: 'Delete Report',
                  onPressed: () => _showDeleteConfirmation(report),
                ),

                const Spacer(),

                // Verify Button
                if (!report.isVerified)
                  TextButton.icon(
                    onPressed: () => _showVerifyConfirmation(report),
                    icon: const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF059669)),
                    label: const Text(
                      'Verify',
                      style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),

                // Approve Button
                if (report.isPending || report.isRejected)
                  TextButton.icon(
                    onPressed: () => _updateVerificationStatus(report, 'Approved'),
                    icon: const Icon(Icons.check_rounded, size: 15, color: Color(0xFF2563EB)),
                    label: const Text(
                      'Approve',
                      style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),

                // Reject Button
                if (!report.isRejected)
                  TextButton.icon(
                    onPressed: () => _showRejectDialog(report),
                    icon: const Icon(Icons.close_rounded, size: 15, color: Color(0xFFDC2626)),
                    label: const Text(
                      'Reject',
                      style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
