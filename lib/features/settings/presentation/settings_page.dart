import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../application/settings_cubit.dart';
import '../application/settings_state.dart';
import 'manage_emotions_page.dart';

/// Settings screen — faithful to the mockup: Appearance / Reminders / Data,
/// with an added "Import from CSV" row alongside the original "Export to CSV".
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: c.onSurface),
        title: Row(
          children: [
            Icon(Icons.bubble_chart, color: c.primary, size: 22),
            const SizedBox(width: 8),
            Text('Settings',
                style: AppTypography.headlineMd(c.primary)
                    .copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        shape: Border(bottom: BorderSide(color: c.outlineVariant, width: 0.5)),
      ),
      body: BlocConsumer<SettingsCubit, SettingsState>(
        listenWhen: (a, b) => a.message != b.message && b.message != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message!)));
          context.read<SettingsCubit>().consumeMessage();
        },
        builder: (context, state) {
          final cubit = context.read<SettingsCubit>();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            children: [
              _sectionHeader(c, 'Appearance'),
              _group(c, [
                _row(
                  c,
                  icon: Icons.palette_outlined,
                  label: 'Theme',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.themeMode.label,
                          style: AppTypography.bodyMd(c.primary)
                              .copyWith(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 20, color: c.onSurfaceVariant),
                    ],
                  ),
                  onTap: () => _pickTheme(context, cubit, state.themeMode),
                ),
              ]),
              const SizedBox(height: 40),
              _sectionHeader(c, 'Reminders'),
              _group(c, [
                _row(
                  c,
                  icon: Icons.notifications_active_outlined,
                  label: 'Daily prompt',
                  trailing: Switch(
                    value: state.dailyPrompt,
                    onChanged: cubit.setDailyPrompt,
                    activeColor: c.onPrimary,
                    activeTrackColor: c.primary,
                  ),
                ),
              ]),
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 8),
                child: Text(
                  "You'll receive a gentle notification to check in with your "
                  'feelings once a day.',
                  style: AppTypography.labelSm(c.onSurfaceVariant)
                      .copyWith(height: 1.4),
                ),
              ),
              const SizedBox(height: 40),
              _sectionHeader(c, 'Data'),
              _group(c, [
                _row(
                  c,
                  icon: Icons.tune,
                  label: 'Manage Emotions',
                  trailing: Icon(Icons.chevron_right, size: 20, color: c.onSurfaceVariant),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => const ManageEmotionsPage())),
                ),
                _divider(c),
                _row(
                  c,
                  icon: Icons.download,
                  label: 'Export to CSV',
                  trailing: Icon(Icons.chevron_right, size: 20, color: c.onSurfaceVariant),
                  onTap: state.busy ? null : cubit.exportCsv,
                ),
                _divider(c),
                _row(
                  c,
                  icon: Icons.upload,
                  label: 'Import from CSV',
                  trailing: Icon(Icons.chevron_right, size: 20, color: c.onSurfaceVariant),
                  onTap: state.busy ? null : cubit.importCsv,
                ),
                _divider(c),
                _row(
                  c,
                  icon: Icons.delete_forever,
                  label: 'Delete all data',
                  danger: true,
                  onTap: state.busy ? null : () => _confirmDelete(context, cubit),
                ),
              ]),
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.spa, size: 40, color: c.primary.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    const _AppVersionLabel(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickTheme(
      BuildContext context, SettingsCubit cubit, AppThemeMode current) async {
    final c = context.colors;
    final picked = await showModalBottomSheet<AppThemeMode>(
      context: context,
      backgroundColor: c.surface,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final m in AppThemeMode.values)
              ListTile(
                title: Text(m.label, style: AppTypography.bodyLg(c.onSurface)),
                trailing: m == current ? Icon(Icons.check, color: c.primary) : null,
                onTap: () => Navigator.of(context).pop(m),
              ),
          ],
        ),
      ),
    );
    if (picked != null) cubit.setThemeMode(picked);
  }

  Future<void> _confirmDelete(BuildContext context, SettingsCubit cubit) async {
    final c = context.colors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surfaceContainer,
        title: Text('Delete all data?', style: AppTypography.headlineMd(c.onSurface)),
        content: Text('This permanently removes every entry. This cannot be undone.',
            style: AppTypography.bodyMd(c.onSurfaceVariant)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: AppTypography.labelSm(c.onSurfaceVariant))),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete', style: AppTypography.labelSm(c.error))),
        ],
      ),
    );
    if (ok == true) cubit.deleteAllData();
  }

  Widget _sectionHeader(AppColors c, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 8),
        child: Text(text.toUpperCase(),
            style: AppTypography.labelSm(c.onSurfaceVariant)
                .copyWith(letterSpacing: 1.5)),
      );

  Widget _group(AppColors c, List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: c.surfaceContainer,
          border: Border.all(color: c.outlineVariant, width: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      );

  Widget _divider(AppColors c) => Divider(height: 0.5, thickness: 0.5, color: c.outlineVariant);

  Widget _row(
    AppColors c, {
    required IconData icon,
    required String label,
    Widget? trailing,
    VoidCallback? onTap,
    bool danger = false,
  }) {
    final color = danger ? c.error : c.onSurface;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: danger ? c.error : c.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label,
                  style: AppTypography.bodyLg(color)
                      .copyWith(fontWeight: danger ? FontWeight.w500 : FontWeight.w400)),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}

class _AppVersionLabel extends StatefulWidget {
  const _AppVersionLabel();

  @override
  State<_AppVersionLabel> createState() => _AppVersionLabelState();
}

class _AppVersionLabelState extends State<_AppVersionLabel> {
  String? _label;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (!mounted) return;
      setState(() => _label = 'v${info.version} — Built for Clarity');
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Text(
      _label ?? '',
      style: AppTypography.labelSm(c.onSurfaceVariant),
    );
  }
}
