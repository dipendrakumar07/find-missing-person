import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/missing_person.dart';
import 'ai_matcher.dart';
import 'ai_vision_service.dart';
import 'face_embedding_engine.dart';

export 'ai_matcher.dart' show MatchCandidate, AIPhotoMatcher;
export 'face_embedding_engine.dart' show FaceValidationStatus, FaceExtractionResult, FaceEmbeddingComparison;

/// Exception thrown when face scan validation fails (0 faces, multiple faces, blurry)
class FaceScanException implements Exception {
  final FaceValidationStatus status;
  final String message;
  const FaceScanException({required this.status, required this.message});

  @override
  String toString() => message;
}

/// Face++ & On-Device Hybrid AI Biometric Photo Matching Service
/// Powered by Face++ 106-Point Landmark Face Compare & MobileFaceNet Fallback.
class PhotoMatchingService {
  static final PhotoMatchingService _instance = PhotoMatchingService._internal();
  factory PhotoMatchingService() => _instance;
  PhotoMatchingService._internal();

  /// Primary function: Scans a query photo using Face++ Biometrics and On-Device Embeddings.
  Future<List<MatchCandidate>> scanAndMatchFace({
    File? imageFile,
    Uint8List? imageBytes,
    String? photoUrl,
    required List<MissingPerson> existingReports,
    double similarityThreshold = FaceEmbeddingEngine.defaultMatchThreshold,
  }) async {
    // 1. Prepare query image bytes
    Uint8List? bytes = imageBytes;
    if (bytes == null && imageFile != null && imageFile.existsSync()) {
      bytes = await imageFile.readAsBytes();
    } else if (bytes == null && photoUrl != null && photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('data:image')) {
        final commaIdx = photoUrl.indexOf(',');
        if (commaIdx != -1) {
          bytes = base64Decode(photoUrl.substring(commaIdx + 1));
        }
      }
    }

    // 2. Validate face presence
    final queryExtraction = bytes != null
        ? await FaceEmbeddingEngine().processAndExtractEmbedding(
            imageFile: imageFile,
            imageBytes: bytes,
          )
        : await FaceEmbeddingEngine().processAndExtractEmbedding(
            photoUrlOrBase64: photoUrl,
          );

    // 3. Filter active database candidates with available photos
    final candidatesWithPhotos = existingReports
        .where((r) => r.photoUrl != null && r.photoUrl!.isNotEmpty && r.reportStatus.toLowerCase() != 'found')
        .toList();

    if (candidatesWithPhotos.isEmpty) {
      return [];
    }

    final List<MatchCandidate> matches = [];
    final visionService = AiVisionService();
    final effectiveQueryPhoto = photoUrl ?? (bytes != null ? 'data:image/jpeg;base64,${base64Encode(bytes)}' : null);

    if (effectiveQueryPhoto == null) {
      return [];
    }

    // 4. Compare query against candidates using Face++ Biometric Engine
    for (final candidate in candidatesWithPhotos) {
      try {
        bool matchFound = false;

        // A. Primary: Face++ 106-Point Landmark Face Compare
        if (visionService.hasFacePlusKey) {
          final aiResult = await visionService.comparePhotos(
            photoUrl1: effectiveQueryPhoto,
            photoUrl2: candidate.photoUrl,
            name1: 'Query Person',
            name2: candidate.fullName,
            gender1: null,
            gender2: candidate.gender,
          );

          if (aiResult.isMatch || aiResult.similarityPercentage >= 60) {
            matches.add(
              MatchCandidate(
                person: candidate,
                confidenceScore: aiResult.similarityPercentage / 100.0,
                matchDescription: '${aiResult.similarityPercentage}% Biometric Match • ${aiResult.analysisReason}',
                matchAlgorithm: aiResult.algorithmUsed,
              ),
            );
            matchFound = true;
          }
        }

        // B. Fallback: On-Device Embedding comparison if Face++ did not match or was not used
        if (!matchFound && queryExtraction.isValid && queryExtraction.embedding != null) {
          List<double>? candidateEmbedding = candidate.faceEmbedding;

          if (candidateEmbedding == null || candidateEmbedding.length != 128) {
            final candidateExtraction = await FaceEmbeddingEngine().processAndExtractEmbedding(
              photoUrlOrBase64: candidate.photoUrl,
            );
            if (candidateExtraction.isValid) {
              candidateEmbedding = candidateExtraction.embedding;
            }
          }

          if (candidateEmbedding != null && candidateEmbedding.length == 128) {
            final comparison = FaceEmbeddingEngine().compareEmbeddings(
              embedding1: queryExtraction.embedding!,
              embedding2: candidateEmbedding,
              threshold: similarityThreshold,
            );

            if (comparison.isMatch) {
              matches.add(
                MatchCandidate(
                  person: candidate,
                  confidenceScore: comparison.similarityPercentage / 100.0,
                  matchDescription: '${comparison.matchStatus} (${comparison.similarityPercentage}% Similarity) • On-Device Biometric Alignment',
                  matchAlgorithm: 'On-Device MobileFaceNet (Cosine: ${comparison.cosineSimilarity.toStringAsFixed(3)})',
                ),
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Error matching candidate ${candidate.fullName}: $e');
      }
    }

    // Sort descending by highest confidence score
    matches.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));
    return matches;
  }

  /// Backward-compatible alias for existing callers
  Future<List<MatchCandidate>> findMatches({
    File? imageFile,
    Uint8List? imageBytes,
    String? photoUrl,
    required List<MissingPerson> existingReports,
  }) async {
    return scanAndMatchFace(
      imageFile: imageFile,
      imageBytes: imageBytes,
      photoUrl: photoUrl,
      existingReports: existingReports,
    );
  }
}

