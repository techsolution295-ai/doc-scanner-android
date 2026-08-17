import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum HomeNavItem { home, files, tools, settings }

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({
    super.key,
    required this.current,
    required this.onHome,
    required this.onFiles,
    required this.onCamera,
    required this.onTools,
    required this.onSettings,
  });

  final HomeNavItem current;
  final VoidCallback onHome;
  final VoidCallback onFiles;
  final VoidCallback onCamera;
  final VoidCallback onTools;
  final VoidCallback onSettings;

  static const Color _activeBlue = Color(0xFF3B66FF);
  static const Color _inactiveGrey = Color(0xFF8E8E93);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 0, 18, bottomInset + 10),
      child: SizedBox(
        height: 76,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFFF0F2F6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: _NavTile(
                        label: 'Home',
                        selected: current == HomeNavItem.home,
                        onTap: onHome,
                        icon: CupertinoIcons.house,
                        selectedIcon: CupertinoIcons.house_fill,
                      ),
                    ),
                    Expanded(
                      child: _NavTile(
                        label: 'Files',
                        selected: current == HomeNavItem.files,
                        onTap: onFiles,
                        icon: CupertinoIcons.folder,
                        selectedIcon: CupertinoIcons.folder_fill,
                      ),
                    ),
                    const SizedBox(width: 58),
                    Expanded(
                      child: _NavTile(
                        label: 'Tools',
                        selected: current == HomeNavItem.tools,
                        onTap: onTools,
                        icon: CupertinoIcons.square_grid_2x2,
                        selectedIcon: CupertinoIcons.square_grid_2x2_fill,
                      ),
                    ),
                    Expanded(
                      child: _NavTile(
                        label: 'Settings',
                        selected: current == HomeNavItem.settings,
                        onTap: onSettings,
                        icon: CupertinoIcons.gear,
                        selectedIcon: CupertinoIcons.gear_solid,
                      ),
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                .slideY(begin: 0.35, end: 0, duration: 550.ms, curve: Curves.easeOutCubic),
            Positioned(
              top: 0,
              child: _CameraButton(onTap: onCamera),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraButton extends StatefulWidget {
  const _CameraButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_CameraButton> createState() => _CameraButtonState();
}

class _CameraButtonState extends State<_CameraButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF4B8BFF),
                Color(0xFF2B5FE8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: CustomBottomNavBar._activeBlue.withValues(alpha: 0.45),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            CupertinoIcons.camera,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 2000.ms,
          curve: Curves.easeInOut,
        )
        .animate()
        .fadeIn(delay: 200.ms, duration: 450.ms)
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1, 1),
          delay: 200.ms,
          duration: 500.ms,
          curve: Curves.elasticOut,
        );
  }
}

class _NavTile extends StatefulWidget {
  const _NavTile({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;
  final IconData selectedIcon;

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.selected ? CustomBottomNavBar._activeBlue : CustomBottomNavBar._inactiveGrey;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedScale(
          scale: _pressed ? 0.9 : (widget.selected ? 1.05 : 1),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.selected
                        ? CustomBottomNavBar._activeBlue.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.selected ? widget.selectedIcon : widget.icon,
                    color: color,
                    size: 23,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                    height: 1.1,
                  ),
                  child: Text(widget.label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
