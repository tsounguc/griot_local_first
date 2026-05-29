double calculateMemoryImportance(String input) {
  final lower = input.toLowerCase();

  if (lower.contains('my name is')) return 1.0;
  if (lower.contains('my goal')) return 0.95;
  if (lower.contains('i want')) return 0.85;
  if (lower.contains('from now on')) return 0.9;
  if (lower.contains('griot should')) return 0.9;
  if (lower.contains('i prefer')) return 0.8;
  if (lower.contains('remember')) return 0.75;
  return 0.5;
}
