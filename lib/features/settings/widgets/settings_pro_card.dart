import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/constants/app_assets.dart';
import '../../../app/routes/route_names.dart';
import '../../../shared/providers/settings_provider.dart';
import '../../../shared/widgets/app_animations.dart';
import '../../home/home_constants.dart';

class SettingsProCard extends StatelessWidget {
  const SettingsProCard({super.key});

  static const _themeBlue = Color(0xFF3B66FF);

  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5C82FF), _themeBlue],
  );

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<SettingsProvider>().isPremium;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HomeConstants.screenPadding,
        18,
        HomeConstants.screenPadding,
        0,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).pushNamed(RouteNames.premium);
          },
          borderRadius: BorderRadius.circular(HomeConstants.cardRadius),
          child: Ink(
            decoration: BoxDecoration(
              gradient: _gradient,
              borderRadius: BorderRadius.circular(HomeConstants.cardRadius),
              boxShadow: [
                BoxShadow(
                  color: _themeBlue.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Image.asset(
                      AppAssets.proCrown,
                      fit: BoxFit.contain,
                      color: _themeBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPremium ? "You're a Pro member" : 'Upgrade to Pro',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPremium
                              ? 'Unlimited scans, HD export, and an ad-free app'
                              : 'Unlock unlimited scans, HD export, and remove ads',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12.5,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).fadeScaleIn(delayMs: 80);
  }
}
