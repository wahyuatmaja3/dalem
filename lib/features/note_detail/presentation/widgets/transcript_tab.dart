import 'package:flutter/material.dart';

class TranscriptTab extends StatelessWidget {
  final String transcript;

  const TranscriptTab({super.key, required this.transcript});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        transcript,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
