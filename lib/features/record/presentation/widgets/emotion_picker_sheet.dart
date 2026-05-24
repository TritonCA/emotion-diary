import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/l10n/emotion_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/emotion_icons.dart';
import '../../../entries/domain/entities/emotion.dart';
import '../../../entries/domain/entities/emotion_category.dart';
import '../../../settings/application/settings_cubit.dart';

/// "How are you feeling?" bottom sheet. Level 1: category grid + search.
/// Level 2: sub-emotion checkboxes with "Select all". Returns chosen emotions.
Future<List<Emotion>?> showEmotionPicker(
  BuildContext context, {
  required List<EmotionCategory> catalog,
  required List<Emotion> initial,
}) {
  return showModalBottomSheet<List<Emotion>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (_) => _EmotionPickerSheet(catalog: catalog, initial: initial),
  );
}

class _EmotionPickerSheet extends StatefulWidget {
  const _EmotionPickerSheet({required this.catalog, required this.initial});
  final List<EmotionCategory> catalog;
  final List<Emotion> initial;

  @override
  State<_EmotionPickerSheet> createState() => _EmotionPickerSheetState();
}

class _EmotionPickerSheetState extends State<_EmotionPickerSheet> {
  final Map<String, Emotion> _selected = {};
  EmotionCategory? _category;
  String _query = '';

  @override
  void initState() {
    super.initState();
    for (final e in widget.initial) {
      _selected[e.name] = e;
    }
  }

  Emotion _emotionOf(EmotionCategory cat, String name) =>
      Emotion(name: name, categoryId: cat.id, valence: cat.valence);

  void _toggle(EmotionCategory cat, String name) {
    setState(() {
      if (_selected.containsKey(name)) {
        _selected.remove(name);
      } else {
        _selected[name] = _emotionOf(cat, name);
      }
    });
  }

  void _selectAll(EmotionCategory cat) {
    setState(() {
      for (final name in cat.emotions) {
        _selected[name] = _emotionOf(cat, name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.85,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 6,
            decoration: BoxDecoration(
                color: c.outlineVariant, borderRadius: BorderRadius.circular(99)),
          ),
          const SizedBox(height: 8),
          Expanded(child: _category == null ? _level1(c) : _level2(c, _category!)),
        ],
      ),
    );
  }

  Widget _level1(AppColors c) {
    final locale = context.watch<SettingsCubit>().state.locale;
    final s = context.s;
    final filter = _query.trim().toLowerCase();
    bool matches(EmotionCategory cat) {
      final catName = EmotionTranslations.category(locale, cat.id).toLowerCase();
      if (catName.contains(filter)) return true;
      if (cat.name.toLowerCase().contains(filter)) return true;
      for (final e in cat.emotions) {
        if (e.toLowerCase().contains(filter)) return true;
        if (EmotionTranslations.emotion(locale, e).toLowerCase().contains(filter)) {
          return true;
        }
      }
      return false;
    }

    final visible =
        filter.isEmpty ? widget.catalog : widget.catalog.where(matches).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(s.t('picker.how_are_you'),
              style: AppTypography.headlineLg(c.onSurface)),
          const SizedBox(height: 16),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            style: AppTypography.bodyMd(c.onSurface),
            decoration: InputDecoration(
              hintText: s.t('picker.search_hint'),
              hintStyle: AppTypography.bodyMd(c.outline),
              prefixIcon: Icon(Icons.search, color: c.outline, size: 20),
              filled: true,
              fillColor: c.surfaceContainer,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(99),
                borderSide: BorderSide(color: c.outlineVariant, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(99),
                borderSide: BorderSide(color: c.outlineVariant, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(99),
                borderSide: BorderSide(color: c.primary, width: 1),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
              children: [
                for (final cat in visible)
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _category = cat),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: c.outlineVariant, width: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(EmotionIcons.forCategory(cat.iconName),
                              color: c.primary, size: 32),
                          const SizedBox(height: 4),
                          Text(EmotionTranslations.category(locale, cat.id),
                              style: AppTypography.labelSm(c.onSurface)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _level2(AppColors c, EmotionCategory cat) {
    final locale = context.watch<SettingsCubit>().state.locale;
    final s = context.s;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _category = null),
                icon: Icon(Icons.arrow_back, color: c.onSurface),
              ),
              Text(EmotionTranslations.category(locale, cat.id),
                  style: AppTypography.headlineMd(c.onSurface)),
              const Spacer(),
              TextButton(
                onPressed: () => _selectAll(cat),
                child: Text(s.t('picker.select_all'),
                    style: AppTypography.labelSm(c.primary)),
              ),
            ],
          ),
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final e in _selected.values)
                    GestureDetector(
                      onTap: () => _toggle(cat, e.name),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: c.primary, borderRadius: BorderRadius.circular(99)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(EmotionTranslations.emotion(locale, e.name),
                                style: AppTypography.labelSm(c.onPrimary)),
                            const SizedBox(width: 4),
                            Icon(Icons.close, size: 14, color: c.onPrimary),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: ListView(
              children: [
                for (final name in cat.emotions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _toggle(cat, name),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: c.surfaceContainerLow,
                          border: Border.all(color: c.outlineVariant, width: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text(
                                    EmotionTranslations.emotion(locale, name),
                                    style: AppTypography.bodyMd(c.onSurface))),
                            Icon(
                              _selected.containsKey(name)
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: _selected.containsKey(name)
                                  ? c.primary
                                  : c.outline,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: c.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(99)),
                ),
                onPressed: () =>
                    Navigator.of(context).pop(_selected.values.toList()),
                child: Text(s.t('common.done'),
                    style: AppTypography.headlineMd(c.onPrimary)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
