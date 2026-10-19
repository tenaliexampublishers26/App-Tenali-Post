import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';

class LogoHeader extends StatelessWidget {
  final double size;
  final bool showTitle;
  final bool showSubtitle;

  const LogoHeader({
    super.key,
    this.size = 100,
    this.showTitle = true,
    this.showSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryNavy.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              AppConstants.logoAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback elegant badge if asset is rendering
                return Container(
                  color: AppTheme.primaryNavy,
                  child: Center(
                    child: Icon(
                      Icons.account_balance_rounded,
                      size: size * 0.5,
                      color: AppTheme.accentGold,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (showTitle) ...[
          const SizedBox(height: 12),
          const Text(
            AppConstants.appName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryNavy,
              letterSpacing: 0.5,
            ),
          ),
        ],
        if (showSubtitle) ...[
          const SizedBox(height: 4),
          const Text(
            AppConstants.appTagline,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.secondaryMaroon,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ],
    );
  }
}
