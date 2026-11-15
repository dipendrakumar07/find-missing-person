import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_photo_view.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _cityController;

  String? _currentPhotoUrl;
  String? _newPhotoDataUri;
  File? _newPhotoFile;
  bool _isLoading = true;
  bool _isSaving = false;

  // Privacy Settings
  bool _hideEmail = true;
  bool _showPhone = true;
  bool _showCity = true;

  final ImagePicker _picker = ImagePicker();

  // Premium Violet & Indigo Theme Colors
  static const Color primaryColor = Color(0xFF7C3AED); // Royal Violet
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color accentColor = Color(0xFF6366F1); // Indigo

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _bioController = TextEditingController();
    _cityController = TextEditingController();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final profile = await AuthService().getUserProfile();
    if (mounted) {
      setState(() {
        _nameController.text = profile['displayName'] ?? '';
        _phoneController.text = profile['phoneNumber'] ?? '';
        _bioController.text = profile['bio'] ?? '';
        _cityController.text = profile['city'] ?? '';
        _currentPhotoUrl = profile['photoURL'];
        _hideEmail = profile['hideEmail'] ?? true;
        _showPhone = profile['showPhone'] ?? true;
        _showCity = profile['showCity'] ?? true;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePicture(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 75,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final base64String = base64Encode(bytes);
        final dataUri = 'data:image/jpeg;base64,$base64String';

        setState(() {
          _newPhotoFile = File(picked.path);
          _newPhotoDataUri = dataUri;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select image: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Change Profile Picture',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: primaryColor),
                ),
                title: const Text('Take photo with Camera', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickProfilePicture(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: primaryColor),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickProfilePicture(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? uploadedPhotoUrl = _currentPhotoUrl;

      // If user selected a new photo, upload or convert to permanent cloud data URI
      if (_newPhotoDataUri != null) {
        if (_newPhotoFile != null && !kIsWeb) {
          uploadedPhotoUrl = await StorageService().uploadPhoto(
            file: _newPhotoFile,
            fileName: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
            folder: 'user_profiles',
          );
        } else {
          uploadedPhotoUrl = _newPhotoDataUri;
        }
      }

      await AuthService().updateUserProfile(
        displayName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        photoURL: uploadedPhotoUrl,
        bio: _bioController.text.trim(),
        city: _cityController.text.trim(),
        hideEmail: _hideEmail,
        showPhone: _showPhone,
        showCity: _showCity,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Profile updated successfully!'),
            ],
          ),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Profile Photo Card
                    _buildProfilePictureSection(),
                    const SizedBox(height: 16),

                    // 2. Personal Details Card
                    _buildDetailsSection(),
                    const SizedBox(height: 16),

                    // 3. Privacy Settings Card (Facebook-style Privacy)
                    _buildPrivacySection(),
                    const SizedBox(height: 24),

                    // 4. Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                              )
                            : const Text('Save Changes'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfilePictureSection() {
    final photoToShow = _newPhotoDataUri ?? _currentPhotoUrl;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profile Picture',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              TextButton(
                onPressed: _showImagePickerModal,
                child: const Text('Change', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showImagePickerModal,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryColor, width: 3),
                  ),
                  child: ClipOval(
                    child: photoToShow != null && photoToShow.isNotEmpty
                        ? AppPhotoView(
                            photoUrl: photoToShow,
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: const Color(0xFFF3E8FF),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 64,
                              color: Color(0xFF9333EA),
                            ),
                          ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap avatar to take photo or choose from gallery',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Public Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Visible to other community members helping in search operations',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),

          // Full Name
          _buildInputLabel('Full Name'),
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: _buildInputDecoration(
              hint: 'Enter your full name',
              prefixIcon: Icons.badge_outlined,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter your name';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Bio / Description
          _buildInputLabel('Bio (About You)'),
          TextFormField(
            controller: _bioController,
            maxLines: 2,
            textInputAction: TextInputAction.next,
            decoration: _buildInputDecoration(
              hint: 'Tell the community how you assist in search operations...',
              prefixIcon: Icons.edit_note_rounded,
            ),
          ),
          const SizedBox(height: 14),

          // Phone Number
          _buildInputLabel('Phone Number'),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: _buildInputDecoration(
              hint: 'e.g. +91 98765 43210',
              prefixIcon: Icons.phone_outlined,
            ),
          ),
          const SizedBox(height: 14),

          // City / Address
          _buildInputLabel('City / Location'),
          TextFormField(
            controller: _cityController,
            textInputAction: TextInputAction.done,
            decoration: _buildInputDecoration(
              hint: 'e.g. Mumbai, Maharashtra',
              prefixIcon: Icons.location_on_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, color: primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                'Privacy Settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Control what other community members can see on your profile',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),

          // 1. Hide Email Toggle (Facebook Style Privacy)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: primaryColor,
            value: _hideEmail,
            onChanged: (val) => setState(() => _hideEmail = val),
            title: const Text(
              'Keep Email Private (Hidden)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
            subtitle: const Text(
              'Your email is never shown to other users. Only you see it.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),

          // 2. Show Phone Toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: primaryColor,
            value: _showPhone,
            onChanged: (val) => setState(() => _showPhone = val),
            title: const Text(
              'Show Phone Number',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
            subtitle: const Text(
              'Allow other volunteers to see your phone number for coordination.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),

          // 3. Show City Toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: primaryColor,
            value: _showCity,
            onChanged: (val) => setState(() => _showCity = val),
            title: const Text(
              'Show City / Location',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
            subtitle: const Text(
              'Display your city to connect with local area search operations.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF334155),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF64748B), size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primaryColor, width: 1.8),
      ),
    );
  }
}
