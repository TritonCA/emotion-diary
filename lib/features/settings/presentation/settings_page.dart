import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/di/injector.dart';
import '../../../core/l10n/app_locale.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../reminders/application/reminders_cubit.dart';
import '../../reminders/presentation/reminders_page.dart';
import '../application/settings_cubit.dart';
import '../application/settings_state.dart';
import 'manage_emotions_page.dart';

/// Settings screen — Appearance / Language / Reminders / Data sections.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
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
            Text(s.t('settings.title'),
                style: AppTypography.headlineMd(c.primary)
                    .copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        shape: Border(bottom: BorderSide(color: c.outlineVariant, width: 0.5)),
      ),
      body: BlocConsumer<SettingsCubit, SettingsState>(
        listenWhen: (a, b) => a.message != b.message && b.message != null,
        listener: (context, _) {
          final cubit = context.read<SettingsCubit>();
          final msg = cubit.pendingMessage;
          if (msg == null) return;
          final text = _translateMessage(context.s, msg);
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(text)));
          cubit.consumeMessage();
        },
        builder: (context, state) {
          final cubit = context.read<SettingsCubit>();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            children: [
              _sectionHeader(c, s.t('settings.appearance')),
              _group(c, [
                _row(
                  c,
                  icon: Icons.palette_outlined,
                  label: s.t('settings.theme'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_themeLabel(s, state.themeMode),
                          style: AppTypography.bodyMd(c.primary)
                              .copyWith(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 20, color: c.onSurfaceVariant),
                    ],
                  ),
                  onTap: () => _pickTheme(context, cubit, state.themeMode),
                ),
                _divider(c),
                _row(
                  c,
                  icon: Icons.language,
                  label: s.t('settings.language'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.locale.nativeLabel,
                          style: AppTypography.bodyMd(c.primary)
                              .copyWith(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 20, color: c.onSurfaceVariant),
                    ],
                  ),
                  onTap: () => _pickLocale(context, cubit, state.locale),
                ),
              ]),
              const SizedBox(height: 40),
              _sectionHeader(c, s.t('settings.reminders')),
              _group(c, [
                _row(
                  c,
                  icon: Icons.notifications_active_outlined,
                  label: s.t('settings.reminders.manage'),
                  trailing: _RemindersCountBadge(),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => BlocProvider<RemindersCubit>.value(
                      value: sl<RemindersCubit>(),
                      child: const RemindersPage(),
                    ),
                  )),
                ),
              ]),
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 8),
                child: Text(
                  s.t('settings.reminders.hint'),
                  style: AppTypography.labelSm(c.onSurfaceVariant)
                      .copyWith(height: 1.4),
                ),
              ),
              const SizedBox(height: 40),
              _sectionHeader(c, s.t('settings.data')),
              _group(c, [
                _row(
                  c,
                  icon: Icons.tune,
                  label: s.t('settings.manage_emotions'),
                  trailing: Icon(Icons.chevron_right, size: 20, color: c.onSurfaceVariant),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => const ManageEmotionsPage())),
                ),
                _divider(c),
                _row(
                  c,
                  icon: Icons.download,
                  label: s.t('settings.export_csv'),
                  trailing: Icon(Icons.chevron_right, size: 20, color: c.onSurfaceVariant),
                  onTap: state.busy ? null : cubit.exportCsv,
                ),
                _divider(c),
                _row(
                  c,
                  icon: Icons.upload,
                  label: s.t('settings.import_csv'),
                  trailing: Icon(Icons.chevron_right, size: 20, color: c.onSurfaceVariant),
                  onTap: state.busy ? null : cubit.importCsv,
                ),
                _divider(c),
                _row(
                  c,
                  icon: Icons.delete_forever,
                  label: s.t('settings.delete_all'),
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

  String _themeLabel(AppStrings s, AppThemeMode m) => switch (m) {
        AppThemeMode.light => s.t('settings.theme.light'),
        AppThemeMode.dark => s.t('settings.theme.dark'),
        AppThemeMode.system => s.t('settings.theme.system'),
      };

  String _translateMessage(AppStrings s, SettingsMessage msg) {
    return switch (msg.kind) {
      SettingsMessageKind.exportReady => s.t('settings.msg.export_ready'),
      SettingsMessageKind.exportFailed => s.t('settings.msg.export_failed'),
      SettingsMessageKind.importOk =>
        s.t('settings.msg.import_ok').replaceAll('{n}', '${msg.count ?? 0}'),
      SettingsMessageKind.importCancelled =>
        s.t('settings.msg.import_cancelled'),
      SettingsMessageKind.importFailed => s.t('settings.msg.import_failed'),
      SettingsMessageKind.deleted => s.t('settings.msg.deleted'),
    };
  }

  Future<void> _pickTheme(
      BuildContext context, SettingsCubit cubit, AppThemeMode current) async {
    final c = context.colors;
    final s = context.s;
    final picked = await showModalBottomSheet<AppThemeMode>(
      context: context,
      backgroundColor: c.surface,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final m in AppThemeMode.values)
              ListTile(
                title: Text(_themeLabel(s, m),
                    style: AppTypography.bodyLg(c.onSurface)),
                trailing: m == current ? Icon(Icons.check, color: c.primary) : null,
                onTap: () => Navigator.of(context).pop(m),
              ),
          ],
        ),
      ),
    );
    if (picked != null) cubit.setThemeMode(picked);
  }

  Future<void> _pickLocale(
      BuildContext context, SettingsCubit cubit, AppLocale current) async {
    final c = context.colors;
    final picked = await showModalBottomSheet<AppLocale>(
      context: context,
      backgroundColor: c.surface,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final l in AppLocale.values)
              ListTile(
                title:
                    Text(l.nativeLabel, style: AppTypography.bodyLg(c.onSurface)),
                trailing: l == current ? Icon(Icons.check, color: c.primary) : null,
                onTap: () => Navigator.of(context).pop(l),
              ),
          ],
        ),
      ),
    );
    if (picked != null) cubit.setLocale(picked);
  }

  Future<void> _confirmDelete(BuildContext context, SettingsCubit cubit) async {
    final c = context.colors;
    final s = context.s;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surfaceContainer,
        title: Text(s.t('settings.delete_confirm.title'),
            style: AppTypography.headlineMd(c.onSurface)),
        content: Text(s.t('settings.delete_confirm.body'),
            style: AppTypography.bodyMd(c.onSurfaceVariant)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(s.t('common.cancel'),
                  style: AppTypography.labelSm(c.onSurfaceVariant))),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(s.t('common.delete'),
                  style: AppTypography.labelSm(c.error))),
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

class _RemindersCountBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocProvider<RemindersCubit>.value(
      value: sl<RemindersCubit>(),
      child: Builder(builder: (context) {
        final count = context.watch<RemindersCubit>().state.reminders.length;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (count > 0)
              Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: c.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text('$count',
                    style: AppTypography.labelSm(c.primary)
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
            Icon(Icons.chevron_right, size: 20, color: c.onSurfaceVariant),
          ],
        );
      }),
    );
  }
}

class _AppVersionLabel extends StatefulWidget {
  const _AppVersionLabel();

  @override
  State<_AppVersionLabel> createState() => _AppVersionLabelState();
}

class _AppVersionLabelState extends State<_AppVersionLabel> {
  String? _version;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (!mounted) return;
      setState(() => _version = 'v${info.version}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final v = _version;
    return Text(
      v == null ? '' : '$v — ${context.s.t('settings.built_for')}',
      style: AppTypography.labelSm(c.onSurfaceVariant),
    );
  }
}
