import 'package:brainiac_plus/features/dashboard/widgets/ai/ai_chat_fab.dart';
import 'package:brainiac_plus/features/dashboard/widgets/navigation/floating_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/navigation/navigation_service.dart';
import '../terminal/terminal_screen.dart';
import '../automation/screens/automation_main_screen.dart';
import '../file_manager/file_manager_screen.dart';
import '../settings/screens/modern_settings_screen.dart';
import '../activity/recent_activity_screen.dart';
import 'widgets/hud/hud_background.dart';
import 'widgets/hud/hud_theme.dart';
import 'widgets/hud/jarvis_dashboard.dart';

// Constant for bottom navigation bar height
const double kBottomNavHeight = 100.0;

class DashboardScreen extends ConsumerStatefulWidget {
  final int? initialTabIndex;
  final int? initialSettingsTabIndex;
  final int? initialAutomationTabIndex;

  const DashboardScreen({
    super.key,
    this.initialTabIndex = 0,
    this.initialSettingsTabIndex = 0,
    this.initialAutomationTabIndex = 0,
  });

  const DashboardScreen.withIndex({
    super.key,
    this.initialTabIndex = 0,
    this.initialSettingsTabIndex = 0,
    this.initialAutomationTabIndex = 0,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;
  int _settingsTabIndex = 0;
  int _automationTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = _sanitizeMainIndex(widget.initialTabIndex ?? 0);
    _settingsTabIndex = _sanitizeSettingsIndex(
      widget.initialSettingsTabIndex ?? 0,
    );
    _automationTabIndex = _sanitizeAutomationIndex(
      widget.initialAutomationTabIndex ?? 0,
    );
    // Register tab change callback with navigation service
    NavigationService().onTabChange = (tabIndex) {
      setState(() {
        _currentIndex = _sanitizeMainIndex(tabIndex);
      });
    };
  }

  @override
  void dispose() {
    // Clean up navigation service callback
    NavigationService().onTabChange = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient(isDark),
        child: Stack(
          children: [
            // Main content based on selected tab
            _buildContent(),

            // Floating Bottom Navigation Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingBottomBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
            ),

            // AI Chat FAB
            Positioned(
              right: 20,
              bottom: 100,
              child: AIChatFAB(onPressed: _showAIChatBottomSheet),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return const TerminalScreen();
      case 2:
        return AutomationMainScreen(initialTabIndex: _automationTabIndex);
      case 3:
        return const FileManagerScreen();
      case 4:
        return ModernSettingsScreen(initialTabIndex: _settingsTabIndex);
      default:
        return _buildDashboardContent();
    }
  }

  int _sanitizeMainIndex(int value) {
    if (value < 0) return 0;
    if (value > 4) return 4;
    return value;
  }

  int _sanitizeSettingsIndex(int value) {
    if (value < 0) return 0;
    if (value > 3) return 3;
    return value;
  }

  int _sanitizeAutomationIndex(int value) {
    if (value < 0) return 0;
    if (value > 3) return 3;
    return value;
  }

  Widget _buildDashboardContent() {
    // Jarvis-style command HUD: holographic vitals over a technical grid.
    return HudBackground(
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const Expanded(child: JarvisDashboard()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // Reactor-core mark.
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  HudTheme.cyanGlow.withValues(alpha: 0.4),
                  HudTheme.panel,
                ],
              ),
              border: Border.all(color: HudTheme.cyan.withValues(alpha: 0.6)),
              boxShadow: [
                BoxShadow(
                  color: HudTheme.cyan.withValues(alpha: 0.35),
                  blurRadius: 18,
                ),
              ],
            ),
            child: const Icon(
              Icons.blur_on,
              color: HudTheme.cyanGlow,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'BRAINIAC',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PLUS',
                      style: TextStyle(
                        color: HudTheme.cyan,
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
                Text(
                  'SYSTEM COMMAND INTERFACE',
                  style: TextStyle(
                    color: HudTheme.cyan.withValues(alpha: 0.55),
                    fontFamily: 'monospace',
                    fontSize: 10,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.history,
              color: HudTheme.cyan.withValues(alpha: 0.8),
            ),
            tooltip: 'Activity log',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RecentActivityScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAIChatBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          AIChatOverlay(onClose: () => Navigator.pop(context)),
    );
  }
}
