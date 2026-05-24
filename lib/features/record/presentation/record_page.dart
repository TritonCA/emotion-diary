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
import '../../settings/application/settings_cubit.dart';
import '../application/record_cubit.dart';
import '../application/record_state.dart';
import 'widgets/emotion_picker_sheet.dart';
import 'widgets/intensity_viz.dart';

class RecordPage extends StatelessWidget {
  const RecordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RecordCubit>(
      create: (_) => sl<RecordCubit>()..init(),
      child: const _RecordView(),
    );
  }
}

class _RecordView extends StatefulWidget {
  const _RecordView();
  @override
  State<_RecordView> createState() => _RecordViewState();
}

class _RecordViewState extends State<_RecordView> {
  final _triggerCtrl = TextEditingController();

  @override
  void dispose() {
    _triggerCtrl.dispose();
    super.dispose();
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
    return Scaffold(
      appBar: AppTopBar(title: s.t('record.title')),
      body: BlocConsumer<RecordCubit, RecordState>(
        listenWhen: (a, b) => a.savedTick != b.savedTick,
        listener: (context, state) {
          _triggerCtrl.clear();
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(context.s.t('record.saved'))));
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
              const SizedBox(height: 12),
              Center(
                child: Text(s.t('record.history_footer'),
                    style: AppTypography.labelSm(c.onSurfaceVariant)),
              ),
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
      final result = await showEmotionPicker(context,
          catalog: s.catalog, initial: s.selected);
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
          Slider(
            value: s.intensity.toDouble(),
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
        ],
      ),
    );
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
        child: Text(context.s.t('record.save_entry'),
            style: AppTypography.headlineMd(c.onPrimary)),
      ),
    );
  }
}
