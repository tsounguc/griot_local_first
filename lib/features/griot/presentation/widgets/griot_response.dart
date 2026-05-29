import 'package:flutter/material.dart';

class GriotResponse extends StatelessWidget {
  const GriotResponse({
    super.key,
    required this.response,
  });

  final String response;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (response.trim().isEmpty) {
      return Center(
        child: Text(
          'GRIOT is ready.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.topLeft,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
          ),
          child: SelectableText(
            response,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}