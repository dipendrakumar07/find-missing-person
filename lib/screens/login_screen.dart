import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';
import '../widgets/otp_verification_dialog.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final bool initialIsSignUp;

  const LoginScreen({
    super.key,
    this.onLoginSuccess,
    this.initialIsSignUp = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

  // Login Controllers
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();

  // Sign Up Controllers
  final TextEditingController _signUpNameController = TextEditingController();
  final TextEditingController _signUpEmailController = TextEditingController();
  final TextEditingController _signUpPhoneController = TextEditingController();
  final TextEditingController _signUpPasswordController = TextEditingController();
  final TextEditingController _signUpConfirmPasswordController = TextEditingController();

  bool _isCreateAccountMode = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscureLoginPassword = true;
  bool _obscureSignUpPassword = true;
  bool _obscureSignUpConfirm = true;

  @override
  void initState() {
    super.initState();
    _isCreateAccountMode = widget.initialIsSignUp;
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signUpNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPhoneController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();
    super.dispose();
  }

  void _completeLogin() {
    if (widget.onLoginSuccess != null) {
      widget.onLoginSuccess!();
    }
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AuthService().signInWithEmailAndPassword(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Welcome back! Logged in successfully.'),
            ],
          ),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _completeLogin();
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  errorMsg,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      final credential = await AuthService().signInWithGoogle();
      if (!mounted) return;
      if (credential != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Signed in with Google successfully.'),
              ],
            ),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _completeLogin();
      }
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  errorMsg,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _handleSignUp() async {
    if (!_signUpFormKey.currentState!.validate()) return;

    final email = _signUpEmailController.text.trim();

    // Trigger 6-Digit OTP verification before creating account
    OtpVerificationDialog.show(
      context: context,
      destination: email,
      onVerified: () => _executeSignUp(),
    );
  }

  Future<void> _executeSignUp() async {
    setState(() => _isLoading = true);

    try {
      await AuthService().signUpWithEmailAndPassword(
        email: _signUpEmailController.text.trim(),
        password: _signUpPasswordController.text,
        displayName: _signUpNameController.text.trim(),
        phoneNumber: _signUpPhoneController.text.trim(),
        role: 'user',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.verified_user_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Account verified and created successfully! Welcome.'),
            ],
          ),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _completeLogin();
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  errorMsg,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController(text: _loginEmailController.text.trim());
    String? localError;
    bool isSearching = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.lock_reset_rounded, color: Color(0xFF1877F2)),
              SizedBox(width: 8),
              Text('Find Your Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your registered email address to search for your account and receive a password reset link.',
                style: TextStyle(fontSize: 13.5, color: Color(0xFF65676B)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                enabled: !isSearching,
                decoration: InputDecoration(
                  hintText: 'Email address or mobile number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                ),
                onChanged: (_) {
                  if (localError != null) {
                    setDialogState(() => localError = null);
                  }
                },
              ),
              if (localError != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          localError!,
                          style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12.5, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSearching ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF65676B))),
            ),
            ElevatedButton(
              onPressed: isSearching
                  ? null
                  : () async {
                      final input = emailCtrl.text.trim();
                      final validationError = AppValidators.validateEmailOrPhone(input);
                      if (validationError != null) {
                        setDialogState(() => localError = validationError);
                        return;
                      }

                      setDialogState(() {
                        isSearching = true;
                        localError = null;
                      });

                      final result = await AuthService().sendPasswordReset(emailOrPhone: input);

                      if (!mounted) return;

                      if (!result['success']) {
                        setDialogState(() {
                          isSearching = false;
                          localError = result['message'];
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['message'] ?? 'Account not found.'),
                            backgroundColor: const Color(0xFFDC2626),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                        return;
                      }

                      // Successfully found account & dispatched reset link
                      Navigator.pop(ctx);

                      showDialog(
                        context: context,
                        builder: (sCtx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Row(
                            children: [
                              Icon(Icons.mark_email_read_rounded, color: Color(0xFF16A34A)),
                              SizedBox(width: 8),
                              Text('Reset Link Sent!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'A password reset link has been sent to your email (${result['email']}).',
                                style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                '1. Open your Gmail / Email inbox.\n2. Click the password reset link to set your new password.\n3. Return to the app and sign in with your new password.',
                                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                              ),
                            ],
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () => Navigator.pop(sCtx),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1877F2),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('OK, Got it'),
                            ),
                          ],
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1877F2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: isSearching
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Search & Send Link'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5), // Facebook neutral background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Facebook Style App Header
                  _buildFacebookBrandHeader(),
                  const SizedBox(height: 20),

                  // 2. Primary Card (Login or Create Account)
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 250),
                    crossFadeState: _isCreateAccountMode
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: _buildFacebookLoginCard(),
                    secondChild: _buildFacebookCreateAccountCard(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFacebookBrandHeader() {
    return Column(
      children: [
        // App icon with Facebook blue accent
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFF1877F2),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1877F2).withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.travel_explore_rounded,
            color: Colors.white,
            size: 34,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'FindMissingPerson',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1877F2),
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Connect with community to locate missing loved ones.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF65676B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFacebookLoginCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCCD0D5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: _loginFormKey,
        child: Column(
          children: [
            // Email or Phone input
            TextFormField(
              controller: _loginEmailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: _buildFacebookInputDecoration(
                hintText: 'Mobile number or email address',
                prefixIcon: Icons.person_outline_rounded,
              ),
              validator: AppValidators.validateEmailOrPhone,
            ),
            const SizedBox(height: 12),

            // Password input
            TextFormField(
              controller: _loginPasswordController,
              obscureText: _obscureLoginPassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleLogin(),
              decoration: _buildFacebookInputDecoration(
                hintText: 'Password',
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureLoginPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF65676B),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Facebook Blue Log In Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (_isLoading || _isGoogleLoading) ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1877F2),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                      )
                    : const Text('Log In'),
              ),
            ),
            const SizedBox(height: 14),

            // Forgotten password link
            GestureDetector(
              onTap: _showForgotPasswordDialog,
              child: const Text(
                'Forgotten password?',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1877F2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Divider with OR
            Row(
              children: [
                const Expanded(child: Divider(color: Color(0xFFDADDE1), thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'or',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF8D949E),
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: Color(0xFFDADDE1), thickness: 1)),
              ],
            ),
            const SizedBox(height: 16),

            // Continue with Google Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: (_isLoading || _isGoogleLoading) ? null : _handleGoogleSignIn,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF3C4043),
                  side: const BorderSide(color: Color(0xFFDADCE0), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isGoogleLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFF1877F2)),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const GoogleLogoWidget(size: 20),
                          const SizedBox(width: 12),
                          const Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3C4043),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Classic Facebook Green "Create new account" Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _isCreateAccountMode = true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF42B72A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                child: const Text('Create new account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacebookCreateAccountCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCCD0D5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: _signUpFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section Header
            const Row(
              children: [
                Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF42B72A), size: 22),
                SizedBox(width: 8),
                Text(
                  'Create a new account',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1E21),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              "It's quick and easy.",
              style: TextStyle(fontSize: 13, color: Color(0xFF65676B)),
            ),
            const SizedBox(height: 16),

            // Full Name input
            TextFormField(
              controller: _signUpNameController,
              textInputAction: TextInputAction.next,
              decoration: _buildFacebookInputDecoration(
                hintText: 'Full name',
                prefixIcon: Icons.badge_outlined,
              ),
              validator: AppValidators.validateName,
            ),
            const SizedBox(height: 12),

            // Email input
            TextFormField(
              controller: _signUpEmailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: _buildFacebookInputDecoration(
                hintText: 'Email address (e.g. name@example.com)',
                prefixIcon: Icons.mail_outline_rounded,
              ),
              validator: AppValidators.validateEmail,
            ),
            const SizedBox(height: 12),

            // Mobile number input
            TextFormField(
              controller: _signUpPhoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: _buildFacebookInputDecoration(
                hintText: 'Mobile number (e.g. +91 9876543210)',
                prefixIcon: Icons.phone_outlined,
              ),
              validator: (v) => AppValidators.validatePhone(v, isRequired: true, fieldName: 'Mobile number'),
            ),
            const SizedBox(height: 12),

            // Password input
            TextFormField(
              controller: _signUpPasswordController,
              obscureText: _obscureSignUpPassword,
              textInputAction: TextInputAction.next,
              decoration: _buildFacebookInputDecoration(
                hintText: 'Strong password (e.g. Strong@123)',
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureSignUpPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF65676B),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureSignUpPassword = !_obscureSignUpPassword),
                ),
              ),
              validator: AppValidators.validateStrongPassword,
            ),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Must have 8+ chars with uppercase, lowercase, number & symbol.',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF65676B),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Confirm Password input
            TextFormField(
              controller: _signUpConfirmPasswordController,
              obscureText: _obscureSignUpConfirm,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleSignUp(),
              decoration: _buildFacebookInputDecoration(
                hintText: 'Confirm password',
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureSignUpConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF65676B),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureSignUpConfirm = !_obscureSignUpConfirm),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Please confirm password';
                if (val != _signUpPasswordController.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 18),

            // Green Sign Up Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (_isLoading || _isGoogleLoading) ? null : _handleSignUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF42B72A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                      )
                    : const Text('Sign Up'),
              ),
            ),
            const SizedBox(height: 14),

            // Continue with Google option on Sign Up
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                onPressed: (_isLoading || _isGoogleLoading) ? null : _handleGoogleSignIn,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF3C4043),
                  side: const BorderSide(color: Color(0xFFDADCE0), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const GoogleLogoWidget(size: 18),
                    const SizedBox(width: 10),
                    const Text(
                      'Sign up with Google',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3C4043),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Already have an account link
            Center(
              child: GestureDetector(
                onTap: () {
                  setState(() => _isCreateAccountMode = false);
                },
                child: const Text(
                  'Already have an account? Log In',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1877F2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildFacebookInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF8D949E), fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF65676B), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCCD0D5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCCD0D5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1877F2), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFA3E3E), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFA3E3E), width: 1.8),
      ),
    );
  }
}

/// Native Canvas Google 'G' 4-color Logo Widget (Zero external assets needed)
class GoogleLogoWidget extends StatelessWidget {
  final double size;
  const GoogleLogoWidget({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;
    final strokeWidth = radius * 0.38;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final paintYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Red: top arc
    canvas.drawArc(rect, 3.65, 1.7, false, paintRed);
    // Yellow: left arc
    canvas.drawArc(rect, 2.35, 1.35, false, paintYellow);
    // Green: bottom arc
    canvas.drawArc(rect, 0.75, 1.65, false, paintGreen);
    // Blue: right arc
    canvas.drawArc(rect, -0.1, 0.85, false, paintBlue);

    // Crossbar for G
    final crossPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.46, h * 0.38, w * 0.98, h * 0.62),
        const Radius.circular(1.5),
      ),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
