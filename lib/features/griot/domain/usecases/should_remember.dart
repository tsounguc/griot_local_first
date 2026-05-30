bool shouldRemember(String input) {
  final lower = input.toLowerCase();

  return lower.contains('my name is') ||
      lower.contains('remember') ||
      lower.contains('my goal') ||
      lower.contains('i want') ||
      lower.contains('from now on') ||
      lower.contains('griot should');
}
