import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injector.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/emotion_translations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/section_label.dart';
import '../../entries/domain/entities/emotion.dart';
import '../../entries/domain/entities/mood_entry.dart';
import '../../settings/application/settings_cubit.dart';
import '../application/record_cubit.dart';
import '../application/record_state.dart';
import 'widgets/emotion_picker_sheet.dart';
import 'widgets/intensity_viz.dart';

/// Single screen used both for creating a new entry (bottom-nav tab) and
/// for editing an existing one (pushed from History with [existing] set).
class RecordPage extends StatelessWidget {
  const RecordPage({super.key, this.existing});
  final MoodEntry? existing;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RecordCubit>(
      create: (_) {
        final cubit = sl<RecordCubit>();
        if (existing != null) {
          cubit.loadExisting(existing!);
        } else {
          cubit.init();
        }
        return cubit;
      },
      child: _RecordView(initialTrigger: existing?.trigger ?? ''),
    );
  }
}

class _RecordView extends StatefulWidget {
  const _RecordView({this.initialTrigger = ''});
  final String initialTrigger;
  @override
  State<_RecordView> createState() => _RecordViewState();
}

class _RecordViewState extends State<_RecordView> with WidgetsBindingObserver {
  late final TextEditingController _triggerCtrl;
  int _lastSavedTick = 0;
  int _lastDeletedTick = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _triggerCtrl = TextEditingController(text: widget.initialTrigger);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh catalog when the app comes back to the foreground so renames /
    // deletes from Manage Emotions are reflected in the picker.
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<RecordCubit>().reloadCatalog();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _triggerCtrl.dispose();
    super.dispose();
  }

  PreferredSizeWidget _editAppBar(BuildContext context, AppColors c, AppStrings s) {
    return AppBar(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: BackButton(color: c.onSurface),
      title: Text(s.t('record.edit_title'),
          style: AppTypography.headlineMd(c.primary)
              .copyWith(fontWeight: FontWeight.w700)),
      shape: Border(bottom: BorderSide(color: c.outlineVariant, width: 0.5)),
      actions: [
        IconButton(
          tooltip: s.t('common.delete'),
          icon: Icon(Icons.delete_outline, color: c.error),
          onPressed: () => _confirmDelete(context),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final c = context.colors;
    final s = context.s;
    final cubit = context.read<RecordCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surfaceContainer,
        title: Text(s.t('record.delete_confirm.title'),
            style: AppTypography.headlineMd(c.onSurface)),
        content: Text(s.t('record.delete_confirm.body'),
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
    if (ok == true) {
      await cubit.deleteCurrent();
    }
  }

  Future<void> _pickDateTime(BuildContext context, RecordState s) async {
    final cubit = context.read<RecordCubit>();
    final date = await showDatePicker(
      context: context,
      initialDate: s.timestamp,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(s.timestamp),
    );
    final picked = DateTime(date.year, date.month, date.day,
        time?.hour ?? s.timestamp.hour, time?.minute ?? s.timestamp.minute);
    cubit.setTimestamp(picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final isEditing = context.watch<RecordCubit>().state.isEditing;
    return Scaffold(
      appBar: isEditing ? _editAppBar(context, c, s) : AppTopBar(title: s.t('record.title')),
      body: BlocConsumer<RecordCubit, RecordState>(
        listenWhen: (a, b) =>
            a.savedTick != b.savedTick || a.deletedTick != b.deletedTick,
        listener: (context, state) {
          // Deletion fires first — pop the route and surface a snack on the
          // parent so the History list shows the result.
          if (state.deletedTick != _lastDeletedTick) {
            _lastDeletedTick = state.deletedTick;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(context.s.t('record.deleted'))));
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            return;
          }
          if (state.savedTick != _lastSavedTick) {
            _lastSavedTick = state.savedTick;
            final msg = state.isEditing
                ? context.s.t('record.updated')
                : context.s.t('record.saved');
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(msg)));
            if (state.isEditing) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            } else {
              _triggerCtrl.clear();
            }
          }
        },
        builder: (context, state) {
          final cubit = context.read<RecordCubit>();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
            children: [
              _dateCard(context, state),
              const SizedBox(height: 40),
              SectionLabel(s.t('record.current_emotions')),
              const SizedBox(height: 16),
              _emotionsSection(context, state, cubit),
              const SizedBox(height: 40),
              _intensityCard(context, state, cubit),
              const SizedBox(height: 40),
              SectionLabel(s.t('record.what_happened')),
              const SizedBox(height: 16),
              _triggerField(context, c, cubit),
              const SizedBox(height: 40),
              _saveButton(context, c, state, cubit),
              if (!state.isEditing) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(s.t('record.history_footer'),
                      style: AppTypography.labelSm(c.onSurfaceVariant)),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _dateCard(BuildContext context, RecordState s) {
    final c = context.colors;
    final locale = context.watch<SettingsCubit>().state.locale;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _pickDateTime(context, s),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surfaceContainer,
          border: Border.all(color: c.outlineVariant, width: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.event, color: c.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
                s.isNow
                    ? context.s.t('common.now')
                    : DateFormatter.fullDate(s.timestamp, locale: locale),
                style: AppTypography.bodyLg(c.onSurface)),
            const Spacer(),
            Icon(Icons.chevron_right, color: c.outline),
          ],
        ),
      ),
    );
  }

  Widget _emotionsSection(BuildContext context, RecordState s, RecordCubit cubit) {
    final c = context.colors;
    final locale = context.watch<SettingsCubit>().state.locale;
    Future<void> openPicker() async {
      // Pull a fresh catalog in case the user renamed / removed emotions in
      // Settings since this screen was first built.
      await cubit.reloadCatalog();
      if (!context.mounted) return;
      final result = await showEmotionPicker(context,
          catalog: cubit.state.catalog, initial: cubit.state.selected);
      if (result != null) cubit.confirmEmotions(result);
    }

    if (s.selected.isEmpty) {
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: openPicker,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: c.outline, width: 0.5, style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: c.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(context.s.t('record.add_emotion'),
                  style: AppTypography.bodyMd(c.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final e in s.selected)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: c.surfaceContainer,
              border: Border.all(color: c.outline, width: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(EmotionTranslations.emotion(locale, e.name),
                    style: AppTypography.bodyMd(c.onSurface)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => cubit.removeEmotion(e),
                  child: Icon(Icons.close, size: 18, color: c.outline),
                ),
              ],
            ),
          ),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: openPicker,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              border: Border.all(color: c.outlineVariant, width: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.add, color: c.outline),
          ),
        ),
      ],
    );
  }

  Widget _intensityCard(BuildContext context, RecordState s, RecordCubit cubit) {
    final c = context.colors;
    final multi = s.selected.length > 1;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.surfaceContainer,
        border: Border.all(color: c.outlineVariant, width: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SectionLabel(context.s.t('record.intensity')),
              Text('${s.intensity}', style: AppTypography.display(c.primary)),
            ],
          ),
          const SizedBox(height: 8),
          IntensityViz(intensity: s.intensity, selected: s.selected),
          if (!multi) ...[
            Slider(
              value: _singleSliderValue(s).toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              onChanged: (v) => cubit.setIntensity(v.round()),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.s.t('record.mild'),
                    style: AppTypography.labelSm(c.outline)),
                Text(context.s.t('record.intense'),
                    style: AppTypography.labelSm(c.outline)),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(context.s.t('record.per_emotion_intensity'),
                style: AppTypography.labelSm(c.onSurfaceVariant)
                    .copyWith(letterSpacing: 1.0)),
            const SizedBox(height: 8),
            for (final emotion in s.selected)
              _PerEmotionSlider(
                emotion: emotion,
                value: s.intensities[emotion.name] ?? s.intensity,
                onChanged: (v) => cubit.setEmotionIntensity(emotion.name, v),
              ),
          ],
        ],
      ),
    );
  }

  int _singleSliderValue(RecordState s) {
    if (s.selected.length == 1) {
      return s.intensities[s.selected.first.name] ?? s.intensity;
    }
    return s.intensity;
  }

  Widget _triggerField(BuildContext context, AppColors c, RecordCubit cubit) {
    return TextField(
      controller: _triggerCtrl,
      onChanged: cubit.setTrigger,
      minLines: 4,
      maxLines: 8,
      style: AppTypography.bodyMd(c.onSurface),
      decoration: InputDecoration(
        hintText: context.s.t('record.trigger_hint'),
        hintStyle: AppTypography.bodyMd(c.outline),
        filled: true,
        fillColor: c.surface,
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
    );
  }

  Widget _saveButton(
      BuildContext context, AppColors c, RecordState s, RecordCubit cubit) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        ),
        onPressed: s.saving ? null : cubit.save,
        child: Text(
            s.isEditing
                ? context.s.t('record.save_changes')
                : context.s.t('record.save_entry'),
            style: AppTypography.headlineMd(c.onPrimary)),
      ),
    );
  }
}

class _PerEmotionSlider extends StatelessWidget {
  const _PerEmotionSlider({
    required this.emotion,
    required this.value,
    required this.onChanged,
  });
  final Emotion emotion;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final locale = context.watch<SettingsCubit>().state.locale;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              EmotionTranslations.emotion(locale, emotion.name),
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMd(c.onSurface)
                  .copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: AppTypography.bodyMd(c.primary)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
