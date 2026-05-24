import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/emotion.dart';
import '../../domain/entities/emotion_category.dart';
import '../../domain/entities/mood_entry.dart';
import '../../domain/repositories/entries_csv_gateway.dart';

/// All file-system / share / pick side effects for CSV live here (ARCH:
/// side effects centralized in data/services, never in the UI).
///
/// Emotions are encoded as `name|categoryId|valence|intensity` joined by `;`.
/// The trailing `|intensity` is optional — rows produced by older app
/// versions (without per-emotion intensities) are still parsed correctly,
/// falling back to the row-level intensity for each emotion.
class CsvService implements EntriesCsvGateway {
  const CsvService();

  static const _headers = ['id', 'timestamp', 'emotions', 'intensity', 'trigger'];

  String _encodeEmotion(Emotion e, int intensity) =>
      '${e.name}|${e.categoryId}|${e.valence.name}|$intensity';

  String _build(List<MoodEntry> entries) {
    final rows = <List<dynamic>>[
      _headers,
      ...entries.map((e) => [
            e.id,
            e.timestamp.toIso8601String(),
            [
              for (var i = 0; i < e.emotions.length; i++)
                _encodeEmotion(e.emotions[i], e.intensityFor(i)),
            ].join(';'),
            e.intensity,
            e.trigger,
          ]),
    ];
    return const ListToCsvConverter(eol: '\n').convert(rows);
  }

  @override
  Future<void> exportAndShare(List<MoodEntry> entries) async {
    final csv = _build(entries);
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final file = File('${dir.path}/mood_export_$stamp.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], subject: 'Mood entries export');
  }

  /// Returns parsed entries, or null if the user cancelled the picker.
  @override
  Future<List<MoodEntry>?> pickAndParse() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (res == null || res.files.isEmpty) return null;

    final picked = res.files.single;
    final content = picked.bytes != null
        ? String.fromCharCodes(picked.bytes!)
        : await File(picked.path!).readAsString();

    final rows = const CsvToListConverter(eol: '\n', shouldParseNumbers: false)
        .convert(content);
    if (rows.isEmpty) return [];

    final out = <MoodEntry>[];
    for (var i = 1; i < rows.length; i++) {
      final r = rows[i];
      if (r.length < 5) continue;
      final rowIntensity = int.tryParse(r[3].toString().trim()) ?? 0;
      final parsed = _parseEmotions(r[2].toString(), rowIntensity);
      out.add(MoodEntry(
        id: r[0].toString().isEmpty
            ? DateTime.now().microsecondsSinceEpoch.toString()
            : r[0].toString(),
        timestamp: DateTime.tryParse(r[1].toString()) ?? DateTime.now(),
        emotions: parsed.emotions,
        intensities: parsed.intensities,
        intensity: rowIntensity,
        trigger: r[4].toString(),
      ));
    }
    return out;
  }

  _ParsedEmotions _parseEmotions(String raw, int fallbackIntensity) {
    if (raw.trim().isEmpty) {
      return const _ParsedEmotions(emotions: [], intensities: []);
    }
    final emotions = <Emotion>[];
    final intensities = <int>[];
    for (final token in raw.split(';').where((s) => s.trim().isNotEmpty)) {
      final parts = token.split('|');
      final valence = parts.length > 2
          ? Valence.values.firstWhere((v) => v.name == parts[2],
              orElse: () => Valence.neutral)
          : Valence.neutral;
      final intensity = parts.length > 3
          ? (int.tryParse(parts[3].trim()) ?? fallbackIntensity)
          : fallbackIntensity;
      emotions.add(Emotion(
        name: parts[0],
        categoryId: parts.length > 1 ? parts[1] : '',
        valence: valence,
      ));
      intensities.add(intensity.clamp(0, 10));
    }
    return _ParsedEmotions(emotions: emotions, intensities: intensities);
  }
}

class _ParsedEmotions {
  const _ParsedEmotions({required this.emotions, required this.intensities});
  final List<Emotion> emotions;
  final List<int> intensities;
}
