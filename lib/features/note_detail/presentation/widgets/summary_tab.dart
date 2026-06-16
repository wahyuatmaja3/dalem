import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/constants/app_colors.dart';

class SummaryTab extends StatelessWidget {
  final String summaryMarkdown;

  const SummaryTab({super.key, required this.summaryMarkdown});

  @override
  Widget build(BuildContext context) {
    if (summaryMarkdown.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.summarize_outlined,
                size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            const Text(
              'No summary available',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return Markdown(
      data: summaryMarkdown,
      padding: const EdgeInsets.all(20),
      styleSheet: MarkdownStyleSheet(
        h1: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        h2: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        p: const TextStyle(
          fontSize: 16,
          color: AppColors.textPrimary,
          height: 1.6,
        ),
        listBullet: const TextStyle(
          fontSize: 16,
          color: AppColors.primary,
        ),
        strong: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
