import 'package:equatable/equatable.dart';
import 'emotion_category.dart';

/// A concrete chosen emotion, tagged with the category it came from.
class Emotion extends Equatable {
  const Emotion({
    required this.name,
    required this.categoryId,
    required this.valence,
  });

  final String name;
  final String categoryId;
  final Valence valence;

  @override
  List<Object?> get props => [name, categoryId];
}
