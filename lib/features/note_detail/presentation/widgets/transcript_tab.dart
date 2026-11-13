import 'package:flutter/material.dart';
import '../../../dashboard/data/models/transcript_segment.dart';

class TranscriptTab extends StatefulWidget {
  final String transcript;
  final List<TranscriptSegment> segments;
  final bool hasAudio;
  final bool isTranscribing;
  final VoidCallback? onRetryTranscription;

  const TranscriptTab({
    super.key,
    required this.transcript,
    this.segments = const [],
    this.hasAudio = false,
    this.isTranscribing = false,
    this.onRetryTranscription,
  });

  @override
  State<TranscriptTab> createState() => _TranscriptTabState();
}

class _TranscriptTabState extends State<TranscriptTab> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _isEmpty => widget.transcript.trim().isEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isEmpty) {
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
                  widget.hasAudio
                      ? Icons.mic_rounded
                      : Icons.description_outlined,
                  size: 32,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.hasAudio
                      ? 'Audio Tersimpan'
                      : 'Belum Ada Transkrip',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.hasAudio
                      ? 'Berkas audio tersimpan di perangkat namun belum ditranskripsikan. Konfigurasikan API key Groq atau OpenAI di Pengaturan untuk memproses teks suara.'
                      : 'Catatan ini belum memiliki rekaman audio atau transkripsi teks.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.secondary,
                    height: 1.45,
                  ),
                ),
                if (widget.hasAudio && widget.onRetryTranscription != null) ...[
                  const SizedBox(height: 20),
                  if (widget.isTranscribing) ...[
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Sedang mentranskripsikan audio...',
                      style: TextStyle(
                        color: colorScheme.secondary,
                        fontSize: 13,
                      ),
                    ),
                  ] else ...[
                    FilledButton.icon(
                      onPressed: widget.onRetryTranscription,
                      icon: const Icon(Icons.transcribe_rounded, size: 18),
                      label: const Text('Transkripsikan Sekarang'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      );
    }

    final segments = widget.segments;
    final filtered = _query.trim().isEmpty
        ? segments
        : segments.where((s) => _matches(s.text)).toList();

    return Column(
      children: [
        Container(
          color: colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v),
            style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Cari dalam transkrip...',
              isDense: true,
              prefixIcon: Icon(Icons.search_rounded,
                  size: 20, color: colorScheme.secondary),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty && segments.isNotEmpty
              ? Center(
                  child: Text(
                    'Tidak ditemukan bagian yang cocok dengan kata kunci',
                    style: TextStyle(color: colorScheme.secondary, fontSize: 14),
                  ),
                )
              : _buildContent(filtered),
        ),
      ],
    );
  }

  bool _matches(String text) =>
      text.toLowerCase().contains(_query.toLowerCase());

  Widget _buildContent(List<TranscriptSegment> filtered) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.segments.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: SelectableText(
          widget.transcript,
          style: TextStyle(
            height: 1.65,
            color: colorScheme.onSurface,
            fontSize: 15.5,
          ),
        ),
      );
    }

    final segments = filtered.isEmpty ? widget.segments : filtered;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: segments.length,
      separatorBuilder: (context, index) => Divider(
        height: 16,
        thickness: 0.5,
        color: colorScheme.outline.withValues(alpha: 0.5),
      ),
      itemBuilder: (context, index) {
        return _SegmentRow(segment: segments[index], query: _query);
      },
    );
  }
}

class _SegmentRow extends StatelessWidget {
  final TranscriptSegment segment;
  final String query;

  const _SegmentRow({required this.segment, required this.query});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _formatTimestamp(segment.startSeconds),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  segment.speaker,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 3),
                SelectableText.rich(
                  _highlight(segment.text, colorScheme),
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _highlight(String text, ColorScheme colorScheme) {
    if (query.trim().isEmpty) return TextSpan(text: text);

    final lower = text.toLowerCase();
    final q = query.trim().toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    while (true) {
      final idx = lower.indexOf(q, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) spans.add(TextSpan(text: text.substring(start, idx)));
      spans.add(TextSpan(
        text: text.substring(idx, idx + q.length),
        style: TextStyle(
          backgroundColor: colorScheme.primaryContainer,
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ));
      start = idx + q.length;
    }
    return TextSpan(children: spans);
  }

  static String _formatTimestamp(double seconds) {
    final total = seconds.round();
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
