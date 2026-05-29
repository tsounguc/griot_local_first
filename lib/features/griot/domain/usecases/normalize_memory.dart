String normalizeMemory(String input) {
  final trimmed = input.trim();

  final lower = trimmed.toLowerCase();

  if (lower.startsWith('remember my name is ')) {
    final name = trimmed.substring('remember my name is '.length).trim();
    return 'The user\'s name is $name.';
  }

  if (lower.startsWith('my name is ')) {
    final name = trimmed.substring('my name is '.length).trim();
    return 'The user\'s name is $name.';
  }

  if (lower.contains('i want griot')) {
    return trimmed
        .replaceAll(RegExp(r'\bI want\b', caseSensitive: false), 'The user wants')
        .replaceAll(RegExp(r'\bmy\b', caseSensitive: false), 'the user\'s');
  }

  return 'User said: $trimmed';
}