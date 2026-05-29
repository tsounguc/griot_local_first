import 'package:flutter/material.dart';

class GriotLoadingIndicator extends StatelessWidget {
  const GriotLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}