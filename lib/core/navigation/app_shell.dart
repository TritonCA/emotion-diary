import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../features/record/presentation/record_page.dart';
import '../../features/history/presentation/history_page.dart';
import '../../features/stats/presentation/stats_page.dart';

/// Root scaffold owning the 3-tab bottom navigation from the mockups.
/// Pages are kept alive via IndexedStack so form/scroll state survives swaps.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _pages = [RecordPage(), HistoryPage(), StatsPage()];

  void _goTo(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: _BottomNav(current: _index, onTap: _goTo),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.current, required this.onTap});
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.outlineVariant, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.edit_note,
                label: 'Record',
                active: current == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.history,
                label: 'History',
                active: current == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.leaderboard,
                label: 'Stats',
                active: current == 2,
                onTap: () => onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = active ? c.primary : c.onSurfaceVariant;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelSm(color)
                  .copyWith(fontWeight: active ? FontWeight.w700 : FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
