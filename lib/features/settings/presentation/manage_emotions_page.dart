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

/// Lists the emotion taxonomy and lets the user append custom emotions
/// to a category (persisted via the catalog repository).
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

  Future<void> _addEmotion(EmotionCategory cat) async {
    final c = context.colors;
    final s = context.s;
    final locale = context.read<SettingsCubit>().state.locale;
    final controller = TextEditingController();
    try {
      final name = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: c.surfaceContainer,
          title: Text(
              s.t('manage.add_to').replaceAll(
                  '{n}', EmotionTranslations.category(locale, cat.id)),
              style: AppTypography.headlineMd(c.onSurface)),
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
                child: Text(s.t('common.add'),
                    style: AppTypography.labelSm(c.primary))),
          ],
        ),
      );
      if (name != null && name.isNotEmpty) {
        await _repo.addCustomEmotion(cat.id, name);
        if (!mounted) return;
        await _load();
      }
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: c.surfaceContainer,
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(color: c.outlineVariant, width: 0.5),
                                ),
                                child: Text(
                                    EmotionTranslations.emotion(locale, e),
                                    style: AppTypography.labelSm(c.onSurface)),
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
