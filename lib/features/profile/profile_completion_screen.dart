import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;

  bool _isSaving = false;
  String? _saveErrorMessage;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _locationController = TextEditingController(
      text: user?.location ?? user?.postalCircle ?? '',
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  bool _isValidPhone(String phone) {
    // Standard phone validation: supports 10-digit Indian mobile or +91 format
    final clean = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final phoneRegex = RegExp(r'^(\+91|91|0)?[6-9]\d{9}$');
    return phoneRegex.hasMatch(clean) || (clean.length == 10 && RegExp(r'^\d{10}$').hasMatch(clean));
  }

  Future<void> _handleSave() async {
    setState(() {
      _saveErrorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final success = await auth.updateProfile(
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        location: _locationController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile completed successfully! Welcome to Tenali Post.'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _saveErrorMessage = auth.errorMessage ?? 'Could not save profile to Supabase. Please retry.';
        });
      }
    } catch (e) {
      setState(() {
        _saveErrorMessage = 'Error saving profile: $e. Your information was kept. Please retry.';
      });
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
    // PopScope prevents skipping profile completion via back button
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.bgWarm,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Complete Profile'),
          backgroundColor: AppTheme.surfaceWarmWhite,
          actions: [
            IconButton(
              tooltip: 'Sign Out',
              icon: const Icon(Icons.logout_rounded, color: AppTheme.errorRed),
              onPressed: () async {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                await auth.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Information Header Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryNavy.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.primaryNavy.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryNavy,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.assignment_ind_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mandatory Candidate Profile',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primaryNavy,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'All 4 fields below are required to access examination modules, live mock rankings, and departmental notes.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Error Message
                    if (_saveErrorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRedBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppTheme.errorRed, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _saveErrorMessage!,
                                style: const TextStyle(color: AppTheme.errorRed, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Card with 4 Mandatory Fields
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Full Name
                            const Text(
                              '1. Full Name *',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _fullNameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                hintText: 'Enter your full name',
                                prefixIcon: Icon(Icons.person_rounded, size: 20),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Full Name is mandatory';
                                }
                                if (val.trim().length < 2) {
                                  return 'Enter at least 2 characters';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 18),

                            // 2. Email Address (Read-only, locked to authenticated identity)
                            const Row(
                              children: [
                                Text(
                                  '2. Email Address *',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.lock_rounded, size: 14, color: AppTheme.textMuted),
                                SizedBox(width: 4),
                                Text(
                                  '(Read-only, linked to account)',
                                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailController,
                              readOnly: true,
                              enabled: false,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.email_rounded, size: 20),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Email Address is mandatory';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 18),

                            // 3. Phone Number
                            const Text(
                              '3. Phone Number *',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                hintText: '10-digit mobile number (e.g. 9876543210)',
                                prefixIcon: Icon(Icons.phone_rounded, size: 20),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Phone Number is mandatory';
                                }
                                if (!_isValidPhone(val.trim())) {
                                  return 'Please enter a valid 10-digit phone number';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 18),

                            // 4. Location
                            const Text(
                              '4. Location / Postal Circle *',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _locationController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                hintText: 'City, District, or Postal Circle (e.g. Tenali, Guntur)',
                                prefixIcon: Icon(Icons.location_on_rounded, size: 20),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Location is mandatory';
                                }
                                if (val.trim().length < 2) {
                                  return 'Location must be at least 2 characters';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Save Profile Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isSaving ? null : _handleSave,
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save & Continue to App',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                    ),

                    const SizedBox(height: 14),
                    const Text(
                      'Information is securely saved in your Tenali Post database.\nYou can update your name, phone, and location anytime from your Profile.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
