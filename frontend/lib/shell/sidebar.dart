import 'package:flutter/material.dart';
import 'package:frontend/core/app_theme.dart';
import 'package:frontend/core/app_page.dart';

class Sidebar extends StatelessWidget {
  final AppPage currentPage;
  final ValueChanged<AppPage> onPageSelected;
  final bool isCompact;

  const Sidebar({
    super.key,
    required this.currentPage,
    required this.onPageSelected,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sidebar,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 16,
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment:
            isCompact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          _buildBrand(),

          const SizedBox(height: 32),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: isCompact
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  if (!isCompact) ...[
                    const _SectionTitle(label: 'OVERVIEW'),
                    const SizedBox(height: 8),
                  ],

                  _NavigationItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    isCompact: isCompact,
                    selected: currentPage == AppPage.dashboard,
                    onTap: () => onPageSelected(AppPage.dashboard),
                  ),

                  const SizedBox(height: 20),

                  if (!isCompact) ...[
                    const _SectionTitle(label: 'OPERATIONS'),
                    const SizedBox(height: 8),
                  ],

                  _NavigationItem(
                    icon: Icons.map_outlined,
                    label: 'Live Traffic',
                    isCompact: isCompact,
                    selected: currentPage == AppPage.traffic,
                    onTap: () => onPageSelected(AppPage.traffic),
                  ),

                  _NavigationItem(
                    icon: Icons.warning_amber_outlined,
                    label: 'Incidents',
                    isCompact: isCompact,
                    selected: currentPage == AppPage.incidents,
                    onTap: () => onPageSelected(AppPage.incidents),
                  ),

                  _NavigationItem(
                    icon: Icons.local_fire_department_outlined,
                    label: 'Hotspots',
                    isCompact: isCompact,
                    selected: currentPage == AppPage.hotspots,
                    onTap: () => onPageSelected(AppPage.hotspots),
                  ),

                  const SizedBox(height: 20),

                  if (!isCompact) ...[
                    const _SectionTitle(label: 'INSIGHTS'),
                    const SizedBox(height: 8),
                  ],

                  _NavigationItem(
                    icon: Icons.analytics_outlined,
                    label: 'Analytics',
                    isCompact: isCompact,
                    selected: currentPage == AppPage.analytics,
                    onTap: () => onPageSelected(AppPage.analytics),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          _SystemStatus(isCompact: isCompact),
        ],
      ),
    );
  }

  Widget _buildBrand() {
    if (isCompact) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(
            Icons.traffic,
            size: 20,
            color: AppColors.accent,
          ),
        ),
      );
    }

    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.traffic,
              size: 22,
              color: AppColors.accent,
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'RISE TRAFFIC',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          'COMMAND & CONTROL',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool isCompact;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isCompact ? label : '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 10 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.surfaceElevated
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: selected
                ? Border.all(color: AppColors.accent.withValues(alpha: 0.3))
                : null,
          ),
          child: Row(
            mainAxisAlignment:
                isCompact ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 19,
                color: selected
                    ? AppColors.accent
                    : AppColors.textSecondary,
              ),
              if (!isCompact) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SystemStatus extends StatelessWidget {
  final bool isCompact;

  const _SystemStatus({this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Tooltip(
        message: 'SYSTEM ONLINE',
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: const Center(
            child: Icon(
              Icons.circle,
              size: 8,
              color: AppColors.systemOnline,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: AppColors.systemOnline,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'SYSTEM ONLINE',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
