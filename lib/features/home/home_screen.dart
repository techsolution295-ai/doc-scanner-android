import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/constants/app_assets.dart';
import '../../app/routes/route_names.dart';
import '../../shared/models/scan_session.dart';
import '../../shared/providers/document_provider.dart';
import '../../shared/widgets/app_animations.dart';
import '../files/files_screen.dart';
import '../files/widgets/files_list_item.dart';
import '../image_to_pdf/image_to_pdf_flow.dart';
import '../pdf_tools/pdf_tools_screen.dart';
import '../pdf_viewer/pdf_viewer_screen.dart';
import '../scanner/scan_flow.dart';
import '../settings/settings_screen.dart';
import 'home_constants.dart';
import 'widgets/custom_bottom_nav_bar.dart';
import 'widgets/feature_grid_card.dart';
import 'widgets/home_banner.dart';
import 'widgets/home_header.dart';
import 'widgets/recent_scan_item.dart';
import 'widgets/scan_button_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeNavItem _nav = HomeNavItem.home;
  final Set<HomeNavItem> _visited = {HomeNavItem.home};

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _openScanner() => ScanFlow.startDocumentScan(context);

  void _setNav(HomeNavItem item) {
    setState(() {
      _visited.add(item);
      _nav = item;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeConstants.background,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _nav.index,
          children: [
            AnimatedTabBody(
              active: _nav == HomeNavItem.home,
              child: _HomeDashboard(
                greeting: _greeting,
                onOpenScanner: _openScanner,
                onOpenPremium: () => Navigator.of(context).pushNamed(RouteNames.premium),
                onOpenFiles: () => _setNav(HomeNavItem.files),
              ),
            ),
            AnimatedTabBody(
              active: _nav == HomeNavItem.files,
              child: _visited.contains(HomeNavItem.files)
                  ? const FilesScreen(embedded: true)
                  : const SizedBox.shrink(),
            ),
            AnimatedTabBody(
              active: _nav == HomeNavItem.tools,
              child: _visited.contains(HomeNavItem.tools)
                  ? const PdfToolsScreen(embedded: true)
                  : const SizedBox.shrink(),
            ),
            AnimatedTabBody(
              active: _nav == HomeNavItem.settings,
              child: _visited.contains(HomeNavItem.settings)
                  ? const SettingsScreen(embedded: true)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        current: _nav,
        onHome: () => _setNav(HomeNavItem.home),
        onFiles: () => _setNav(HomeNavItem.files),
        onCamera: _openScanner,
        onTools: () => _setNav(HomeNavItem.tools),
        onSettings: () => _setNav(HomeNavItem.settings),
      ),
    );
  }
}

class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard({
    required this.greeting,
    required this.onOpenScanner,
    required this.onOpenPremium,
    required this.onOpenFiles,
  });

  final String greeting;
  final VoidCallback onOpenScanner;
  final VoidCallback onOpenPremium;
  final VoidCallback onOpenFiles;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeHeader(greeting: greeting),
          HomeBanner(onTap: onOpenScanner),
          ScanButtonCard(onTap: onOpenScanner),
          _FeatureGrid(
            onOpenFiles: onOpenFiles,
            onOpenPremium: onOpenPremium,
          ),
          _RecentScansSection(
            onViewAll: onOpenFiles,
          ),
        ],
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({
    required this.onOpenFiles,
    required this.onOpenPremium,
  });

  final VoidCallback onOpenFiles;
  final VoidCallback onOpenPremium;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Document Scan',
        'Scan any document',
        AppAssets.iconDocument,
        () => ScanFlow.startDocumentScan(context),
      ),
      (
        'ID Card Scan',
        'Scan ID, Passport, etc.',
        AppAssets.iconIdCard,
        () => Navigator.of(context).pushNamed(RouteNames.cardScanner),
      ),
      (
        'Image to PDF',
        'Convert images to PDF',
        AppAssets.iconImagePdf,
        () => ImageToPdfFlow.start(context),
      ),
      (
        'PDF Tools',
        'Edit, merge, compress',
        AppAssets.iconPdfTools,
        () => Navigator.of(context).pushNamed(RouteNames.pdfTools),
      ),
      (
        'My Files',
        'View saved documents',
        AppAssets.iconMyFiles,
        onOpenFiles,
      ),
      (
        'Premium',
        'Unlock all features',
        AppAssets.iconPremium,
        onOpenPremium,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HomeConstants.screenPadding,
        HomeConstants.sectionGap,
        HomeConstants.screenPadding,
        0,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 6,
          childAspectRatio: 1.02,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          return FeatureGridCard(
            title: item.$1,
            subtitle: item.$2,
            iconAsset: item.$3,
            onTap: item.$4,
            animationIndex: i,
          );
        },
      ),
    );
  }
}

class _RecentScansSection extends StatelessWidget {
  const _RecentScansSection({required this.onViewAll});

  final VoidCallback onViewAll;

  void _openDoc(BuildContext context, ScannedDocument doc) {
    if (!File(doc.filePath).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File no longer exists.')),
      );
      return;
    }
    Navigator.of(context).pushNamed(
      RouteNames.pdfViewer,
      arguments: PdfViewerArgs(filePath: doc.filePath, title: doc.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DocumentProvider>(
      builder: (context, provider, _) {
        final recent = provider.recentDocuments.take(4).toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            HomeConstants.screenPadding,
            22,
            HomeConstants.screenPadding,
            0,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Scans',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: HomeConstants.navyText,
                    ),
                  ).fadeSlideIn(delayMs: 400),
                  if (recent.isNotEmpty)
                    TextButton(
                      onPressed: onViewAll,
                      style: TextButton.styleFrom(
                        foregroundColor: HomeConstants.linkBlue,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('View All', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          Icon(Icons.chevron_right, size: 18),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (recent.isEmpty)
                const _RecentEmptyState().fadeSlideIn(delayMs: 500)
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(HomeConstants.cardRadius),
                    border: Border.all(color: const Color(0xFFEEF2F7)),
                    boxShadow: [HomeConstants.softShadow(blur: 14, y: 5, opacity: 0.05)],
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < recent.length; i++)
                        RecentScanItem(
                          document: recent[i],
                          subtitle: _subtitle(recent[i]),
                          showDivider: i < recent.length - 1,
                          animationIndex: i,
                          onTap: () => _openDoc(context, recent[i]),
                          onFavoriteTap: () => provider.toggleFavorite(recent[i].id),
                          onMoreTap: () => _openDoc(context, recent[i]),
                        ),
                    ],
                  ),
                ).fadeSlideIn(delayMs: 500),
            ],
          ),
        );
      },
    );
  }

  String _subtitle(ScannedDocument doc) {
    final meta = metaLine(doc);
    final date = formatFileDate(doc.createdAt);
    return meta.isEmpty ? date : '$meta • $date';
  }
}

class _RecentEmptyState extends StatelessWidget {
  const _RecentEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(HomeConstants.cardRadius),
        border: Border.all(color: const Color(0xFFEEF2F7)),
        boxShadow: [HomeConstants.softShadow(blur: 14, y: 5, opacity: 0.05)],
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: HomeConstants.linkBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.document_scanner_outlined,
                color: HomeConstants.linkBlue, size: 26),
          ),
          const SizedBox(height: 12),
          const Text(
            'No scans yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: HomeConstants.navyText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap “Scan Document” to create your first PDF.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: HomeConstants.greySubtitle),
          ),
        ],
      ),
    );
  }
}
