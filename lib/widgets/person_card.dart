import 'package:flutter/material.dart';
import '../models/missing_person.dart';
import '../services/missing_person_repository.dart';
import '../screens/person_detail_screen.dart';
import 'app_photo_view.dart';
import 'full_screen_image_viewer.dart';
import 'status_badge.dart';
import 'verified_badge.dart';

class PersonCard extends StatelessWidget {
  final MissingPerson person;
  final VoidCallback? onBookmarkToggled;

  const PersonCard({
    super.key,
    required this.person,
    this.onBookmarkToggled,
  });

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inHours < 1) {
      return '${diff.inMinutes} mins ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = person.isUrgent && person.status != PersonStatus.found;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
          width: isUrgent ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isUrgent
                ? const Color(0xFFEF4444).withOpacity(0.08)
                : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PersonDetailScreen(personId: person.id),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isUrgent)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFDC2626),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'CRITICAL AMBER ALERT / URGENT SEARCH',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo with fallback
                    GestureDetector(
                      onTap: (person.photoUrl != null && person.photoUrl!.isNotEmpty)
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FullScreenImageViewer(
                                    photoUrl: person.photoUrl!,
                                    title: person.fullName,
                                    subtitle: 'Age ${person.age} · Missing from ${person.lastSeenLocation}',
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Container(
                              width: 96,
                              height: 118,
                              color: const Color(0xFFF1F5F9),
                              child: AppPhotoView(
                                photoUrl: person.avatarUrl,
                                width: 96,
                                height: 118,
                                fit: BoxFit.cover,
                              ),
                            ),
                          if (person.sightings.isNotEmpty)
                            Positioned(
                              bottom: 4,
                              left: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A).withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${person.sightings.length} Sighting${person.sightings.length > 1 ? 's' : ''}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                    // Info Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Row(
                                children: [
                                  StatusBadge(
                                    status: person.status,
                                    isUrgent: person.isUrgent,
                                    isSmall: true,
                                  ),
                                  if (person.isVerified) ...[
                                    const SizedBox(width: 6),
                                    const VerifiedBadge(isSmall: true),
                                  ],
                                ],
                              ),
                              const Spacer(),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  person.isBookmarked
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_border_rounded,
                                  color: person.isBookmarked
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF94A3B8),
                                  size: 22,
                                ),
                                onPressed: () {
                                  MissingPersonRepository().toggleBookmark(person.id);
                                  onBookmarkToggled?.call();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Name
                          Text(
                            person.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),

                          // Demographics: Age, Gender
                          Text(
                            '${person.age} years old • ${person.gender}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Last seen location
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: Color(0xFFEF4444),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  person.lastSeenCity,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Missing time
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Missing: ${_formatDate(person.lastSeenDate)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom bar of card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                  border: Border(
                    top: BorderSide(color: Color(0xFFF1F5F9)),
                  ),
                ),
                child: Row(
                  children: [
                    if (person.rewardAmount != null && person.rewardAmount! > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF9C3),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFDE047)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.monetization_on_rounded,
                              size: 13,
                              color: Color(0xFF854D0E),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Reward: \$${person.rewardAmount!.toInt()}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF854D0E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    const Text(
                      'View Case Details',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: Color(0xFF2563EB),
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
}
