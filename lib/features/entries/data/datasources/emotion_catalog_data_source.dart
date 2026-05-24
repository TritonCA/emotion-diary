import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/storage/key_value_store.dart';
import '../../domain/entities/emotion_category.dart';

/// Static emotion taxonomy merged with the user's overrides. The override
/// store keeps three lists per category id:
///   - `add`: extra emotion names the user appended
///   - `omit`: base emotion names the user hid
///   - `rename`: { originalBaseName -> newName } map
class EmotionCatalogDataSource {
  EmotionCatalogDataSource(this._store);
  final KeyValueStore _store;

  static const _overridesKey = 'emotion_overrides.v1';
  // Legacy pre-rename/delete store. Migrated lazily on first read.
  static const _legacyAddKey = 'custom_emotions.v1';

  static const List<EmotionCategory> _base = [
    EmotionCategory(id: 'joy', name: 'Joy', iconName: 'joy', valence: Valence.positive,
        emotions: ['Happy', 'Excited', 'Grateful', 'Content', 'Proud', 'Hopeful']),
    EmotionCategory(id: 'calm', name: 'Calm', iconName: 'calm', valence: Valence.positive,
        emotions: ['Relaxed', 'Peaceful', 'Steady', 'Safe', 'Relieved']),
    EmotionCategory(id: 'love', name: 'Love', iconName: 'love', valence: Valence.positive,
        emotions: ['Tender', 'Affectionate', 'Warm', 'Trusting', 'Close']),
    EmotionCategory(id: 'interest', name: 'Interest', iconName: 'interest', valence: Valence.positive,
        emotions: ['Curious', 'Engaged', 'Inspired', 'Focused', 'Intrigued']),
    EmotionCategory(id: 'sadness', name: 'Sadness', iconName: 'sadness', valence: Valence.negative,
        emotions: ['Down', 'Lonely', 'Disappointed', 'Hopeless', 'Empty', 'Regretful']),
    EmotionCategory(id: 'anger', name: 'Anger', iconName: 'anger', valence: Valence.negative,
        emotions: ['Annoyed', 'Furious', 'Bitter', 'Frustrated', 'Resentful']),
    EmotionCategory(id: 'fear', name: 'Fear', iconName: 'fear', valence: Valence.negative,
        emotions: ['Anxious', 'Worried', 'Scared', 'Nervous', 'Insecure', 'Panicked']),
    EmotionCategory(id: 'surprise', name: 'Surprise', iconName: 'surprise', valence: Valence.neutral,
        emotions: ['Amazed', 'Confused', 'Startled', 'Shocked']),
    EmotionCategory(id: 'tiredness', name: 'Tiredness', iconName: 'tiredness', valence: Valence.negative,
        emotions: ['Exhausted', 'Bored', 'Apathetic', 'Drained', 'Burned out']),
  ];

  Future<_OverridesMap> _readOverrides() async {
    final raw = await _store.getString(_overridesKey);
    if (raw == null || raw.isEmpty) {
      // Migrate from the legacy "add-only" store if present.
      final legacy = await _store.getString(_legacyAddKey);
      if (legacy != null && legacy.isNotEmpty) {
        try {
          final decoded = jsonDecode(legacy);
          if (decoded is Map) {
            final migrated = <String, _CategoryOverride>{};
            decoded.forEach((k, v) {
              if (k is String && v is List) {
                migrated[k] = _CategoryOverride(
                  add: v.whereType<String>().toList(),
                  omit: const [],
                  rename: const {},
                );
              }
            });
            final result = _OverridesMap(migrated);
            await _writeOverrides(result);
            await _store.remove(_legacyAddKey);
            return result;
          }
        } catch (e) {
          if (kDebugMode) debugPrint('legacy emotions migration failed: $e');
        }
      }
      return const _OverridesMap({});
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const _OverridesMap({});
      final out = <String, _CategoryOverride>{};
      decoded.forEach((k, v) {
        if (k is! String || v is! Map) return;
        out[k] = _CategoryOverride.fromJson(v.cast<String, dynamic>());
      });
      return _OverridesMap(out);
    } catch (e) {
      if (kDebugMode) debugPrint('emotion overrides parse failed: $e');
      return const _OverridesMap({});
    }
  }

  Future<void> _writeOverrides(_OverridesMap overrides) async {
    await _store.setString(_overridesKey, jsonEncode(overrides.toJson()));
  }

  Future<List<EmotionCategory>> getCategories() async {
    final overrides = await _readOverrides();
    return _base.map((cat) {
      final ov = overrides.forCategory(cat.id);
      final renamed = <String>[
        for (final original in cat.emotions)
          if (!ov.omit.contains(original)) ov.rename[original] ?? original,
      ];
      final added = ov.add.where((e) => !renamed.contains(e)).toList();
      return cat.copyWith(emotions: [...renamed, ...added]);
    }).toList();
  }

  Future<void> addCustom(String categoryId, String emotion) async {
    final name = emotion.trim();
    if (name.isEmpty) return;
    final overrides = await _readOverrides();
    final ov = overrides.forCategory(categoryId);
    if (ov.add.contains(name)) return;
    final next = ov.copyWith(add: [...ov.add, name]);
    await _writeOverrides(overrides.with_(categoryId, next));
  }

