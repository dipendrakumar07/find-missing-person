import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/missing_person.dart';
import '../../services/auth_service.dart';
import '../../services/missing_person_repository.dart';
import '../../utils/validators.dart';
import '../../widgets/app_photo_view.dart';

class AdminEditReportScreen extends StatefulWidget {
  final MissingPerson report;

  const AdminEditReportScreen({
    super.key,
    required this.report,
  });

  @override
  State<AdminEditReportScreen> createState() => _AdminEditReportScreenState();
}

class _AdminEditReportScreenState extends State<AdminEditReportScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _contactController;
  late TextEditingController _photoUrlController;
  late TextEditingController _rejectionReasonController;

  late String _gender;
  late String _reportStatus;
  late String _verificationStatus;
  late DateTime _missingDate;
  late bool _isUrgent;
  bool _isSaving = false;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _reportStatusOptions = ['Missing', 'Possible Match', 'Found'];
  final List<String> _verificationOptions = ['Pending', 'Approved', 'Verified', 'Rejected'];

  @override
  void initState() {
    super.initState();
    final r = widget.report;
    _nameController = TextEditingController(text: r.fullName);
    _ageController = TextEditingController(text: r.age.toString());
    _locationController = TextEditingController(text: r.lastSeenLocation);
    _descriptionController = TextEditingController(text: r.description);
    _contactController = TextEditingController(text: r.contactNumber);
    _photoUrlController = TextEditingController(text: r.photoUrl ?? '');
    _photoDataUri = (r.photoUrl != null && r.photoUrl!.isNotEmpty && !r.photoUrl!.contains('/cache/') && !r.photoUrl!.startsWith('/data/'))
        ? r.photoUrl
        : null;
    _rejectionReasonController = TextEditingController(text: r.rejectionReason ?? '');

    _gender = r.gender;
    _reportStatus = r.reportStatus;
    _verificationStatus = r.verificationStatus;
    _missingDate = r.missingDate;
    _isUrgent = r.isUrgent;
  }

  String? _photoDataUri;

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final base64String = base64Encode(bytes);
        setState(() {
          _photoDataUri = 'data:image/jpeg;base64,$base64String';
          _photoUrlController.text = _photoDataUri!;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
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
    _photoUrlController.dispose();
    _rejectionReasonController.dispose();
    super.dispose();
  }

  Future<void> _pickMissingDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _missingDate,
      firstDate: DateTime(1970),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _missingDate = picked;
      });
    }
  }

  String _formatDate(DateTime dt) {
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final currentAdmin = AuthService().currentUser?.email ?? 'admin';
      final updatedReport = widget.report.copyWith(
        fullName: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        gender: _gender,
        lastSeenLocation: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        contactNumber: _contactController.text.trim(),
        photoUrl: (_photoDataUri != null && _photoDataUri!.isNotEmpty)
            ? _photoDataUri
            : (_photoUrlController.text.trim().isNotEmpty
                ? _photoUrlController.text.trim()
                : null),
        missingDate: _missingDate,
        reportStatus: _reportStatus,
        verificationStatus: _verificationStatus,
        isUrgent: _isUrgent,
        rejectionReason: _verificationStatus.toLowerCase() == 'rejected'
            ? _rejectionReasonController.text.trim()
            : null,
        verifiedBy: _verificationStatus.toLowerCase() == 'verified'
            ? (widget.report.verifiedBy ?? currentAdmin)
            : widget.report.verifiedBy,
      );

      await MissingPersonRepository().updateReport(updatedReport);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report for "${updatedReport.fullName}" has been updated.'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update report: $e'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          AuthService().isCurrentAdmin ? 'Edit Report (Admin)' : 'Edit Report',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton.icon(
              onPressed: _isSaving ? null : _saveChanges,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: const Text('Save'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Verification & Status Controls Card (Admin Only)
                if (AuthService().isCurrentAdmin) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Administrative Status',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Verification Status Dropdown
                        const Text(
                          'Verification Status',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _verificationOptions.contains(_verificationStatus)
                              ? _verificationStatus
                              : 'Pending',
                          items: _verificationOptions.map((opt) {
                            return DropdownMenuItem(
                              value: opt,
                              child: Text(opt),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _verificationStatus = val;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Rejection Reason (if rejected)
                        if (_verificationStatus.toLowerCase() == 'rejected') ...[
                          const Text(
                            'Rejection Reason',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFDC2626)),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _rejectionReasonController,
                            decoration: InputDecoration(
                              hintText: 'Specify reason for rejection',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Case Progress Status Dropdown
                        const Text(
                          'Case Progress Status',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _reportStatusOptions.contains(_reportStatus)
                              ? _reportStatus
                              : 'Missing',
                          items: _reportStatusOptions.map((opt) {
                            return DropdownMenuItem(
                              value: opt,
                              child: Text(opt),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _reportStatus = val;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Urgent Alert Toggle
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Mark as Urgent Alert / Amber Alert',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          value: _isUrgent,
                          activeColor: const Color(0xFFDC2626),
                          onChanged: (val) {
                            setState(() {
                              _isUrgent = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Person Details Form Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Person Information',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Full Name
                      const Text('Full Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Age & Gender Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Age', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _ageController,
                                  keyboardType: TextInputType.number,
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Required';
                                    if (int.tryParse(val.trim()) == null) return 'Invalid';
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Gender', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: _genderOptions.contains(_gender) ? _gender : 'Male',
                                  items: _genderOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _gender = val);
                                  },
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Missing Date
                      const Text('Missing Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _pickMissingDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDate(_missingDate), style: const TextStyle(fontSize: 14)),
                              const Icon(Icons.calendar_today, size: 18, color: Color(0xFF64748B)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Last Seen Location
                      const Text('Last Seen Location', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _locationController,
                        validator: (val) => val == null || val.trim().isEmpty ? 'Location is required' : null,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Contact Number
                      const Text('Contact Phone Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _contactController,
                        validator: (val) => AppValidators.validatePhone(
                          val,
                          isRequired: true,
                          fieldName: 'Contact number',
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Person Photo Section with Live Preview & Camera/Gallery Pickers
                      const Text('Person Photo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            if (_photoDataUri != null && _photoDataUri!.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: AppPhotoView(
                                  photoUrl: _photoDataUri,
                                  width: double.infinity,
                                  height: 180,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ] else ...[
                              Container(
                                width: double.infinity,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_outlined, size: 36, color: Color(0xFF94A3B8)),
                                    SizedBox(height: 4),
                                    Text('No photo selected or attached', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _pickPhoto(ImageSource.gallery),
                                    icon: const Icon(Icons.photo_library_rounded, size: 16),
                                    label: const Text('Gallery', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF2563EB),
                                      side: const BorderSide(color: Color(0xFF93C5FD)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _pickPhoto(ImageSource.camera),
                                    icon: const Icon(Icons.camera_alt_rounded, size: 16),
                                    label: const Text('Camera', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF16A34A),
                                      side: const BorderSide(color: Color(0xFF86EFAC)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Description
                      const Text('Description & Identifying Marks', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        validator: (val) => val == null || val.trim().isEmpty ? 'Description is required' : null,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveChanges,
                    icon: const Icon(Icons.save_rounded, size: 20),
                    label: Text(
                      _isSaving ? 'Saving Changes...' : 'Save Report Changes',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
