import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyHelplinesScreen extends StatelessWidget {
  const EmergencyHelplinesScreen({super.key});

  Future<void> _makeCall(BuildContext context, String number, String name) async {
    final clean = number.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) _copyNumber(context, number, name);
      }
    } catch (_) {
      if (context.mounted) _copyNumber(context, number, name);
    }
  }

  void _copyNumber(BuildContext context, String number, String name) {
    Clipboard.setData(ClipboardData(text: number));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name number ($number) copied to clipboard!'),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final helplines = [
      {
        'title': 'National Emergency (All-In-One)',
        'number': '112',
        'desc': 'Police, Medical Ambulance & Disaster Response across India',
        'icon': Icons.emergency_rounded,
        'color': const Color(0xFFDC2626),
        'tag': 'PRIMARY SOS',
      },
      {
        'title': 'Police Control Room',
        'number': '100',
        'desc': 'Immediate local police assistance and filing missing reports',
        'icon': Icons.local_police_rounded,
        'color': const Color(0xFF2563EB),
        'tag': 'POLICE',
      },
      {
        'title': 'Childline (Missing Children)',
        'number': '1098',
        'desc': '24x7 toll-free emergency service for children in distress or missing',
        'icon': Icons.child_care_rounded,
        'color': const Color(0xFFD97706),
        'tag': 'CHILDREN',
      },
      {
        'title': 'Women & Safety Helpline',
        'number': '1091',
        'desc': 'Dedicated emergency support and immediate assistance for women',
        'icon': Icons.shield_rounded,
        'color': const Color(0xFF7C3AED),
        'tag': 'WOMEN',
      },
      {
        'title': 'Ambulance / Medical Emergency',
        'number': '102',
        'desc': 'Quick emergency medical ambulance service',
        'icon': Icons.medical_services_rounded,
        'color': const Color(0xFF059669),
        'tag': 'MEDICAL',
      },
      {
        'title': 'Senior Citizen National Helpline',
        'number': '14567',
        'desc': 'Elder Line for missing senior citizens and emergency support',
        'icon': Icons.elderly_rounded,
        'color': const Color(0xFF0D9488),
        'tag': 'SENIORS',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Emergency Helplines & SOS',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        children: [
          // Emergency Header Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDC2626).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'One-Tap Emergency Dial',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tap any helpline below to call immediately or copy number.',
                        style: TextStyle(
                          color: Color(0xFFFEE2E2),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Helplines List
          const Text(
            'Official Emergency Helplines',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          ...helplines.map((item) {
            final title = item['title'] as String;
            final number = item['number'] as String;
            final desc = item['desc'] as String;
            final icon = item['icon'] as IconData;
            final color = item['color'] as Color;
            final tag = item['tag'] as String;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 26),
                    ),
                    const SizedBox(width: 14),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                number,
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            desc,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Call & Copy Buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF64748B)),
                          tooltip: 'Copy Number',
                          onPressed: () => _copyNumber(context, number, title),
                        ),
                        InkWell(
                          onTap: () => _makeCall(context, number, title),
                          borderRadius: BorderRadius.circular(25),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.call_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Golden Hour Action Checklist
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb_rounded, color: Color(0xFF2563EB), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'First 24 Hours: Golden Rules Checklist',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildChecklistItem('1', 'File an immediate Police FIR (No waiting period required for missing children or adults).'),
                _buildChecklistItem('2', 'Collect recent high-resolution photos and details of clothing, scars, or height.'),
                _buildChecklistItem('3', 'Create a missing report here on FindMissingPerson for AI face matching & community alerts.'),
                _buildChecklistItem('4', 'Generate and share the Official Missing Poster on WhatsApp and social media.'),
                _buildChecklistItem('5', 'Check nearby hospitals, bus stands, railway stations, and local CCTV footage.'),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 9,
            backgroundColor: const Color(0xFF2563EB),
            child: Text(
              step,
              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B), height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

