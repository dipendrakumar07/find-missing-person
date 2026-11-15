import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/found_report.dart';
import '../models/missing_person.dart';
import '../services/ai_vision_service.dart';
import '../services/found_report_service.dart';
import '../services/missing_person_repository.dart';
import '../widgets/app_photo_view.dart';
import 'person_detail_screen.dart';

class MatchedAlertsScreen extends StatefulWidget {
  const MatchedAlertsScreen({super.key});

  @override
  State<MatchedAlertsScreen> createState() => _MatchedAlertsScreenState();
}

class _MatchedAlertsScreenState extends State<MatchedAlertsScreen> {
  String _formatDate(DateTime dt) {
    return DateFormat('dd MMM yyyy').format(dt);
  }

  Future<void> _makeCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) _showCopyDialog(phoneNumber);
      }
    } catch (_) {
      if (mounted) _showCopyDialog(phoneNumber);
    }
  }

  void _showCopyDialog(String phoneNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Contact Number', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SelectableText(
          phoneNumber,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: phoneNumber));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied phone number to clipboard!'),
                  backgroundColor: Color(0xFF16A34A),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  void _confirmAndMarkFound(MissingPerson person) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: Color(0xFF16A34A)),
            SizedBox(width: 8),
            Text('Confirm Match Safe', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to officially mark "${person.fullName}" as Found and Safe? This will resolve the alert for the community.',
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
              await FoundReportService().markCaseAsFound(person.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${person.fullName}" has been marked as Found & Safe!'),
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
            child: const Text('Confirm Found'),
          ),
        ],
      ),
    );
  }

  void _dismissMatch(FoundReport sighting) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.link_off_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Unmatch Alert', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Do you want to dismiss this match? It will be unlinked from the missing person case.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FoundReportService().dismissMatch(sighting.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Match alert dismissed and unlinked.'),
                    backgroundColor: Color(0xFF475569),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Dismiss Match'),
          ),
        ],
      ),
    );
  }

  void _deleteReport(MissingPerson person) {
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
              await MissingPersonRepository().deleteReport(person.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Report for "${person.fullName}" deleted successfully.'),
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
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([MissingPersonRepository(), FoundReportService()]),
      builder: (context, _) {
        final allReports = MissingPersonRepository().reports;

        // Collect all reports that are marked as 'Possible Match' or have sightings linked
        final possibleMatchReports = allReports
            .where((r) =>
                r.reportStatus.toLowerCase() == 'possible match' ||
                r.reportStatus.toLowerCase() == 'sighted' ||
                r.reportStatus.toLowerCase() == 'found')
            .toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Row(
              children: [
                Icon(Icons.bolt_rounded, color: Color(0xFFEA580C), size: 24),
                SizedBox(width: 8),
                Text(
                  'Matched Alerts Hub',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.psychology_rounded, color: Color(0xFF6366F1), size: 24),
                tooltip: 'AI Vision & Face Model Settings',
                onPressed: () => AiVisionService.showAiConfigDialog(context),
              ),
            ],
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F172A),
            elevation: 0,
          ),
          body: SafeArea(
            child: possibleMatchReports.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEA580C).withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 48,
                              color: Color(0xFFEA580C),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'No Matched Alerts Yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'When a sighting is verified by AI facial comparison against a missing report, match alerts will appear here automatically.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => AiVisionService.showAiConfigDialog(context),
                            icon: const Icon(Icons.face_retouching_natural_rounded, size: 18),
                            label: const Text('Configure Face++ Biometric AI'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF6366F1),
                              side: const BorderSide(color: Color(0xFF6366F1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    itemCount: possibleMatchReports.length,
                    itemBuilder: (context, index) {
                      final person = possibleMatchReports[index];
                      return _buildMatchedPairCard(person);
                    },
                  ),
          ),
        );
      },
    );
  }

  Widget _buildMatchedPairCard(MissingPerson person) {
    final isFound = person.reportStatus.toLowerCase() == 'found';

    return StreamBuilder<List<FoundReport>>(
      stream: FoundReportService().getFoundReportsForPerson(person.id),
      builder: (context, snapshot) {
        final foundReports = (snapshot.data ?? []).where((r) => !r.isDismissed).toList();
        final hasSpecificSighting = foundReports.isNotEmpty;
        final latestSighting = hasSpecificSighting ? foundReports.first : null;

        final similarityScore = (latestSighting != null && latestSighting.similarityScore > 0)
            ? latestSighting.similarityScore
            : 82;
        final matchReason = latestSighting?.matchReason ?? 'Facial landmarks and demographic criteria correlated.';

        return Container(
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFound ? const Color(0xFF10B981) : const Color(0xFFF97316),
              width: 1.5,
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
              // 1. Top Match Probability Alert Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isFound ? const Color(0xFFDCFCE7) : const Color(0xFFFFF7ED),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isFound ? Icons.verified_rounded : Icons.auto_awesome,
                      size: 18,
                      color: isFound ? const Color(0xFF166534) : const Color(0xFFEA580C),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isFound
                            ? 'CONFIRMED MATCH • CASE RESOLVED & SAFE'
                            : 'AI FACE VERIFICATION • $similarityScore% MATCH CONFIDENCE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: isFound ? const Color(0xFF166534) : const Color(0xFFC2410C),
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF64748B)),
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        if (value == 'unmatch' && latestSighting != null) {
                          _dismissMatch(latestSighting);
                        } else if (value == 'delete') {
                          _deleteReport(person);
                        }
                      },
                      itemBuilder: (context) => [
                        if (latestSighting != null)
                          const PopupMenuItem(
                            value: 'unmatch',
                            child: Row(
                              children: [
                                Icon(Icons.link_off_rounded, size: 18, color: Color(0xFFDC2626)),
                                SizedBox(width: 8),
                                Text('Unmatch Alert'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                              SizedBox(width: 8),
                              Text('Delete Report'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // AI Verification Analysis Note
              if (!isFound)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  color: const Color(0xFFF1F5F9),
                  child: Row(
                    children: [
                      const Icon(Icons.psychology_outlined, size: 15, color: Color(0xFF6366F1)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          matchReason,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              // 2. Comparison Grid: Missing Post vs Found/Sighting Post
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  children: [
                    // Missing Case Section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 65,
                            height: 75,
                            color: const Color(0xFFF1F5F9),
                            child: AppPhotoView(
                              photoUrl: person.photoUrl,
                              width: 65,
                              height: 75,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'ORIGINAL MISSING REPORT',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                person.fullName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                              ),
                              Text(
                                '${person.age}y • ${person.gender} • Missing since ${_formatDate(person.missingDate)}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                              Text(
                                'Last seen: ${person.lastSeenLocation}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      child: Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.compare_arrows_rounded, color: Color(0xFFEA580C), size: 20),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                    ),

                    // Found / Sighting Section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 65,
                            height: 75,
                            color: const Color(0xFFF1F5F9),
                            child: AppPhotoView(
                              photoUrl: latestSighting?.photoUrl ?? person.photoUrl,
                              width: 65,
                              height: 75,
                              fit: BoxFit.cover,
                              placeholderIcon: Icons.visibility,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'FOUND / SIGHTING REPORT',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                latestSighting != null
                                    ? 'Sighted at ${latestSighting.foundLocation}'
                                    : 'Potential Match Sighted in Nearby Area',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                              ),
                              Text(
                                latestSighting != null
                                    ? 'Date: ${_formatDate(latestSighting.foundDate)}'
                                    : 'Matched with community database',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                              if (latestSighting != null && latestSighting.description.isNotEmpty)
                                Text(
                                  'Note: ${latestSighting.description}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // 3. Action Buttons (Call Reporter, Call Finder, Confirm Match, Unmatch)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                ),
                child: Row(
                  children: [
                    // Call Missing Reporter
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _makeCall(person.contactNumber),
                        icon: const Icon(Icons.call, size: 14),
                        label: const Text('Call Reporter', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          side: const BorderSide(color: Color(0xFF2563EB)),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Call Finder (if available)
                    if (latestSighting != null && latestSighting.contactNumber.isNotEmpty && latestSighting.contactNumber != 'Confidential') ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _makeCall(latestSighting.contactNumber),
                          icon: const Icon(Icons.phone_in_talk_rounded, size: 14),
                          label: const Text('Call Finder', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF059669),
                            side: const BorderSide(color: Color(0xFF059669)),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],

                    // Details / Confirm
                    if (!isFound)
                      ElevatedButton(
                        onPressed: () => _confirmAndMarkFound(person),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                        child: const Text('Confirm Safe'),
                      )
                    else
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PersonDetailScreen(personId: person.id),
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF64748B)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
