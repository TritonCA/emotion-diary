import 'app_locale.dart';

/// Translations of the static emotion taxonomy (category ids + sub-emotion
/// English names). Custom user-added emotions fall through untouched.
class EmotionTranslations {
  const EmotionTranslations._();

  static String category(AppLocale locale, String categoryId) {
    final table = _categories[locale.code] ?? _categories['ru']!;
    return table[categoryId] ?? _capitalize(categoryId);
  }

  static String emotion(AppLocale locale, String englishName) {
    if (locale == AppLocale.en) return englishName;
    return _ruEmotions[englishName] ?? englishName;
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  static const _categories = <String, Map<String, String>>{
    'ru': {
      'joy': 'Радость',
      'calm': 'Спокойствие',
      'love': 'Любовь',
      'interest': 'Интерес',
      'sadness': 'Грусть',
      'anger': 'Гнев',
      'fear': 'Страх',
      'surprise': 'Удивление',
      'tiredness': 'Усталость',
    },
    'en': {
      'joy': 'Joy',
      'calm': 'Calm',
      'love': 'Love',
      'interest': 'Interest',
      'sadness': 'Sadness',
      'anger': 'Anger',
      'fear': 'Fear',
      'surprise': 'Surprise',
      'tiredness': 'Tiredness',
    },
  };

  static const _ruEmotions = <String, String>{
    // Joy
    'Happy': 'Счастье',
    'Excited': 'Воодушевление',
    'Grateful': 'Благодарность',
    'Content': 'Удовлетворение',
    'Proud': 'Гордость',
    'Hopeful': 'Надежда',
    // Calm
    'Relaxed': 'Расслабленность',
    'Peaceful': 'Умиротворение',
    'Steady': 'Уравновешенность',
    'Safe': 'Безопасность',
    'Relieved': 'Облегчение',
    // Love
    'Tender': 'Нежность',
    'Affectionate': 'Привязанность',
    'Warm': 'Тепло',
    'Trusting': 'Доверие',
    'Close': 'Близость',
    // Interest
    'Curious': 'Любопытство',
    'Engaged': 'Увлечённость',
    'Inspired': 'Вдохновение',
    'Focused': 'Сосредоточенность',
    'Intrigued': 'Заинтригованность',
    // Sadness
    'Down': 'Подавленность',
    'Lonely': 'Одиночество',
    'Disappointed': 'Разочарование',
    'Hopeless': 'Безнадёжность',
    'Empty': 'Опустошённость',
    'Regretful': 'Сожаление',
    // Anger
    'Annoyed': 'Раздражение',
    'Furious': 'Ярость',
    'Bitter': 'Обида',
    'Frustrated': 'Досада',
    'Resentful': 'Негодование',
    // Fear
    'Anxious': 'Тревога',
    'Worried': 'Беспокойство',
    'Scared': 'Испуг',
    'Nervous': 'Нервозность',
    'Insecure': 'Неуверенность',
    'Panicked': 'Паника',
    // Surprise
    'Amazed': 'Изумление',
    'Confused': 'Замешательство',
    'Startled': 'Вздрог',
    'Shocked': 'Шок',
    // Tiredness
    'Exhausted': 'Истощение',
    'Bored': 'Скука',
    'Apathetic': 'Апатия',
    'Drained': 'Опустошённость',
    'Burned out': 'Выгорание',
  };
}
