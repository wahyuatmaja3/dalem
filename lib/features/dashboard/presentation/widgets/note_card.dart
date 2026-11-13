import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/note_model.dart';

class NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hari ini ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Kemarin ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return DateFormat('d MMM yyyy').format(date);
    }
  }

  Color _getStatusColor(ColorScheme colorScheme) {
    switch (note.status) {
      case NoteStatus.processed:
        return const Color(0xFF1B7340);
      case NoteStatus.uploading:
        return colorScheme.primary;
      case NoteStatus.error:
        return colorScheme.error;
      case NoteStatus.draft:
        return colorScheme.secondary;
    }
  }

  String _getStatusText() {
    switch (note.status) {
      case NoteStatus.processed:
        return 'Selesai';
      case NoteStatus.uploading:
        return 'Mengunggah';
      case NoteStatus.error:
        return 'Gagal';
      case NoteStatus.draft:
        return 'Draf';
    }
  }

  IconData _getStatusIcon() {
    switch (note.status) {
      case NoteStatus.processed:
        return Icons.check_circle_outline_rounded;
      case NoteStatus.uploading:
        return Icons.sync_rounded;
      case NoteStatus.error:
        return Icons.error_outline_rounded;
      case NoteStatus.draft:
        return Icons.edit_note_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _getStatusColor(colorScheme);

    final String? previewText = note.transcript?.trim().isNotEmpty == true
        ? note.transcript!.trim()
        : (note.summaryMarkdown?.trim().isNotEmpty == true
            ? note.summaryMarkdown!.trim()
            : null);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        note.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: colorScheme.secondary.withValues(alpha: 0.5),
                      size: 14,
                    ),
                  ],
                ),
                if (previewText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    previewText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.secondary,
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      _formatDate(note.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (note.category != null &&
                        note.category!.trim().isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          note.category!,
                          style: TextStyle(
                            color: colorScheme.onSecondaryContainer,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(),
                          size: 13,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
