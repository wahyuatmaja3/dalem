import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onRecord;
  final VoidCallback? onImport;

  const EmptyState({
    super.key,
    this.title,
    this.message,
    this.onRecord,
    this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.mic_none_rounded,
                  size: 24,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title ?? 'Belum ada catatan suara',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message ??
                    'Mulai rekam suara atau impor berkas audio untuk membuat catatan pertama Anda.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.secondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRecord != null || onImport != null) ...[
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    if (onRecord != null)
                      ElevatedButton.icon(
                        onPressed: onRecord,
                        icon: const Icon(Icons.mic_rounded, size: 18),
                        label: const Text('Mulai Rekam'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                        ),
                      ),
                    if (onImport != null)
                      OutlinedButton.icon(
                        onPressed: onImport,
                        icon: const Icon(Icons.file_upload_outlined, size: 18),
                        label: const Text('Impor Audio'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
