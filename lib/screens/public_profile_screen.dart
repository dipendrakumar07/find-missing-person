import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/missing_person.dart';
import '../services/missing_person_repository.dart';
import '../widgets/app_photo_view.dart';
import 'person_detail_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  final String? fallbackName;

  const PublicProfileScreen({
    super.key,
    required this.userId,
    this.fallbackName,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get()
          .timeout(const Duration(seconds: 5));

      if (doc.exists && doc.data() != null) {
        if (mounted) {
          setState(() {
            _userData = doc.data()!;
            _isLoading = false;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime dt) {
    return DateFormat('dd MMM yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _userData?['displayName'] ?? widget.fallbackName ?? 'Community Volunteer';
    final photoUrl = (_userData?['photoURL'] ?? '').toString().trim();
    final bio = _userData?['bio'] ?? 'Community Safety Volunteer · Helping locate lost loved ones';
    final city = (_userData?['city'] ?? '').toString().trim();
    final phone = (_userData?['phoneNumber'] ?? '').toString().trim();

    final showPhone = _userData?['showPhone'] ?? true;
    final showCity = _userData?['showCity'] ?? true;

    final volunteerId = widget.userId.length >= 6
        ? '#FMP-${widget.userId.substring(0, 6).toUpperCase()}'
        : '#FMP-VOLUNTEER';

    // Get reports submitted by this user
    final allReports = MissingPersonRepository().reports;
    final userReports = allReports.where((r) => r.reportedBy == widget.userId).toList();
    final verifiedCount = userReports.where((r) => r.isVerified).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Facebook Style Cover & Avatar Header
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Cover Banner
                      Container(
                        height: 140,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.shield_outlined,
                            size: 70,
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                      ),

                      // Circular Profile Avatar
                      Positioned(
                        bottom: -46,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: SizedBox(
                              width: 92,
                              height: 92,
                              child: AppPhotoView(
                                photoUrl: photoUrl.isNotEmpty ? photoUrl : null,
                                width: 92,
                                height: 92,
                                fit: BoxFit.cover,
                                placeholderIcon: Icons.person_rounded,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 54),

                  // 2. User Name, Volunteer Badge & Bio
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),

                          // Volunteer ID Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              volunteerId,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Bio
                          Text(
                            bio,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF475569),
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3. Community Stats Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Reports Posted', '${userReports.length}', const Color(0xFF7C3AED)),
                          Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                          _buildStatItem('Verified Cases', '$verifiedCount', const Color(0xFF10B981)),
                          Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                          _buildStatItem('Community Role', 'Volunteer', const Color(0xFF2563EB)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Public Information Card (Facebook Style Privacy Protected)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.public_rounded, size: 18, color: Color(0xFF7C3AED)),
                              SizedBox(width: 8),
                              Text(
                                'Public Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Email: Strictly Private / Hidden
                          const Row(
                            children: [
                              Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF64748B)),
                              SizedBox(width: 8),
                              Text(
                                'Email:',
                                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Private · Hidden by user',
                                style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),

                          // City
                          if (showCity && city.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                                SizedBox(width: 8),
                                const Text(
                                  'Lives in:',
                                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  city,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],

                          // Phone
                          if (showPhone && phone.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF64748B)),
                                const SizedBox(width: 8),
                                const Text(
                                  'Contact:',
                                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  phone,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 5. Reports Posted by this User
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.feed_outlined, size: 20, color: Color(0xFF0F172A)),
                        const SizedBox(width: 8),
                        Text(
                          'Reports by $displayName (${userReports.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (userReports.isEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.search_off_rounded, size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              '$displayName has not submitted any reports yet.',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: userReports.length,
                      itemBuilder: (ctx, index) {
                        final report = userReports[index];
                        final isFound = report.reportStatus.toLowerCase() == 'found';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PersonDetailScreen(personId: report.id),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 60,
                                      height: 60,
                                      child: AppPhotoView(
                                        photoUrl: report.photoUrl,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        placeholderIcon: Icons.person_rounded,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
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
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Age ${report.age} · Last seen: ${report.lastSeenLocation}',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isFound
                                                    ? const Color(0xFFDCFCE7)
                                                    : const Color(0xFFFEF2F2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                report.reportStatus,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: isFound
                                                      ? const Color(0xFF166534)
                                                      : const Color(0xFFDC2626),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _formatDate(report.reportDate),
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
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
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

