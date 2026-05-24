import 'package:equatable/equatable.dart';

/// Emotional valence used for the Stats donut and the Record visualization.
enum Valence { positive, neutral, negative }

/// A top-level emotion category (Joy, Calm, ...). Mirrors the bottom-sheet grid.
/// `iconName` is a logical key resolved to an [IconData] in presentation,
/// keeping the domain free of any Flutter import.
class EmotionCategory extends Equatable {
  const EmotionCategory({
    required this.id,
    required this.name,
    required this.iconName,
    required this.valence,
    required this.emotions,
  });

  final String id;
  final String name;
  final String iconName;
  final Valence valence;
  final List<String> emotions;

  EmotionCategory copyWith({List<String>? emotions}) => EmotionCategory(
        id: id,
        name: name,
        iconName: iconName,
        valence: valence,
        emotions: emotions ?? this.emotions,
      );

  @override
  List<Object?> get props => [id, name, iconName, valence, emotions];
}
