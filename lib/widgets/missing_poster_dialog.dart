import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/missing_person.dart';
import 'app_photo_view.dart';

class MissingPosterDialog extends StatelessWidget {
  final MissingPerson person;

  const MissingPosterDialog({super.key, required this.person});

  static Future<void> show(BuildContext context, MissingPerson person) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => MissingPosterDialog(person: person),
    );
  }

  String _formatDate(DateTime dt) {
    return DateFormat('dd MMMM yyyy').format(dt);
  }

  Future<void> _shareOnWhatsApp(BuildContext context) async {
    final message = '🚨 *URGENT MISSING PERSON NOTICE* 🚨\n\n'
        '👤 *Name:* ${person.fullName}\n'
        '🎂 *Age / Gender:* ${person.age} years old (${person.gender})\n'
        '📍 *Last Seen Location:* ${person.lastSeenLocation}\n'
        '📅 *Missing Since:* ${_formatDate(person.missingDate)}\n'
        '📝 *Description:* ${person.description}\n\n'
        '📞 *Emergency Contact:* ${person.contactNumber}\n'
        '🚓 *Police Emergency:* 112 / 100\n\n'
        'Please forward this alert to groups to help reunite this family. Every share matters!';

    final uri = Uri.parse('https://api.whatsapp.com/send?text=${Uri.encodeComponent(message)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Clipboard.setData(ClipboardData(text: message));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notice copied to clipboard for WhatsApp!'),
              backgroundColor: Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      Clipboard.setData(ClipboardData(text: message));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notice copied to clipboard!'),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _copyNoticeText(BuildContext context) {
    final notice = '==============================\n'
        '      MISSING PERSON NOTICE   \n'
        '==============================\n\n'
        'NAME: ${person.fullName.toUpperCase()}\n'
        'AGE: ${person.age} Years\n'
        'GENDER: ${person.gender}\n'
        'LAST SEEN: ${person.lastSeenLocation}\n'
        'DATE MISSING: ${_formatDate(person.missingDate)}\n'
        'PHYSICAL DETAILS: ${person.description}\n\n'
        'IF SEEN OR ANY INFORMATION, CONTACT:\n'
        'Phone: ${person.contactNumber}\n'
        'National Police Helpline: 112 / 100\n'
        'Childline: 1098\n\n'
        'Issued via FindMissingPerson Citizen Portal\n'
        '==============================';

    Clipboard.setData(ClipboardData(text: notice));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Official Missing Notice copied to clipboard!'),
        backgroundColor: Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Top Poster Header (Bold Red Hazard Banner)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'OFFICIAL NOTICE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'MISSING PERSON',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const Text(
                      'HAVE YOU SEEN THIS PERSON? PLEASE HELP US REUNITE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFFEE2E2),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Poster Body with Border
              Container(
                color: const Color(0xFFFAFAFA),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Photo Frame with Warning Stripe
                    Container(
                      width: double.infinity,
                      height: 240,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDC2626), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: AppPhotoView(
                                photoUrl: person.photoUrl,
                                fit: BoxFit.cover,
                                placeholderIcon: Icons.person_rounded,
                              ),
                            ),
                            if (person.isUrgent)
                              Positioned(
                                top: 10,
                                left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDC2626),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.warning_amber_rounded, size: 14, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text(
                                        'URGENT SEARCH',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'CASE #${person.id.isEmpty ? "TEMP" : person.id.substring(0, person.id.length > 6 ? 6 : person.id.length).toUpperCase()}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Full Name Display
                    Text(
                      person.fullName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Key Details Grid
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            icon: Icons.cake_outlined,
                            label: 'Age & Gender',
                            value: '${person.age} Years  •  ${person.gender}',
                          ),
                          const Divider(height: 16),
                          _buildDetailRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Date Missing',
                            value: _formatDate(person.missingDate),
                          ),
                          const Divider(height: 16),
                          _buildDetailRow(
                            icon: Icons.location_on_outlined,
                            label: 'Last Seen At',
                            value: person.lastSeenLocation,
                            valueColor: const Color(0xFFDC2626),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Physical Description Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.notes_rounded, size: 16, color: Color(0xFFDC2626)),
                              SizedBox(width: 6),
                              Text(
                                'Physical Appearance & Details',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF991B1B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            person.description,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1E293B),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Contact Alert Callout Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'IF YOU HAVE ANY INFORMATION, PLEASE CALL IMMEDIATELY:',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF22C55E), size: 22),
                              const SizedBox(width: 8),
                              SelectableText(
                                person.contactNumber,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Police Helpline: 112 / 100  •  Childline: 1098',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFFCBD5E1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Action Buttons (WhatsApp Share & Copy Notice)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: [
                    // Copy Notice
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copyNoticeText(context),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Copy Notice'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // WhatsApp Share
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _shareOnWhatsApp(context),
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: const Text('Share Notice'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor ?? const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}

