import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../features/settings/application/settings_cubit.dart';
import '../../features/settings/application/settings_state.dart';
import '../../features/settings/presentation/settings_page.dart';

/// Sticky top app bar replicating the HTML header: bubble_chart logo + title
/// in primary color, theme toggle on the right, plus a settings entry point.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, required this.title});
  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(57);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = context.watch<SettingsCubit>().state.themeMode == AppThemeMode.dark ||
        (context.watch<SettingsCubit>().state.themeMode == AppThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.outlineVariant, width: 0.5)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.bubble_chart, color: c.primary, size: 24),
              const SizedBox(width: 8),
              Text(title, style: AppTypography.headlineMd(c.primary).copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                tooltip: 'Settings',
                icon: Icon(Icons.tune, color: c.onSurfaceVariant, size: 22),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
                ),
              ),
              IconButton(
                tooltip: 'Toggle theme',
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode,
                    color: c.onSurfaceVariant, size: 22),
                onPressed: () => context.read<SettingsCubit>().toggleTheme(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
