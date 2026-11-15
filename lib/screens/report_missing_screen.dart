import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/missing_person.dart';
import '../services/auth_service.dart';
import '../services/missing_person_repository.dart';
import '../services/storage_service.dart';
import '../utils/validators.dart';
import 'login_screen.dart';

class ReportMissingScreen extends StatefulWidget {
  const ReportMissingScreen({super.key});

  @override
  State<ReportMissingScreen> createState() => _ReportMissingScreenState();
}

class _ReportMissingScreenState extends State<ReportMissingScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  String _selectedGender = 'Male';
  String _selectedStatus = 'Missing';
  DateTime? _selectedMissingDate;
  bool _isSubmitting = false;
  String _uploadProgressStatus = '';

  XFile? _selectedImageFile;
  final ImagePicker _imagePicker = ImagePicker();

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _statusOptions = ['Missing', 'Sighted', 'Found'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
    });
  }

  void _checkAuthentication() {
    if (!AuthService().isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to submit a missing person report.'),
          backgroundColor: Color(0xFF2563EB),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(
            onLoginSuccess: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportMissingScreen(),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (picked != null) {
        setState(() {
          _selectedImageFile = picked;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not pick image: $e'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedMissingDate ?? now,
      firstDate: DateTime(1970),
      lastDate: now,
      helpText: 'SELECT MISSING DATE',
    );

    if (pickedDate != null) {
      setState(() {
        _selectedMissingDate = pickedDate;
      });
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Future<void> _submitReport() async {
    // Guard against multiple simultaneous taps / double submission
    if (_isSubmitting) return;

    if (!AuthService().isLoggedIn) {
      _checkAuthentication();
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMissingDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select the missing date.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadProgressStatus = 'Preparing submission...';
    });

    try {
      String? finalPhotoUrl;

      // 1. Upload Photo to Firebase Storage if an image file was selected
      if (_selectedImageFile != null) {
        setState(() {
          _uploadProgressStatus = 'Uploading photo to Firebase Storage...';
        });

        if (kIsWeb) {
          final bytes = await _selectedImageFile!.readAsBytes();
          finalPhotoUrl = await StorageService().uploadPhoto(
            bytes: bytes,
            fileName: _selectedImageFile!.name,
          );
        } else {
          final file = File(_selectedImageFile!.path);
          finalPhotoUrl = await StorageService().uploadPhoto(
            file: file,
            fileName: _selectedImageFile!.name,
          );
        }
      }

      // 2. Save Missing Person details to Firebase Firestore
      setState(() {
        _uploadProgressStatus = 'Saving report to Firestore...';
      });

      final currentUserId = AuthService().userId;
      final isAdmin = AuthService().isCurrentAdmin;
      final report = MissingPerson(
        id: '',
        fullName: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        gender: _selectedGender,
        missingDate: _selectedMissingDate!,
        lastSeenLocation: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        contactNumber: _contactController.text.trim(),
        photoUrl: finalPhotoUrl,
        reportDate: DateTime.now(),
        reportStatus: _selectedStatus,
        verificationStatus: isAdmin ? 'Approved' : 'Pending',
        reportedBy: currentUserId,
      );

      await MissingPersonRepository().addReport(report);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Report for "${report.fullName}" has been submitted successfully.',
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submission failed: $e'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _uploadProgressStatus = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Report Missing Person',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.2,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Full Name
                _buildLabel('Full Name *'),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: _buildInputDecoration(
                    hintText: 'Enter full legal name',
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Full name is required';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 2. Age & Gender Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Age
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Age *'),
                          TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            decoration: _buildInputDecoration(
                              hintText: 'e.g. 24',
                              prefixIcon: Icons.calendar_today_outlined,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Age required';
                              }
                              final age = int.tryParse(value.trim());
                              if (age == null || age < 0 || age > 130) {
                                return 'Enter valid age';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Gender
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Gender *'),
                          DropdownButtonFormField<String>(
                            value: _selectedGender,
                            decoration: _buildInputDecoration(
                              hintText: 'Select gender',
                              prefixIcon: Icons.people_outline_rounded,
                            ),
                            items: _genderOptions.map((g) {
                              return DropdownMenuItem<String>(
                                value: g,
                                child: Text(g),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedGender = value;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Missing Date Picker
                _buildLabel('Missing Date *'),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedMissingDate == null
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF2563EB),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_rounded,
                          color: _selectedMissingDate == null
                              ? const Color(0xFF64748B)
                              : const Color(0xFF2563EB),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _selectedMissingDate == null
                              ? 'Select missing date'
                              : _formatDate(_selectedMissingDate!),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: _selectedMissingDate == null
                                ? FontWeight.normal
                                : FontWeight.w600,
                            color: _selectedMissingDate == null
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.calendar_month_outlined,
                          color: Color(0xFF64748B),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Last Seen Location
                _buildLabel('Last Seen Location *'),
                TextFormField(
                  controller: _locationController,
                  textInputAction: TextInputAction.next,
                  decoration: _buildInputDecoration(
                    hintText: 'e.g. City Park, Main Street, Delhi',
                    prefixIcon: Icons.location_on_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Last seen location is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 5. Contact Number
                _buildLabel('Contact Number *'),
                TextFormField(
                  controller: _contactController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: _buildInputDecoration(
                    hintText: 'e.g. +91 9876543210',
                    prefixIcon: Icons.phone_outlined,
                  ),
                  validator: (value) => AppValidators.validatePhone(
                    value,
                    isRequired: true,
                    fieldName: 'Contact number',
                  ),
                ),
                const SizedBox(height: 16),

                // 6. Description
                _buildLabel('Description *'),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  textInputAction: TextInputAction.newline,
                  decoration: _buildInputDecoration(
                    hintText:
                        'Provide physical appearance, clothing worn, height, weight, and any identifying marks...',
                    prefixIcon: Icons.notes_rounded,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Description is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 7. Report Status
                _buildLabel('Report Status'),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: _buildInputDecoration(
                    hintText: 'Select status',
                    prefixIcon: Icons.info_outline_rounded,
                  ),
                  items: _statusOptions.map((s) {
                    return DropdownMenuItem<String>(
                      value: s,
                      child: Text(s),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 8. Photo Section (Upload from Camera or Gallery)
                _buildLabel('Photo (Upload from Camera or Gallery)'),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined, size: 18),
                        label: const Text('Gallery'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: const Text('Camera'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Selected Local Image Preview
                if (_selectedImageFile != null) ...[
                  Stack(
                    children: [
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF2563EB)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: kIsWeb
                              ? Image.network(
                                  _selectedImageFile!.path,
                                  fit: BoxFit.contain,
                                )
                              : Image.file(
                                  File(_selectedImageFile!.path),
                                  fit: BoxFit.contain,
                                ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.black.withOpacity(0.6),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedImageFile = null;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],

                const SizedBox(height: 24),

                // Loading progress message if submitting
                if (_isSubmitting && _uploadProgressStatus.isNotEmpty) ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _uploadProgressStatus,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // 9. Action Buttons (Submit & Cancel)
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Submit Report Button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Submit Report',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 14,
      ),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF64748B), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
      ),
    );
  }
}
