import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/missing_person.dart';
import '../screens/admin/admin_edit_report_screen.dart';
import '../screens/match_result_screen.dart';
import '../screens/person_detail_screen.dart';
import '../screens/public_profile_screen.dart';
import '../screens/report_found_person_screen.dart';
import '../screens/report_sighting_dialog.dart';
import '../services/auth_service.dart';
import '../services/missing_person_repository.dart';
import '../services/photo_matching_service.dart';
import 'app_photo_view.dart';
import 'full_screen_image_viewer.dart';
import 'missing_poster_dialog.dart';
import 'verified_badge.dart';

class SocialPostCard extends StatefulWidget {
  final MissingPerson person;
  final VoidCallback? onStatusChanged;

  const SocialPostCard({
    super.key,
    required this.person,
    this.onStatusChanged,
  });

  @override
  State<SocialPostCard> createState() => _SocialPostCardState();
}

class _SocialPostCardState extends State<SocialPostCard> {
  bool _isCheckingAi = false;

  String _formatDate(DateTime dt) {
    return DateFormat('dd MMM yyyy').format(dt);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(dt);
  }

  Future<void> _contactReporter(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) _showCopyPhoneDialog(phoneNumber);
      }
    } catch (_) {
      if (mounted) _showCopyPhoneDialog(phoneNumber);
    }
  }

  void _showCopyPhoneDialog(String phoneNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.phone_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Contact Reporter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reporter Phone Number:', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
            const SizedBox(height: 6),
            SelectableText(
              phoneNumber,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: phoneNumber));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contact number copied to clipboard.'),
                  backgroundColor: Color(0xFF16A34A),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy Number'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _sharePost() {
    final p = widget.person;
    final text = '🚨 MISSING PERSON ALERT 🚨\n\n'
        'Name: ${p.fullName}\n'
        'Age / Gender: ${p.age} yrs, ${p.gender}\n'
        'Last Seen Location: ${p.lastSeenLocation}\n'
        'Missing Date: ${_formatDate(p.missingDate)}\n'
        'Description: ${p.description}\n\n'
        'If seen or found, please call: ${p.contactNumber}\n'
        'Shared via FindMissingPerson Community Portal';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Missing person post alert copied to clipboard! You can paste and share anywhere.'),
        backgroundColor: Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _checkAiMatchForThisPost() async {
    final p = widget.person;
    if (p.photoUrl == null || p.photoUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This post does not have a photo for AI matching.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isCheckingAi = true;
    });

    try {
      final allReports = MissingPersonRepository()
          .reports
          .where((r) => r.id != p.id)
          .toList();

      final matches = await PhotoMatchingService().findMatches(
        photoUrl: p.photoUrl,
        existingReports: allReports,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MatchResultScreen(
            matches: matches,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI matching notice: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingAi = false;
        });
      }
    }
  }

  void _confirmDeletePost() {
    final currentUserId = AuthService().userId;
    final isOwner = (widget.person.reportedBy != null && widget.person.reportedBy == currentUserId) || AuthService().isCurrentAdmin;
    if (!isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only the author who created this post or an admin can delete it.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Delete Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete the report for "${widget.person.fullName}"? This action cannot be undone.',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await MissingPersonRepository().deleteReport(widget.person.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Report for "${widget.person.fullName}" has been deleted.'),
                    backgroundColor: const Color(0xFFDC2626),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final person = widget.person;
    final isFound = person.reportStatus.toLowerCase() == 'found';
    final isPossibleMatch =
        person.reportStatus.toLowerCase() == 'possible match' ||
            person.reportStatus.toLowerCase() == 'sighted';
    final currentUserId = AuthService().userId;
    final isOwner = (person.reportedBy != null && person.reportedBy == currentUserId) || AuthService().isCurrentAdmin;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFound ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
          width: isFound ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Post Header (Facebook Style with Avatar, Name, Relative Time, and Status)
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Reporter / Person Initial Avatar (Tappable to view public profile)
                GestureDetector(
                  onTap: () {
                    if (person.reportedBy != null && person.reportedBy!.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PublicProfileScreen(
                            userId: person.reportedBy!,
                          ),
                        ),
                      );
                    }
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: isFound
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFF2563EB).withOpacity(0.12),
                    child: Text(
                      person.fullName.isNotEmpty ? person.fullName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isFound ? const Color(0xFF166534) : const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Case Title & Post Timestamp
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              person.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (person.isVerified) ...[
                            const SizedBox(width: 4),
                            const VerifiedBadge(isSmall: true),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.public_rounded, size: 12, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(person.reportDate),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          if (person.reportedBy != null && person.reportedBy!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            const Text('·', style: TextStyle(color: Color(0xFF94A3B8))),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PublicProfileScreen(
                                      userId: person.reportedBy!,
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                'Reporter Profile',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // 3-Dots Menu for Post Actions (Strictly Protected: Only Owner/Admin can Edit or Delete)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF64748B)),
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'details') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PersonDetailScreen(personId: person.id),
                        ),
                      );
                    } else if (value == 'share') {
                      _sharePost();
                    } else if (value == 'poster') {
                      MissingPosterDialog.show(context, person);
                    } else if (value == 'profile' && person.reportedBy != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PublicProfileScreen(userId: person.reportedBy!),
                        ),
                      );
                    } else if (value == 'edit') {
                      if (isOwner) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminEditReportScreen(report: person),
                          ),
                        );
                      }
                    } else if (value == 'delete') {
                      if (isOwner) {
                        _confirmDeletePost();
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF2563EB)),
                          SizedBox(width: 8),
                          Text('View Details'),
                        ],
                      ),
                    ),
                    if (person.reportedBy != null && person.reportedBy!.isNotEmpty)
                      const PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.account_circle_outlined, size: 18, color: Color(0xFF7C3AED)),
                            SizedBox(width: 8),
                            Text('View Reporter Profile'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share_outlined, size: 18, color: Color(0xFF0F172A)),
                          SizedBox(width: 8),
                          Text('Share Alert'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'poster',
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf_outlined, size: 18, color: Color(0xFFDC2626)),
                          SizedBox(width: 8),
                          Text('Generate Notice Poster'),
                        ],
                      ),
                    ),
                    if (isOwner) ...[
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFF2563EB)),
                            SizedBox(width: 8),
                            Text('Edit Post'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                            SizedBox(width: 8),
                            Text('Delete Post', style: TextStyle(color: Color(0xFFDC2626))),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // 2. Post Headline & Key Information Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFFEF4444)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Last seen: ${person.lastSeenLocation}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${person.age}y • ${person.gender}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
                if (person.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    person.description,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF1E293B),
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 3. Post Photo Banner (Facebook Style Uncropped & Full Screen on Tap)
          if (person.photoUrl != null && person.photoUrl!.isNotEmpty)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenImageViewer(
                      photoUrl: person.photoUrl!,
                      title: person.fullName,
                      subtitle: 'Age ${person.age} · Missing from ${person.lastSeenLocation}',
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 380, minHeight: 220),
                color: const Color(0xFF0F172A),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AppPhotoView(
                      photoUrl: person.photoUrl,
                      width: double.infinity,
                      height: 320,
                      fit: BoxFit.contain, // Uncropped photo
                      placeholderIcon: Icons.person_rounded,
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fullscreen_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Tap to view full',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 8),
          const Divider(height: 1),

          // 4. Facebook-Style Interactive Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 1. Contact Reporter Button
                TextButton.icon(
                  onPressed: () => _contactReporter(person.contactNumber),
                  icon: const Icon(Icons.call_rounded, size: 17, color: Color(0xFF2563EB)),
                  label: const Text(
                    'Contact',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),

                // 2. Report Sighting Button
                TextButton.icon(
                  onPressed: () {
                    ReportSightingDialog.show(context, person);
                  },
                  icon: const Icon(Icons.visibility_rounded, size: 17, color: Color(0xFF059669)),
                  label: const Text(
                    'I Saw Info',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF059669),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),

                // 3. AI Match Check
                TextButton.icon(
                  onPressed: _isCheckingAi ? null : _checkAiMatchForThisPost,
                  icon: _isCheckingAi
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C3AED)),
                        )
                      : const Icon(Icons.auto_awesome, size: 17, color: Color(0xFF7C3AED)),
                  label: const Text(
                    'AI Match',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  ),
                ),

                // 4. Generate Poster Button
                TextButton.icon(
                  onPressed: () => MissingPosterDialog.show(context, person),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 17, color: Color(0xFFDC2626)),
                  label: const Text(
                    'Poster',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  ),
                ),

                // 5. Share Post Button
                TextButton.icon(
                  onPressed: _sharePost,
                  icon: const Icon(Icons.share_rounded, size: 17, color: Color(0xFF475569)),
                  label: const Text(
                    'Share',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
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