  /// Removes an emotion — either a custom addition or a base one (in which
  /// case the base name is added to the `omit` set so it stays hidden across
  /// app launches). Renames are also reset back to the base.
  Future<void> removeEmotion(String categoryId, String displayName) async {
    final overrides = await _readOverrides();
    final ov = overrides.forCategory(categoryId);
    final base = _base.firstWhere((c) => c.id == categoryId,
        orElse: () => const EmotionCategory(
            id: '', name: '', iconName: '', valence: Valence.neutral, emotions: []));

    // Custom-added: drop from `add`.
    if (ov.add.contains(displayName)) {
      final next = ov.copyWith(add: ov.add.where((e) => e != displayName).toList());
      await _writeOverrides(overrides.with_(categoryId, next));
      return;
    }

    // Possibly a renamed base — find the original it maps from.
    final renameSource = ov.rename.entries
        .firstWhere((kv) => kv.value == displayName,
            orElse: () => const MapEntry('', ''))
        .key;
    if (renameSource.isNotEmpty) {
      final rename = Map<String, String>.from(ov.rename)..remove(renameSource);
      final omit = ov.omit.contains(renameSource) ? ov.omit : [...ov.omit, renameSource];
      await _writeOverrides(
          overrides.with_(categoryId, ov.copyWith(rename: rename, omit: omit)));
      return;
    }

    // Base name — only valid if it exists in the static taxonomy.
    if (base.emotions.contains(displayName) && !ov.omit.contains(displayName)) {
      final next = ov.copyWith(omit: [...ov.omit, displayName]);
      await _writeOverrides(overrides.with_(categoryId, next));
    }
  }

  /// Renames an existing emotion. Works for base, renamed-base, or custom
  /// entries. No-op if `newName` is empty, equal to current, or already
  /// present in the category.
  Future<void> renameEmotion(
      String categoryId, String oldName, String newName) async {
    final next = newName.trim();
    if (next.isEmpty || next == oldName) return;
    final overrides = await _readOverrides();
    final ov = overrides.forCategory(categoryId);
    final base = _base.firstWhere((c) => c.id == categoryId,
        orElse: () => const EmotionCategory(
            id: '', name: '', iconName: '', valence: Valence.neutral, emotions: []));

    // Custom: swap in place inside the `add` list.
    if (ov.add.contains(oldName)) {
      if (ov.add.contains(next)) return; // collision — silently ignore
      final list = ov.add.map((e) => e == oldName ? next : e).toList();
      await _writeOverrides(
          overrides.with_(categoryId, ov.copyWith(add: list)));
      return;
    }

    // Renamed-base: find original and update the rename target.
    final renameSource = ov.rename.entries
        .firstWhere((kv) => kv.value == oldName,
            orElse: () => const MapEntry('', ''))
        .key;
    if (renameSource.isNotEmpty) {
      final rename = Map<String, String>.from(ov.rename);
      if (next == renameSource) {
        rename.remove(renameSource);
      } else {
        rename[renameSource] = next;
      }
      await _writeOverrides(
          overrides.with_(categoryId, ov.copyWith(rename: rename)));
      return;
    }

    // Base emotion: add a rename entry.
    if (base.emotions.contains(oldName)) {
      final rename = Map<String, String>.from(ov.rename);
      rename[oldName] = next;
      await _writeOverrides(
          overrides.with_(categoryId, ov.copyWith(rename: rename)));
    }
  }
}

class _OverridesMap {
  const _OverridesMap(this._map);
  final Map<String, _CategoryOverride> _map;

  _CategoryOverride forCategory(String id) => _map[id] ?? _CategoryOverride.empty;

  _OverridesMap with_(String id, _CategoryOverride v) =>
      _OverridesMap({..._map, id: v});

  Map<String, dynamic> toJson() =>
      _map.map((k, v) => MapEntry(k, v.toJson()));
}

class _CategoryOverride {
  const _CategoryOverride({
    required this.add,
    required this.omit,
    required this.rename,
  });

  static const empty = _CategoryOverride(add: [], omit: [], rename: {});

  final List<String> add;
  final List<String> omit;
  final Map<String, String> rename;

  _CategoryOverride copyWith({
    List<String>? add,
    List<String>? omit,
    Map<String, String>? rename,
  }) =>
      _CategoryOverride(
        add: add ?? this.add,
        omit: omit ?? this.omit,
        rename: rename ?? this.rename,
      );

  factory _CategoryOverride.fromJson(Map<String, dynamic> j) => _CategoryOverride(
        add: ((j['add'] as List?) ?? const []).whereType<String>().toList(),
        omit: ((j['omit'] as List?) ?? const []).whereType<String>().toList(),
        rename: ((j['rename'] as Map?) ?? const {}).map(
            (k, v) => MapEntry(k.toString(), v.toString())),
      );

  Map<String, dynamic> toJson() => {
        if (add.isNotEmpty) 'add': add,
        if (omit.isNotEmpty) 'omit': omit,
        if (rename.isNotEmpty) 'rename': rename,
      };
}
