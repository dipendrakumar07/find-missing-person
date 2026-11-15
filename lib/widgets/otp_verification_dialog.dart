import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/email_service.dart';

class OtpVerificationDialog extends StatefulWidget {
  final String destination;
  final VoidCallback onVerified;

  const OtpVerificationDialog({
    super.key,
    required this.destination,
    required this.onVerified,
  });

  static Future<void> show({
    required BuildContext context,
    required String destination,
    required VoidCallback onVerified,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => OtpVerificationDialog(
        destination: destination,
        onVerified: onVerified,
      ),
    );
  }

  @override
  State<OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<OtpVerificationDialog> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  late String _generatedOtp;
  Timer? _countdownTimer;
  int _secondsRemaining = 60;
  bool _canResend = false;
  String? _errorMessage;
  bool _isVerifying = false;
  bool _isSendingEmail = true;

  @override
  void initState() {
    super.initState();
    _generatedOtp = EmailService.generate6DigitOtp();
    _sendEmailOtp();
    _startTimer();
  }

  Future<void> _sendEmailOtp() async {
    setState(() => _isSendingEmail = true);
    try {
      // Extract clean email from destination string
      final cleanEmail = widget.destination.contains('&')
          ? widget.destination.split('&').first.trim()
          : widget.destination.trim();

      await EmailService().sendOtpEmail(
        recipientEmail: cleanEmail,
        otpCode: _generatedOtp,
      );
    } catch (_) {}
    if (mounted) {
      setState(() => _isSendingEmail = false);
    }
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
        }
      } else {
        _countdownTimer?.cancel();
        if (mounted) {
          setState(() {
            _canResend = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _enteredOtp => _controllers.map((c) => c.text.trim()).join();

  void _onDigitChanged(int index, String value) {
    setState(() {
      _errorMessage = null;
    });

    if (value.isNotEmpty) {
      if (value.length > 1) {
        _controllers[index].text = value.substring(value.length - 1);
      }
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_enteredOtp.length == 6) {
          _verifyOtp();
        }
      }
    }
  }

  void _onKeyDown(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _resendOtp() {
    if (!_canResend) return;

    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();

    setState(() {
      _generatedOtp = EmailService.generate6DigitOtp();
      _errorMessage = null;
    });
    _sendEmailOtp();
    _startTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'New 6-digit OTP code sent to ${widget.destination}',
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _verifyOtp() {
    final entered = _enteredOtp;

    if (entered.length < 6) {
      setState(() {
        _errorMessage = 'Please enter all 6 digits of the OTP code.';
      });
      return;
    }

    // STRICT CHECK: Reject if OTP doesn't match!
    if (entered != _generatedOtp) {
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
      setState(() {
        _errorMessage = 'Incorrect OTP code! Please check your Gmail and enter the exact code.';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      Navigator.pop(context);
      widget.onVerified();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  color: Color(0xFF2563EB),
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                'Check Your Gmail',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle with destination
              Text(
                'We have sent a 6-digit verification code to:\n${widget.destination}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),

              // Status Box (Sending or Sent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _isSendingEmail ? const Color(0xFFFFFBEB) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isSendingEmail ? const Color(0xFFFDE68A) : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Row(
                  children: [
                    if (_isSendingEmail)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD97706)),
                      )
                    else
                      const Icon(Icons.check_circle_outline_rounded, size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isSendingEmail
                            ? 'Sending code to your Gmail inbox...'
                            : 'Code sent! Check your inbox & spam folder.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isSendingEmail ? const Color(0xFFB45309) : const Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 6 OTP Input Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  final hasError = _errorMessage != null;
                  return SizedBox(
                    width: 44,
                    height: 52,
                    child: RawKeyboardListener(
                      focusNode: FocusNode(),
                      onKey: (event) => _onKeyDown(index, event),
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: hasError ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                        ),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: hasError
                              ? const Color(0xFFFEF2F2)
                              : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: hasError ? const Color(0xFFDC2626) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: hasError ? const Color(0xFFDC2626) : const Color(0xFFCBD5E1),
                              width: hasError ? 1.5 : 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: hasError ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (val) => _onDigitChanged(index, val),
                      ),
                    ),
                  );
                }),
              ),

              // Error Message
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),

              // Countdown Timer & Resend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_canResend) ...[
                    const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      'Resend code in ${_secondsRemaining}s',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else ...[
                    TextButton.icon(
                      onPressed: _resendOtp,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text(
                        'Resend Code to Gmail',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      child: const Text(
                        'Change Email',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isVerifying ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isVerifying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Verify & Proceed',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
