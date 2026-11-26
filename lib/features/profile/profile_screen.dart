import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mcq_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;

  bool _isEditing = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    _nameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _locationController = TextEditingController(
      text: user?.location ?? user?.postalCircle ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  bool _isValidPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final phoneRegex = RegExp(r'^(\+91|91|0)?[6-9]\d{9}$');
    return phoneRegex.hasMatch(clean) || (clean.length == 10 && RegExp(r'^\d{10}$').hasMatch(clean));
  }

  Future<void> _handleSave() async {
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.updateProfile(
      fullName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      location: _locationController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (success) {
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _errorMessage = auth.errorMessage ?? 'Failed to update profile in database.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final mcqProvider = Provider.of<McqProvider>(context);
    final user = authProvider.user;
    final bool isAdmin = authProvider.isAdmin;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.canPop(context),
        title: const Text('User Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              tooltip: 'Edit Profile',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            IconButton(
              tooltip: 'Cancel Editing',
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _nameController.text = user?.fullName ?? '';
                  _phoneController.text = user?.phoneNumber ?? '';
                  _locationController.text = user?.location ?? user?.postalCircle ?? '';
                  _errorMessage = null;
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.accentGold, width: 2),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          AppConstants.logoAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person_rounded,
                            size: 40,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.fullName.isNotEmpty == true ? user!.fullName : 'Postal Candidate',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'candidate@india.gov.in',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: isAdmin ? AppTheme.secondaryMaroon : AppTheme.primaryNavy,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isAdmin ? 'ADMINISTRATOR' : 'STUDENT ASPIRANT',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Error display
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorRedBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppTheme.errorRed, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Profile Details & Edit Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (_isEditing)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.accentGold.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'EDITING',
                                style: TextStyle(
                                  color: AppTheme.primaryNavy,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Full Name
                      const Text('Full Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _nameController,
                        enabled: _isEditing,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline, size: 20),
                          filled: !_isEditing,
                          fillColor: !_isEditing ? Colors.grey.shade50 : Colors.white,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Full Name is required';
                          if (val.trim().length < 2) return 'Enter at least 2 characters';
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      // Email Address (Always Read-Only)
                      const Row(
                        children: [
                          Text('Email Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                          SizedBox(width: 6),
                          Icon(Icons.lock_rounded, size: 12, color: AppTheme.textMuted),
                          SizedBox(width: 4),
                          Text('(Locked to authenticated account)', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _emailController,
                        enabled: false,
                        readOnly: true,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email_outlined, size: 20),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Phone Number
                      const Text('Phone Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _phoneController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                          filled: !_isEditing,
                          fillColor: !_isEditing ? Colors.grey.shade50 : Colors.white,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Phone Number is required';
                          if (!_isValidPhone(val.trim())) return 'Enter valid 10-digit phone number';
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      // Location
                      const Text('Location / Postal Circle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _locationController,
                        enabled: _isEditing,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                          filled: !_isEditing,
                          fillColor: !_isEditing ? Colors.grey.shade50 : Colors.white,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Location is required';
                          if (val.trim().length < 2) return 'Enter at least 2 characters';
                          return null;
                        },
                      ),

                      if (_isEditing) ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.save_rounded, size: 18),
                            label: Text(_isSaving ? 'Saving Changes...' : 'Save Profile Changes'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryNavy,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            onPressed: _isSaving ? null : _handleSave,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Performance Statistics
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Learning & Practice Overview',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _metricCol(
                          'MCQs Solved',
                          '${mcqProvider.correctAnswersCount + mcqProvider.wrongAnswersCount}',
                          AppTheme.primaryNavy,
                        ),
                        _metricCol(
                          'Accuracy',
                          '${mcqProvider.correctAnswersCount > 0 ? ((mcqProvider.correctAnswersCount / (mcqProvider.correctAnswersCount + mcqProvider.wrongAnswersCount)) * 100).toInt() : 0}%',
                          AppTheme.successGreen,
                        ),
                        _metricCol('Live Tests', '1', AppTheme.secondaryMaroon),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (isAdmin) ...[
              const SizedBox(height: 16),
              Card(
                color: AppTheme.primaryNavy,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.accentGold, size: 30),
                  title: const Text(
                    'Admin Management Console',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Manage MCQs, Live Tests, Students, Videos, Notes & Announcements',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.accentGold, size: 16),
                  onTap: () => Navigator.pushNamed(context, '/admin'),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Sign Out Button
            ElevatedButton.icon(
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryMaroon,
                minimumSize: const Size(double.infinity, 46),
              ),
              onPressed: () async {
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCol(String title, String val, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
      ],
    );
  }
}
