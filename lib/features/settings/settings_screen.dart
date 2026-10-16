import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/constants/app_constants.dart';
import '../../shared/providers/settings_provider.dart';
import '../../shared/services/pro_purchase_service.dart';
import '../home/home_constants.dart';
import 'widgets/settings_header.dart';
import 'widgets/settings_menu_tile.dart';
import 'widgets/settings_pro_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.embedded = false});

  final bool embedded;

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open link.')));
      }
    }
  }

  Future<void> _restore(BuildContext context) async {
    await context.read<ProPurchaseService>().restore();
    if (!context.mounted) return;
    final isPremium = context.read<SettingsProvider>().isPremium;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isPremium
              ? 'Pro access restored.'
              : 'No active subscription was found.',
        ),
      ),
    );
  }

  Future<void> _openSupport(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppConstants.supportEmail,
      query:
          'subject=${Uri.encodeComponent('${AppConstants.appName} Support')}',
    );
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email us at ${AppConstants.supportEmail}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeConstants.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(bottom: embedded ? 110 : 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsHeader(showBack: !embedded),
              if (!context.watch<SettingsProvider>().isPremium)
                const SettingsProCard(),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: HomeConstants.screenPadding,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      HomeConstants.cardRadius,
                    ),
                    border: Border.all(color: const Color(0xFFEEF2F7)),
                    boxShadow: [
                      HomeConstants.softShadow(blur: 12, y: 4, opacity: 0.05),
                    ],
                  ),
                  child: Column(
                    children: [
                      SettingsMenuTile(
                        icon: Icons.privacy_tip_outlined,
                        iconColor: const Color(0xFF6366F1),
                        iconBg: const Color(0xFFEEF2FF),
                        title: 'Privacy Policy',
                        subtitle: 'How we protect your data',
                        animationIndex: 0,
                        onTap: () =>
                            _openUrl(context, AppConstants.privacyPolicyUrl),
                      ),
                      SettingsMenuTile(
                        icon: Icons.description_outlined,
                        iconColor: const Color(0xFF3B82F6),
                        iconBg: const Color(0xFFEFF6FF),
                        title: 'Terms & Conditions',
                        subtitle: 'Rules for using this app',
                        animationIndex: 1,
                        onTap: () => _openUrl(context, AppConstants.termsUrl),
                      ),
                      SettingsMenuTile(
                        icon: Icons.headset_mic_outlined,
                        iconColor: const Color(0xFF10B981),
                        iconBg: const Color(0xFFECFDF5),
                        title: 'Support',
                        subtitle: 'Get help or send feedback',
                        animationIndex: 2,
                        onTap: () => _openSupport(context),
                      ),
                      SettingsMenuTile(
                        icon: Icons.restore_rounded,
                        iconColor: const Color(0xFF3B66FF),
                        iconBg: const Color(0xFFEEF2FF),
                        title: 'Restore Purchases',
                        subtitle: 'Restore your Pro subscription',
                        showDivider: false,
                        animationIndex: 3,
                        onTap: () => _restore(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
