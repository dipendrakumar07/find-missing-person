import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/found_report.dart';
import '../models/missing_person.dart';
import '../services/auth_service.dart';
import '../services/found_report_service.dart';
import '../services/missing_person_repository.dart';
import '../widgets/app_photo_view.dart';
import '../widgets/full_screen_image_viewer.dart';
import '../widgets/missing_poster_dialog.dart';
import '../widgets/verified_badge.dart';
import 'admin/admin_edit_report_screen.dart';
import 'public_profile_screen.dart';
import 'report_found_person_screen.dart';

class PersonDetailScreen extends StatefulWidget {
  final String personId;

  const PersonDetailScreen({
    super.key,
    required this.personId,
  });

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  String _formatDate(DateTime dt) {
    return DateFormat('dd MMMM yyyy').format(dt);
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
            const Text('Phone Number:', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
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

  void _showMarkAsFoundConfirmation(MissingPerson person) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A)),
            SizedBox(width: 8),
            Text('Mark as Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to mark "${person.fullName}" as Found / Safe? This will update the case status for all users.',
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
              await FoundReportService().markCaseAsFound(person.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Case status for "${person.fullName}" has been marked as Found.'),
                    backgroundColor: const Color(0xFF16A34A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm & Mark Found'),
          ),
        ],
      ),
    );
  }

  void _showStatusUpdateDialog(MissingPerson person) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Update Case Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Missing', 'Possible Match', 'Found'].map((status) {
            final isSelected = person.reportStatus.toLowerCase() == status.toLowerCase();
            return ListTile(
              leading: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
              ),
              title: Text(
                status == 'Found' ? 'Found / Safe' : status,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: const Color(0xFF0F172A),
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                final updated = person.copyWith(reportStatus: status);
                await MissingPersonRepository().updateReport(updated);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Report status updated to "$status".'),
                      backgroundColor: const Color(0xFF16A34A),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _shareReport(MissingPerson person) {
    final alertText =
        '🚨 MISSING PERSON ALERT: ${person.fullName}, Age: ${person.age}, Gender: ${person.gender}. '
        'Last seen at ${person.lastSeenLocation} on ${_formatDate(person.missingDate)}. '
        'If you have any information, please contact: ${person.contactNumber}.';

    Clipboard.setData(ClipboardData(text: alertText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Missing person alert copied to clipboard!'),
        backgroundColor: Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmDeleteReport(MissingPerson person) {
    final currentUserId = AuthService().userId;
    final isReporter = person.reportedBy != null && person.reportedBy == currentUserId;
    if (!isReporter && !AuthService().isCurrentAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only the author who posted this report or an admin can delete it.'),
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
          'Are you sure you want to permanently delete the report for "${person.fullName}"? This action cannot be undone.',
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
              Navigator.pop(context);
              await MissingPersonRepository().deleteReport(person.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Report for "${person.fullName}" has been deleted.'),
                  backgroundColor: const Color(0xFFDC2626),
                  behavior: SnackBarBehavior.floating,
                ),
              );
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

  Future<void> _pickAndUploadPhoto(MissingPerson person) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Attach / Change Photo',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              const Text(
                'Photo will be saved permanently to Cloud so it never disappears.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF2563EB)),
                ),
                title: const Text('Take Photo with Camera', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(bCtx);
                  _processPickedPhoto(person, ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF7C3AED)),
                ),
                title: const Text('Select from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(bCtx);
                  _processPickedPhoto(person, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPickedPhoto(MissingPerson person, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (picked == null) return;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Saving photo permanently to Cloud...'),
            ],
          ),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );

      final bytes = await picked.readAsBytes();
      final base64String = base64Encode(bytes);
      final dataUri = 'data:image/jpeg;base64,$base64String';

      await MissingPersonRepository().updatePhoto(person.id, dataUri);

      if (!mounted) return;

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo successfully saved permanently to Cloud!'),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update photo: $e'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MissingPersonRepository(),
      builder: (context, _) {
        final person = MissingPersonRepository().getPersonById(widget.personId);

        if (person == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Missing Person Details'),
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A),
            ),
            body: const Center(
              child: Text(
                'Missing person report not found.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
              ),
            ),
          );
        }

        final isFound = person.reportStatus.toLowerCase() == 'found';
        final isPossibleMatch =
            person.reportStatus.toLowerCase() == 'possible match' ||
                person.reportStatus.toLowerCase() == 'sighted';
        final currentUserId = AuthService().userId;
        final isReporter = person.reportedBy != null && person.reportedBy == currentUserId;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text(
              'Person Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F172A),
            actions: [
              if (AuthService().isCurrentAdmin || isReporter)
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded, size: 24, color: Color(0xFF2563EB)),
                  tooltip: 'Edit Report',
                  onPressed: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminEditReportScreen(report: person),
                      ),
                    );
                    if (updated == true && mounted) {
                      setState(() {});
                    }
                  },
                ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 22, color: Color(0xFFDC2626)),
                tooltip: 'Notice Poster',
                onPressed: () => MissingPosterDialog.show(context, person),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, size: 22),
                tooltip: 'Share Report',
                onPressed: () => _shareReport(person),
              ),
              if (isReporter || AuthService().isCurrentAdmin)
                IconButton(
                  icon: const Icon(Icons.tune_rounded, size: 22),
                  tooltip: 'Update Status',
                  onPressed: () => _showStatusUpdateDialog(person),
                ),
              if (isReporter || AuthService().isCurrentAdmin)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 22, color: Color(0xFFDC2626)),
                  tooltip: 'Delete Report',
                  onPressed: () => _confirmDeleteReport(person),
                ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo Banner Card with Edit/Upload Overlay & Full Screen Zoom on Tap
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: (person.photoUrl != null && person.photoUrl!.isNotEmpty)
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FullScreenImageViewer(
                                      photoUrl: person.photoUrl!,
                                      title: person.fullName,
                                      subtitle: 'Age ${person.age} · Last seen: ${person.lastSeenLocation}',
                                    ),
                                  ),
                                );
                              }
                            : null,
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 220, maxHeight: 380),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: AppPhotoView(
                              photoUrl: person.photoUrl,
                              width: double.infinity,
                              height: 320,
                              fit: BoxFit.contain, // Uncropped photo
                              placeholderIcon: Icons.person_rounded,
                            ),
                          ),
                        ),
                      ),
                      if (person.photoUrl != null && person.photoUrl!.isNotEmpty)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.65),
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
                      if (isReporter || AuthService().isCurrentAdmin)
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: ElevatedButton.icon(
                            onPressed: () => _pickAndUploadPhoto(person),
                            icon: const Icon(Icons.camera_alt_rounded, size: 16),
                            label: Text(
                              (person.photoUrl == null ||
                                      person.photoUrl!.isEmpty ||
                                      person.photoUrl!.contains('/cache/') ||
                                      person.photoUrl!.startsWith('/data/'))
                                  ? 'Add Photo'
                                  : 'Change Photo',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black.withOpacity(0.75),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 2,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Warning & Quick Add Banner if Photo is Missing or from local cache
                  if ((person.photoUrl == null ||
                          person.photoUrl!.isEmpty ||
                          person.photoUrl!.contains('/cache/') ||
                          person.photoUrl!.startsWith('/data/')) &&
                      (isReporter || AuthService().isCurrentAdmin)) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCD34D)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 22),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Photo is missing or not synced to cloud. Tap "Add Photo" to attach a photo permanently.',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _pickAndUploadPhoto(person),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD97706),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text('Add Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),

                  // Name & Status Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: person.isVerified
                            ? const Color(0xFF10B981).withOpacity(0.4)
                            : const Color(0xFFE2E8F0),
                        width: person.isVerified ? 1.5 : 1,
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
                        if (person.isVerified) ...[
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Official Verified Case • Confirmed by authorities',
                                    style: TextStyle(
                                      color: Color(0xFF065F46),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (person.isRejected && person.rejectionReason != null) ...[
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Report Rejected: ${person.rejectionReason}',
                                    style: const TextStyle(
                                      color: Color(0xFF991B1B),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      person.fullName,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  if (person.isVerified) ...[
                                    const SizedBox(width: 6),
                                    const VerifiedBadge(isSmall: true),
                                  ],
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isFound
                                    ? const Color(0xFFDCFCE7)
                                    : isPossibleMatch
                                        ? const Color(0xFFFEF3C7)
                                        : const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isFound
                                      ? const Color(0xFF166534).withOpacity(0.3)
                                      : isPossibleMatch
                                          ? const Color(0xFF92400E).withOpacity(0.3)
                                          : const Color(0xFF0369A1).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isFound
                                        ? Icons.check_circle_rounded
                                        : isPossibleMatch
                                            ? Icons.warning_amber_rounded
                                            : Icons.search_rounded,
                                    size: 14,
                                    color: isFound
                                        ? const Color(0xFF166534)
                                        : isPossibleMatch
                                            ? const Color(0xFF92400E)
                                            : const Color(0xFF0369A1),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isFound
                                        ? 'Found / Safe'
                                        : isPossibleMatch
                                            ? 'Possible Match'
                                            : 'Missing',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isFound
                                          ? const Color(0xFF166534)
                                          : isPossibleMatch
                                              ? const Color(0xFF92400E)
                                              : const Color(0xFF0369A1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),

                        // Key Info Grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoItem(
                                icon: Icons.cake_outlined,
                                label: 'Age',
                                value: '${person.age} years old',
                              ),
                            ),
                            Expanded(
                              child: _buildInfoItem(
                                icon: Icons.people_outline_rounded,
                                label: 'Gender',
                                value: person.gender,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoItem(
                                icon: Icons.event_rounded,
                                label: 'Missing Date',
                                value: _formatDate(person.missingDate),
                              ),
                            ),
                            Expanded(
                              child: _buildInfoItem(
                                icon: Icons.schedule_rounded,
                                label: 'Reported On',
                                value: _formatDate(person.reportDate),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoItem(
                          icon: Icons.location_on_outlined,
                          label: 'Last Seen Location',
                          value: person.lastSeenLocation,
                          iconColor: const Color(0xFFEF4444),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
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
                        const Row(
                          children: [
                            Icon(Icons.notes_rounded, size: 20, color: Color(0xFF2563EB)),
                            SizedBox(width: 8),
                            Text(
                              'Description & Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          person.description,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Contact Reporter Card & Action
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
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
                        const Row(
                          children: [
                            Icon(Icons.contact_phone_outlined, size: 20, color: Color(0xFF2563EB)),
                            SizedBox(width: 8),
                            Text(
                              'Contact Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.phone_outlined, color: Color(0xFF2563EB), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  person.contactNumber,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Contact Reporter Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () => _contactReporter(person.contactNumber),
                            icon: const Icon(Icons.call_rounded, size: 20),
                            label: const Text('Contact Reporter'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // View Reporter Public Profile Button (Facebook Style)
                        if (person.reportedBy != null && person.reportedBy!.isNotEmpty) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PublicProfileScreen(
                                      userId: person.reportedBy!,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.account_circle_outlined, size: 20),
                              label: const Text('View Reporter Profile'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF7C3AED),
                                side: const BorderSide(color: Color(0xFFC4B5FD), width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],

                        // Generate Official Poster Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () => MissingPosterDialog.show(context, person),
                            icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                            label: const Text('Generate Printable Notice Poster'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons (Report Found Person & Mark as Found)
                  Row(
                    children: [
                      // Report Found Person (For citizens / finders)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReportFoundPersonScreen(
                                  preselectedPerson: person,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text('Report Sighting / Found'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F172A),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      if (isReporter || AuthService().isCurrentAdmin) ...[
                        const SizedBox(width: 10),
                        // Mark as Found (Strictly for original reporter or admin)
                        if (!isFound)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showMarkAsFoundConfirmation(person),
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: const Text('Mark as Found'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Sightings & Found Reports Feed (if any submitted)
                  StreamBuilder<List<FoundReport>>(
                    stream: FoundReportService().getFoundReportsForPerson(person.id),
                    builder: (context, snapshot) {
                      final foundReports = snapshot.data ?? [];
                      if (foundReports.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reported Sightings & Matches',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...foundReports.map((report) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 16, color: Color(0xFF2563EB)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          report.foundLocation,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ),
                                      Text(
                                        _formatDate(report.foundDate),
                                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    report.description,
                                    style: const TextStyle(color: Color(0xFF334155), fontSize: 13),
                                  ),
                                  if (report.photoUrl != null && report.photoUrl!.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: AppPhotoView(
                                        photoUrl: report.photoUrl,
                                        height: 120,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        placeholderIcon: Icons.visibility_rounded,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor ?? const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
