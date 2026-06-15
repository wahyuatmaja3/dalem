import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class SummaryTab extends StatelessWidget {
  final String summaryMarkdown;

  const SummaryTab({super.key, required this.summaryMarkdown});

  @override
  Widget build(BuildContext context) {
    return Markdown(
      data: summaryMarkdown,
      padding: const EdgeInsets.all(16),
    );
  }
}
