import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:mailer/smtp_server/gmail.dart';
import '../config/secrets.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  /// Sender Gmail configuration (loaded from AppSecrets)
  static String senderEmail = AppSecrets.gmailSenderEmail;
  static String senderAppPassword = AppSecrets.gmailAppPassword;

  /// Optional Google Apps Script Webhook URL (100% free serverless email relay)
  static String appsScriptWebhookUrl = AppSecrets.appsScriptWebhookUrl;

  /// Generate a cryptographically secure 6-digit numeric OTP
  static String generate6DigitOtp() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Send the 6-digit OTP to the user's Gmail address
  Future<bool> sendOtpEmail({
    required String recipientEmail,
    required String otpCode,
  }) async {
    debugPrint('Sending 6-digit OTP to: $recipientEmail');

    bool sent = false;

    // 1. Method A: If Google Apps Script Webhook URL is configured
    if (appsScriptWebhookUrl.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse(appsScriptWebhookUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': recipientEmail.trim(),
            'subject': 'FindMissingPerson - Your Verification Code is $otpCode',
            'message': 'Your 6-digit verification code is: $otpCode\n\nThis code is valid for 10 minutes. Please enter it in the app to complete your registration.',
            'otp': otpCode,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200 || response.statusCode == 302) {
          debugPrint('Email sent successfully via Apps Script Webhook.');
          sent = true;
        }
      } catch (e) {
        debugPrint('Webhook email notice: $e');
      }
    }

    // 2. Method B: If Gmail SMTP App Password is provided
    if (!sent && senderAppPassword.isNotEmpty && senderEmail.isNotEmpty) {
      try {
        final cleanPassword = senderAppPassword.replaceAll(' ', '').trim();
        final smtpServer = SmtpServer(
          'smtp.gmail.com',
          port: 465,
          ssl: true,
          username: senderEmail.trim(),
          password: cleanPassword,
        );
        final message = Message()
          ..from = Address(senderEmail, 'FindMissingPerson Official')
          ..recipients.add(recipientEmail.trim())
          ..subject = 'FindMissingPerson - Verification Code: $otpCode'
          ..html = '''
            <div style="font-family: Arial, sans-serif; max-width: 520px; padding: 24px; border: 1px solid #E2E8F0; border-radius: 14px; background: #FFFFFF;">
              <h2 style="color: #2563EB; margin-top: 0;">FindMissingPerson Community</h2>
              <p style="color: #334155; font-size: 15px;">Hello,</p>
              <p style="color: #334155; font-size: 15px;">Use the following 6-digit verification code to complete your registration:</p>
              <div style="background: #EFF6FF; border: 2px dashed #93C5FD; padding: 16px; font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #1D4ED8; text-align: center; border-radius: 10px; margin: 24px 0;">
                $otpCode
              </div>
              <p style="color: #64748B; font-size: 13px;">This verification code is valid for 10 minutes. If you did not request this, please ignore this email.</p>
              <hr style="border: none; border-top: 1px solid #E2E8F0; margin: 20px 0;" />
              <p style="color: #94A3B8; font-size: 12px; margin: 0;">FindMissingPerson Community Safety Network</p>
            </div>
          ''';

        await send(message, smtpServer).timeout(const Duration(seconds: 12));
        debugPrint('Email sent successfully via Gmail SMTP.');
        sent = true;
      } catch (e) {
        debugPrint('Gmail SMTP notice: $e');
      }
    }

    // 3. Method C: Save OTP to Firestore 'otps' collection for real-time verification & cloud sync
    try {
      await FirebaseFirestore.instance
          .collection('otps')
          .doc(recipientEmail.trim().toLowerCase())
          .set({
        'otp': otpCode,
        'email': recipientEmail.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
      });
      debugPrint('OTP saved to Firestore otps collection.');
    } catch (e) {
      debugPrint('Firestore OTP save notice: $e');
    }

    // 4. Method D: Log to Firestore 'mail' collection (Triggers Firebase Email Extension if installed)
    try {
      await FirebaseFirestore.instance.collection('mail').add({
        'to': [recipientEmail.trim()],
        'message': {
          'subject': 'FindMissingPerson - Verification Code: $otpCode',
          'text': 'Your 6-digit verification code is: $otpCode',
          'html': '<h2>Your 6-digit verification code is: <b>$otpCode</b></h2>',
        },
        'otp': otpCode,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 4));
      debugPrint('Email logged to Firestore mail queue.');
    } catch (_) {}

    return sent;
  }

  /// Send password reset notification email via Gmail SMTP
  Future<bool> sendPasswordResetNotification({
    required String recipientEmail,
    String? displayName,
  }) async {
    final cleanEmail = recipientEmail.trim();
    if (senderAppPassword.isEmpty || senderEmail.isEmpty) return false;
    try {
      final cleanPassword = senderAppPassword.replaceAll(' ', '').trim();
      final smtpServer = SmtpServer(
        'smtp.gmail.com',
        port: 465,
        ssl: true,
        username: senderEmail.trim(),
        password: cleanPassword,
      );
      final message = Message()
        ..from = Address(senderEmail, 'FindMissingPerson Official')
        ..recipients.add(cleanEmail)
        ..subject = 'FindMissingPerson - Password Reset Instructions'
        ..html = '''
          <div style="font-family: Arial, sans-serif; max-width: 520px; padding: 24px; border: 1px solid #E2E8F0; border-radius: 14px; background: #FFFFFF;">
            <h2 style="color: #2563EB; margin-top: 0;">FindMissingPerson Community</h2>
            <p style="color: #334155; font-size: 15px;">Hello ${displayName ?? 'User'},</p>
            <p style="color: #334155; font-size: 15px;">A password reset request was submitted for your account (<strong>$cleanEmail</strong>).</p>
            <p style="color: #334155; font-size: 14px;">An official password reset link from Firebase has been dispatched to your email address. Please click the link to choose your new password, then return to the app to log in.</p>
            <p style="color: #64748B; font-size: 13px;">If you did not request a password reset, you can safely ignore this email — your account remains completely secure.</p>
            <hr style="border: none; border-top: 1px solid #E2E8F0; margin: 20px 0;" />
            <p style="color: #94A3B8; font-size: 12px; margin: 0;">FindMissingPerson Community Safety Network</p>
          </div>
        ''';

      await send(message, smtpServer).timeout(const Duration(seconds: 10));
      debugPrint('Password reset notification sent successfully via Gmail SMTP.');
      return true;
    } catch (e) {
      debugPrint('Password reset notification notice: $e');
      return false;
    }
  }
}

