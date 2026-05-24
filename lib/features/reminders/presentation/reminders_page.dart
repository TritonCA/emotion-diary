import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../application/reminders_cubit.dart';
import '../application/reminders_state.dart';
import '../domain/entities/reminder.dart';
import 'edit_reminder_page.dart';

/// Lists all user reminders with quick enable/disable + tap-to-edit.
class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _refreshPermission();
  }

  Future<void> _refreshPermission() async {
    final ok = await NotificationService.instance.isNotificationsEnabled();
    if (!mounted) return;
    setState(() => _notificationsEnabled = ok);
  }

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
        title: Text(s.t('reminders.title'),
            style: AppTypography.headlineMd(c.primary)
                .copyWith(fontWeight: FontWeight.w700)),
        shape: Border(bottom: BorderSide(color: c.outlineVariant, width: 0.5)),
      ),
      body: BlocBuilder<RemindersCubit, RemindersState>(
        builder: (context, state) {
          final cubit = context.read<RemindersCubit>();
          final children = <Widget>[
            if (!_notificationsEnabled) _permissionBanner(c, s),
          ];
          if (state.reminders.isEmpty) {
            return Column(
              children: [
                ...children,
                Expanded(child: _empty(context)),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              ...children,
              for (final r in state.reminders) ...[
                _ReminderCard(
                  reminder: r,
                  onTap: () => _openEditor(context, r),
                  onToggle: (v) async {
                    try {
                      await cubit.setEnabled(r.id, v);
                    } catch (_) {/* repo write rarely fails; rebuild reverts UI */}
                  },
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        onPressed: () => _openEditor(context, null),
        icon: const Icon(Icons.add),
        label: Text(s.t('reminders.add'),
            style: AppTypography.labelSm(c.onPrimary)
                .copyWith(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _permissionBanner(AppColors c, AppStrings s) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.error.withOpacity(0.10),
          border: Border.all(color: c.error.withOpacity(0.4), width: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.notifications_off_outlined, color: c.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                s.t('reminders.permission_denied'),
                style: AppTypography.labelSm(c.error).copyWith(height: 1.35),
              ),
            ),
          ],
        ),
      );

  Widget _empty(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none, size: 64, color: c.outline),
            const SizedBox(height: 16),
            Text(s.t('reminders.empty.title'),
                style: AppTypography.headlineMd(c.onSurface)),
            const SizedBox(height: 8),
            Text(
              s.t('reminders.empty.body'),
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd(c.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, Reminder? r) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(
          builder: (_) => EditReminderPage(existing: r),
        ))
        .then((_) => _refreshPermission());
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.onTap,
    required this.onToggle,
  });
  final Reminder reminder;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final next = NotificationService.nextFire(reminder);
    final time =
        '${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')}';
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surfaceContainer,
          border: Border.all(color: c.outlineVariant, width: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.alarm, color: c.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reminder.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMd(c.onSurface)
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    '$time · ${_recurrenceLabel(s, reminder)}',
                    style: AppTypography.labelSm(c.onSurfaceVariant),
                  ),
                  if (next != null && reminder.enabled)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        s.t('reminders.next_fire')
                            .replaceAll('{n}', _formatNext(next)),
                        style: AppTypography.labelSm(c.outline),
                      ),
                    ),
                ],
              ),
            ),
            Switch(
              value: reminder.enabled,
              onChanged: onToggle,
              activeColor: c.onPrimary,
              activeTrackColor: c.primary,
            ),
          ],
        ),
      ),
    );
  }

  String _recurrenceLabel(AppStrings s, Reminder r) {
    switch (r.recurrence) {
      case ReminderRecurrence.once:
        return s.t('reminders.once_at');
      case ReminderRecurrence.hourly:
        return s.t('reminders.every_n_hours').replaceAll('{n}', '${r.every}');
      case ReminderRecurrence.daily:
        return s.t('reminders.every_n_days').replaceAll('{n}', '${r.every}');
      case ReminderRecurrence.weekly:
        return s.t('reminders.every_n_weeks').replaceAll('{n}', '${r.every}');
    }
  }

  String _formatNext(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    final now = DateTime.now();
    final base = '${two(d.day)}.${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
    return d.year == now.year ? base : '$base.${d.year}';
  }
}
