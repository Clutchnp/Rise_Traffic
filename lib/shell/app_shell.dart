import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:frontend/screens/live_traffic_screen.dart';
import 'package:frontend/screens/incidents_screen.dart';
import 'package:frontend/screens/hotspots_screen.dart';
import 'package:frontend/screens/analytics_screen.dart';
import '../screens/dashboard_screen.dart';
import 'package:frontend/core/app_page.dart';
import 'sidebar.dart';
import 'top_bar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppPage currentPage = AppPage.dashboard;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final sidebarWidth = constraints.maxWidth < 1000
              ? constraints.maxWidth * 0.14
              : constraints.maxWidth * 0.12;
          return Row(
            children: [
              SizedBox(
                width: sidebarWidth,
                child: Sidebar(
                  currentPage: currentPage,
                  onPageSelected: (page) {
                    setState(() {
                      currentPage = page;
                    });
                  },
                ),
              ),

              Expanded(
                child: Column(
                  children: [
                    const TopBar(),

                    Expanded(child: _buildCurrentPage()),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (currentPage) {
      case AppPage.dashboard:
        return const DashboardScreen();

      case AppPage.traffic:
        return const LiveTrafficScreen();

      case AppPage.incidents:
        return const IncidentsScreen();

      case AppPage.hotspots:
        return const HotspotsScreen();

      case AppPage.analytics:
        return const AnalyticsScreen();
    }
  }
}
