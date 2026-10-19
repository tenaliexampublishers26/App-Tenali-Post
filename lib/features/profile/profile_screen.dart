import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mcq_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final mcqProvider = Provider.of<McqProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Candidate Profile'),
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
                      user?.fullName ?? 'Postal Candidate',
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
                        color: user?.isAdmin == true ? AppTheme.secondaryMaroon : AppTheme.primaryNavy,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user?.isAdmin == true ? 'ADMINISTRATOR' : 'STUDENT ASPIRANT',
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
                        _metricCol('MCQs Solved', '${mcqProvider.correctAnswersCount + mcqProvider.wrongAnswersCount}', AppTheme.primaryNavy),
                        _metricCol('Accuracy', '${mcqProvider.correctAnswersCount > 0 ? ((mcqProvider.correctAnswersCount / (mcqProvider.correctAnswersCount + mcqProvider.wrongAnswersCount)) * 100).toInt() : 0}%', AppTheme.successGreen),
                        _metricCol('Live Tests', '1', AppTheme.secondaryMaroon),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Profile Details & Circle
            Card(
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.badge_outlined, color: AppTheme.primaryNavy),
                    title: Text('Target Cadre', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    trailing: Text('MTS & Postman', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  const Divider(height: 1, color: AppTheme.borderSubtle),
                  ListTile(
                    leading: const Icon(Icons.location_on_outlined, color: AppTheme.primaryNavy),
                    title: const Text('Postal Circle', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    trailing: Text(user?.postalCircle ?? 'Andhra Pradesh', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  const Divider(height: 1, color: AppTheme.borderSubtle),
                  ListTile(
                    leading: const Icon(Icons.phone_outlined, color: AppTheme.primaryNavy),
                    title: const Text('Registered Phone', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    trailing: Text(user?.phoneNumber ?? '9876543210', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

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
