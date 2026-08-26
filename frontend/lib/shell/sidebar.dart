import 'package:flutter/material.dart';
import 'package:frontend/core/app_theme.dart';
import 'package:frontend/core/app_page.dart';

class Sidebar extends StatelessWidget {
  final AppPage currentPage;
  final ValueChanged<AppPage> onPageSelected;

  const Sidebar({
    super.key,
    required this.currentPage,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sidebar,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBrand(),

          const SizedBox(height: 40),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(label: 'OVERVIEW'),

                  const SizedBox(height: 10),

                  _NavigationItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    selected: currentPage == AppPage.dashboard,
                    onTap: () => onPageSelected(AppPage.dashboard),
                  ),

                  const SizedBox(height: 24),

                  const _SectionTitle(label: 'OPERATIONS'),

                  const SizedBox(height: 10),

                  _NavigationItem(
                    icon: Icons.map_outlined,
                    label: 'Live Traffic',
                    selected: currentPage == AppPage.traffic,
                    onTap: () => onPageSelected(AppPage.traffic),
                  ),

                  _NavigationItem(
                    icon: Icons.warning_amber_outlined,
                    label: 'Incidents',
                    selected: currentPage == AppPage.incidents,
                    onTap: () => onPageSelected(AppPage.incidents),
                  ),

                  _NavigationItem(
                    icon: Icons.local_fire_department_outlined,
                    label: 'Hotspots',
                    selected: currentPage == AppPage.hotspots,
                    onTap: () => onPageSelected(AppPage.hotspots),
                  ),

                  const SizedBox(height: 24),

                  const _SectionTitle(label: 'INSIGHTS'),

                  const SizedBox(height: 10),

                  _NavigationItem(
                    icon: Icons.analytics_outlined,
                    label: 'Analytics',
                    selected: currentPage == AppPage.analytics,
                    onTap: () => onPageSelected(AppPage.analytics),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          const _SystemStatus(),
        ],
      ),
    );
  }

  Widget _buildBrand() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOTRAFFIC',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),

        SizedBox(height: 4),

        Text(
          'TRAFFIC OPERATIONS',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
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
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.surfaceElevated
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 19,
              color: selected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),

            const SizedBox(width: 12),

            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: 14,
                fontWeight: selected
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemStatus extends StatelessWidget {
  const _SystemStatus();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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

          Text(
            'SYSTEM OPERATIONAL',
            style: TextStyle(
              color: AppColors.textSecondary,
              overflow: TextOverflow.ellipsis,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
