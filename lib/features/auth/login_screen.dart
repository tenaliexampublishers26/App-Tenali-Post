import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Official Academy Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryNavy.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      AppConstants.logoAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.school_rounded,
                        size: 60,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  AppConstants.appSubtext,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 36),

                // Card with sign-in actions
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Candidate Sign In',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sign in to access your practice tests, video lessons, and scheduled live examinations.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        if (authProvider.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.errorRedBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              authProvider.errorMessage!,
                              style: const TextStyle(color: AppTheme.errorRed, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Google Sign-In Button
                        ElevatedButton.icon(
                          icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                          label: authProvider.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Continue with Google'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryNavy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: authProvider.isLoading
                              ? null
                              : () async {
                                  final success = await authProvider.signInWithGoogle();
                                  if (success && mounted) {
                                    Navigator.pushReplacementNamed(context, '/home');
                                  }
                                },
                        ),

                        const SizedBox(height: 16),

                        // Fast Demo Candidate Login (for testing without external OAuth credentials)
                        OutlinedButton.icon(
                          icon: const Icon(Icons.person_rounded, size: 18),
                          label: const Text('Enter as Demo Candidate'),
                          onPressed: authProvider.isLoading
                              ? null
                              : () async {
                                  final success = await authProvider.signInWithGoogle();
                                  if (success && mounted) {
                                    Navigator.pushReplacementNamed(context, '/home');
                                  }
                                },
                        ),

                        const SizedBox(height: 10),

                        // Demo Admin Access
                        TextButton.icon(
                          icon: const Icon(Icons.admin_panel_settings_rounded, size: 16, color: AppTheme.secondaryMaroon),
                          label: const Text(
                            'Sign In as Administrator',
                            style: TextStyle(
                              color: AppTheme.secondaryMaroon,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: authProvider.isLoading
                              ? null
                              : () async {
                                  final success = await authProvider.signInAsAdminDemo();
                                  if (success && mounted) {
                                    Navigator.pushReplacementNamed(context, '/home');
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'India Post Departmental Preparation Portal\nStrictly local & isolated from production e-commerce database.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
