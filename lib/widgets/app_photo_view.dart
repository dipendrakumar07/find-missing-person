import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppPhotoView extends StatelessWidget {
  final String? photoUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final IconData placeholderIcon;

  const AppPhotoView({
    super.key,
    required this.photoUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.placeholderIcon = Icons.person_rounded,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    final url = photoUrl?.trim();
    if (url == null || url.isEmpty) {
      content = _buildPlaceholder();
    } else if (url.startsWith('data:image') || (!url.startsWith('http') && !url.startsWith('/') && !url.startsWith('file:') && url.length > 50)) {
      try {
        final rawBase64 = url.contains(',') ? url.substring(url.indexOf(',') + 1) : url;
        final cleanBase64 = rawBase64.replaceAll(RegExp(r'\s+'), '');
        final bytes = base64Decode(cleanBase64);
        content = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      } catch (_) {
        content = _buildPlaceholder();
      }
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      content = Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    } else if (!kIsWeb) {
      try {
        final cleanPath = url.startsWith('file://') ? url.replaceFirst('file://', '') : url;
        final file = File(cleanPath);
        if (file.existsSync()) {
          content = Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => _buildPlaceholder(),
          );
        } else {
          content = _buildPlaceholder();
        }
      } catch (_) {
        content = _buildPlaceholder();
      }
    } else {
      content = _buildPlaceholder();
    }

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }

    return content;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF1F5F9),
      child: Center(
        child: Icon(
          placeholderIcon,
          size: (height != null && height! < 60) ? 24 : 40,
          color: const Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
