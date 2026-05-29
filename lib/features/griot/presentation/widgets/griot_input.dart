import 'package:flutter/material.dart';

class GriotInput extends StatefulWidget {
  const GriotInput({
    super.key,
    required this.onSubmitted,
    this.isLoading = false,
  });

  final ValueChanged<String> onSubmitted;
  final bool isLoading;

  @override
  State<GriotInput> createState() => _GriotInputState();
}

class _GriotInputState extends State<GriotInput> {
  final TextEditingController _controller = TextEditingController();

  void _submit() {
    final input = _controller.text.trim();

    if (input.isEmpty || widget.isLoading) return;

    widget.onSubmitted(input);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 5,
                enabled: !widget.isLoading,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'Ask GRIOT anything...',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: widget.isLoading ? null : _submit,
              icon: widget.isLoading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}