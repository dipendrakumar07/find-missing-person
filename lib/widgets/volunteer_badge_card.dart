import 'package:flutter/material.dart';

class VolunteerBadgeCard extends StatelessWidget {
  const VolunteerBadgeCard({super.key});

  @override
  Widget build(BuildContext context) {
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
          // Header with Level
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Citizen Safety Champion',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'TIER 1 GUARDIAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Your active participation helps bring missing loved ones home sooner.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          // Badges Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBadgeItem(
                icon: Icons.shield_rounded,
                color: const Color(0xFF2563EB),
                label: 'First Alert',
                status: 'Active',
              ),
              _buildBadgeItem(
                icon: Icons.auto_awesome_rounded,
                color: const Color(0xFF7C3AED),
                label: 'Eagle Eye',
                status: 'Unlocked',
              ),
              _buildBadgeItem(
                icon: Icons.share_rounded,
                color: const Color(0xFF059669),
                label: 'Beacon',
                status: 'Unlocked',
              ),
              _buildBadgeItem(
                icon: Icons.favorite_rounded,
                color: const Color(0xFFEA580C),
                label: 'Angel Finder',
                status: 'In Progress',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem({
    required IconData icon,
    required Color color,
    required String label,
    required String status,
  }) {
    final isLocked = status == 'In Progress';
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isLocked ? const Color(0xFFF1F5F9) : color.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: isLocked ? const Color(0xFFCBD5E1) : color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: isLocked ? const Color(0xFF94A3B8) : color,
            size: 24,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isLocked ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
          ),
        ),
        Text(
          status,
          style: TextStyle(
            fontSize: 9.5,
            color: isLocked ? const Color(0xFF94A3B8) : color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

