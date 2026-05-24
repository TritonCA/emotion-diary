import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injector.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/emotion_translations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/emotion_icons.dart';
import '../../entries/domain/entities/emotion_category.dart';
import '../../entries/domain/repositories/emotion_catalog_repository.dart';
import '../application/settings_cubit.dart';

/// Lists the emotion taxonomy and lets the user add, rename or delete
/// entries. Each chip is tappable → opens an edit sheet.
class ManageEmotionsPage extends StatefulWidget {
  const ManageEmotionsPage({super.key});

  @override
  State<ManageEmotionsPage> createState() => _ManageEmotionsPageState();
}

class _ManageEmotionsPageState extends State<ManageEmotionsPage> {
  final EmotionCatalogRepository _repo = sl<EmotionCatalogRepository>();
  List<EmotionCategory> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cats = await _repo.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _loading = false;
    });
  }

  String _displayLabel(String name) {
    // Original base names get translated; user-modified strings are shown as-is.
    final locale = context.read<SettingsCubit>().state.locale;
    return EmotionTranslations.emotion(locale, name);
  }

  Future<void> _addEmotion(EmotionCategory cat) async {
    final s = context.s;
    final locale = context.read<SettingsCubit>().state.locale;
    final name = await _textPrompt(
      title: s.t('manage.add_to').replaceAll(
          '{n}', EmotionTranslations.category(locale, cat.id)),
      initial: '',
      action: s.t('common.add'),
    );
    if (name == null || name.isEmpty) return;
    await _repo.addCustomEmotion(cat.id, name);
    await _load();
  }

  Future<void> _editEmotion(EmotionCategory cat, String emotion) async {
    final s = context.s;
    final c = context.colors;
    final action = await showModalBottomSheet<_ChipAction>(
      context: context,
      backgroundColor: c.surface,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.tune, color: c.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _displayLabel(emotion),
                      style: AppTypography.headlineMd(c.onSurface),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: c.onSurface),
              title: Text(s.t('manage.rename'),
                  style: AppTypography.bodyLg(c.onSurface)),
              onTap: () => Navigator.of(context).pop(_ChipAction.rename),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: c.error),
              title: Text(s.t('manage.delete'),
                  style: AppTypography.bodyLg(c.error)),
              onTap: () => Navigator.of(context).pop(_ChipAction.delete),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    if (action == _ChipAction.rename) {
      final next = await _textPrompt(
        title: s.t('manage.rename'),
        initial: emotion,
        action: s.t('common.save'),
      );
      if (next == null || next.isEmpty || next == emotion) return;
      await _repo.renameEmotion(cat.id, emotion, next);
      await _load();
    } else {
      final confirmed = await _confirmDelete(emotion);
      if (confirmed != true) return;
      await _repo.removeEmotion(cat.id, emotion);
      await _load();
    }
  }

  Future<bool?> _confirmDelete(String emotion) async {
    final c = context.colors;
    final s = context.s;
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surfaceContainer,
        title: Text(
            s.t('manage.delete_confirm').replaceAll('{n}', _displayLabel(emotion)),
            style: AppTypography.headlineMd(c.onSurface)),
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
  }

  Future<String?> _textPrompt({
    required String title,
    required String initial,
    required String action,
  }) async {
    final c = context.colors;
    final s = context.s;
    final controller = TextEditingController(text: initial);
    try {
      return await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: c.surfaceContainer,
          title: Text(title, style: AppTypography.headlineMd(c.onSurface)),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 60,
            style: AppTypography.bodyMd(c.onSurface),
            decoration:
                InputDecoration(hintText: s.t('manage.emotion_name_hint')),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(s.t('common.cancel'),
                    style: AppTypography.labelSm(c.onSurfaceVariant))),
            TextButton(
                onPressed: () => Navigator.of(context).pop(controller.text.trim()),
                child: Text(action, style: AppTypography.labelSm(c.primary))),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final locale = context.watch<SettingsCubit>().state.locale;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: c.onSurface),
        title: Text(s.t('manage.title'),
            style: AppTypography.headlineMd(c.primary)
                .copyWith(fontWeight: FontWeight.w700)),
        shape: Border(bottom: BorderSide(color: c.outlineVariant, width: 0.5)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final cat in _categories)
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: Icon(EmotionIcons.forCategory(cat.iconName),
                          color: c.primary),
                      title: Text(EmotionTranslations.category(locale, cat.id),
                          style: AppTypography.bodyLg(c.onSurface)),
                      childrenPadding: const EdgeInsets.only(left: 16, bottom: 8),
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final e in cat.emotions)
                              _EmotionChip(
                                label: EmotionTranslations.emotion(locale, e),
                                onTap: () => _editEmotion(cat, e),
                              ),
                            ActionChip(
                              avatar: Icon(Icons.add, size: 16, color: c.primary),
                              label: Text(s.t('common.add'),
                                  style: AppTypography.labelSm(c.primary)),
                              backgroundColor: c.surface,
                              side: BorderSide(color: c.primary, width: 0.5),
                              onPressed: () => _addEmotion(cat),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

enum _ChipAction { rename, delete }

class _EmotionChip extends StatelessWidget {
  const _EmotionChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: c.surfaceContainer,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: c.outlineVariant, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTypography.labelSm(c.onSurface)),
            const SizedBox(width: 6),
            Icon(Icons.more_horiz, size: 14, color: c.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
