import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../application/reminders_cubit.dart';
import '../domain/entities/reminder.dart';

/// New / edit form for a reminder. Keeps form state locally; commits via the
/// shared [RemindersCubit] on Save.
class EditReminderPage extends StatefulWidget {
  const EditReminderPage({super.key, this.existing});
  final Reminder? existing;

  @override
  State<EditReminderPage> createState() => _EditReminderPageState();
}

class _EditReminderPageState extends State<EditReminderPage> {
  late final TextEditingController _text;
  late TimeOfDay _time;
  late ReminderRecurrence _rec;
  late int _every;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _text = TextEditingController(text: e?.text ?? '');
    _time = e == null
        ? const TimeOfDay(hour: 9, minute: 0)
        : TimeOfDay(hour: e.hour, minute: e.minute);
    _rec = e?.recurrence ?? ReminderRecurrence.daily;
    _every = e?.every ?? 1;
    _enabled = e?.enabled ?? true;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final s = context.s;
    final cubit = context.read<RemindersCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final text = _text.text.trim().isEmpty
        ? s.t('reminders.default_text')
        : _text.text.trim();
    final every = _every.clamp(1, 365);

    // Preserve the existing anchor when nothing schedule-relevant changed —
    // otherwise editing just the text would reset the N-interval cadence.
    final existing = widget.existing;
    final recomputeAnchor = existing == null ||
        existing.anchor == null ||
        existing.hour != _time.hour ||
        existing.minute != _time.minute ||
        existing.recurrence != _rec ||
        existing.every != every;
    final anchor = recomputeAnchor
        ? _computeAnchor(_time.hour, _time.minute)
        : existing.anchor;

    final reminder = Reminder(
      id: existing?.id ?? cubit.nextId(),
      text: text,
      hour: _time.hour,
      minute: _time.minute,
      recurrence: _rec,
      every: every,
      enabled: _enabled,
      anchor: anchor,
    );
    try {
      await cubit.upsert(reminder);
    } catch (_) {
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(s.t('reminders.save_failed'))));
      return;
    }
    if (mounted) navigator.pop();
  }

  DateTime _computeAnchor(int hour, int minute) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, hour, minute);
    return today.isAfter(now) ? today : today.add(const Duration(days: 1));
  }

  Future<void> _delete() async {
    final s = context.s;
    final c = context.colors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surfaceContainer,
        title: Text(s.t('reminders.delete_confirm.title'),
            style: AppTypography.headlineMd(c.onSurface)),
        content: Text(s.t('reminders.delete_confirm.body'),
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
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final cubit = context.read<RemindersCubit>();
    try {
      await cubit.delete(widget.existing!.id);
    } catch (_) {
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(s.t('reminders.save_failed'))));
      return;
    }
    if (mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final isNew = widget.existing == null;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: c.onSurface),
        title: Text(
          isNew ? s.t('reminders.edit.title.new') : s.t('reminders.edit.title.edit'),
          style: AppTypography.headlineMd(c.primary)
              .copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (!isNew)
            IconButton(
              tooltip: s.t('common.delete'),
              icon: Icon(Icons.delete_outline, color: c.error),
              onPressed: _delete,
            ),
        ],
        shape: Border(bottom: BorderSide(color: c.outlineVariant, width: 0.5)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          _label(c, s.t('reminders.text')),
          const SizedBox(height: 8),
          TextField(
            controller: _text,
            maxLines: 3,
            minLines: 2,
            maxLength: 200,
            style: AppTypography.bodyMd(c.onSurface),
            decoration: InputDecoration(
              hintText: s.t('reminders.default_text'),
              hintStyle: AppTypography.bodyMd(c.outline),
              filled: true,
              fillColor: c.surfaceContainer,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.outlineVariant, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.outlineVariant, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.primary, width: 1),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _label(c, s.t('reminders.time')),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _pickTime,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.surfaceContainer,
                border: Border.all(color: c.outlineVariant, width: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: c.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Text(
                    '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                    style: AppTypography.bodyLg(c.onSurface),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: c.outline),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _label(c, s.t('reminders.recurrence')),
          const SizedBox(height: 8),
          _recurrenceSelector(c, s),
          if (_rec != ReminderRecurrence.once) ...[
            const SizedBox(height: 16),
            _label(c, s.t('reminders.interval')),
            const SizedBox(height: 8),
            _intervalStepper(c),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: c.surfaceContainer,
              border: Border.all(color: c.outlineVariant, width: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.toggle_on_outlined, color: c.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(s.t('reminders.enabled'),
                      style: AppTypography.bodyMd(c.onSurface)),
                ),
                Switch(
                  value: _enabled,
                  onChanged: (v) => setState(() => _enabled = v),
                  activeColor: c.onPrimary,
                  activeTrackColor: c.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: c.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
              ),
              onPressed: _save,
              child: Text(s.t('common.save'),
                  style: AppTypography.headlineMd(c.onPrimary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(AppColors c, String text) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(text.toUpperCase(),
            style: AppTypography.labelSm(c.onSurfaceVariant)
                .copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w600)),
      );

  Widget _recurrenceSelector(AppColors c, AppStrings s) {
    final items = <_RecOption>[
      _RecOption(ReminderRecurrence.once, s.t('reminders.recurrence.once')),
      _RecOption(ReminderRecurrence.hourly, s.t('reminders.recurrence.hourly')),
      _RecOption(ReminderRecurrence.daily, s.t('reminders.recurrence.daily')),
      _RecOption(ReminderRecurrence.weekly, s.t('reminders.recurrence.weekly')),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final opt in items)
          GestureDetector(
            onTap: () => setState(() => _rec = opt.value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _rec == opt.value
                    ? c.primary.withOpacity(0.12)
                    : c.surfaceContainer,
                border: Border.all(
                    color: _rec == opt.value ? c.primary : c.outlineVariant,
                    width: _rec == opt.value ? 1 : 0.5),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                opt.label,
                style: AppTypography.labelSm(
                    _rec == opt.value ? c.primary : c.onSurfaceVariant),
              ),
            ),
          ),
      ],
    );
  }

  Widget _intervalStepper(AppColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: c.surfaceContainer,
        border: Border.all(color: c.outlineVariant, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.repeat, color: c.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text('$_every', style: AppTypography.bodyLg(c.onSurface)),
          ),
          IconButton(
            onPressed: _every > 1 ? () => setState(() => _every--) : null,
            icon: Icon(Icons.remove_circle_outline,
                color: _every > 1 ? c.primary : c.outline),
          ),
          IconButton(
            onPressed: _every < 365 ? () => setState(() => _every++) : null,
            icon: Icon(Icons.add_circle_outline,
                color: _every < 365 ? c.primary : c.outline),
          ),
        ],
      ),
    );
  }
}

class _RecOption {
  const _RecOption(this.value, this.label);
  final ReminderRecurrence value;
  final String label;
}
