import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class SummaryTab extends StatelessWidget {
  final String? summaryMarkdown;
  final bool isGenerating;
  final VoidCallback? onGenerateSummary;

  const SummaryTab({
    super.key,
    required this.summaryMarkdown,
    this.isGenerating = false,
    this.onGenerateSummary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isGenerating) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Menyusun ringkasan catatan...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
      );
    }

    final markdown = summaryMarkdown?.trim();
    if (markdown == null || markdown.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 32,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum Ada Ringkasan',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Buat rangkuman terstruktur dari transkrip percakapan atau rekaman suara ini.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.secondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onGenerateSummary,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.summarize_outlined, size: 18),
                  label: const Text(
                    'Buat Ringkasan',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Markdown(
      data: markdown,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      styleSheet: MarkdownStyleSheet(
        h1: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurface,
          height: 1.4,
          letterSpacing: -0.3,
        ),
        h2: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colorScheme.primary,
          height: 1.4,
        ),
        h3: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
          height: 1.4,
        ),
        p: TextStyle(
          fontSize: 15,
          color: colorScheme.onSurface,
          height: 1.65,
        ),
        listBullet: TextStyle(
          fontSize: 15,
          color: colorScheme.primary,
        ),
        strong: const TextStyle(fontWeight: FontWeight.w700),
        blockquote: TextStyle(
          color: colorScheme.secondary,
          fontSize: 14.5,
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
          border: Border(
            left: BorderSide(color: colorScheme.primary, width: 3),
          ),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(6),
            bottomRight: Radius.circular(6),
          ),
        ),
      ),
    );
  }
}
