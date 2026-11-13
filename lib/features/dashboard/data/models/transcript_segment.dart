class TranscriptSegment {
  final double startSeconds;
  final double endSeconds;
  final String speaker;
  final String text;

  const TranscriptSegment({
    required this.startSeconds,
    required this.endSeconds,
    this.speaker = 'Speaker',
    required this.text,
  });

  factory TranscriptSegment.fromJson(Map<String, dynamic> json) {
    return TranscriptSegment(
      startSeconds: (json['startSeconds'] as num?)?.toDouble() ?? 0,
      endSeconds: (json['endSeconds'] as num?)?.toDouble() ?? 0,
      speaker: json['speaker'] as String? ?? 'Speaker',
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startSeconds': startSeconds,
      'endSeconds': endSeconds,
      'speaker': speaker,
      'text': text,
    };
  }
}
