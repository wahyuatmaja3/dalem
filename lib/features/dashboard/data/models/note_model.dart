import 'transcript_segment.dart';

enum NoteStatus { draft, uploading, processed, error }

class NoteModel {
  final String id;
  final String title;
  final DateTime createdAt;
  final NoteStatus status;
  final String? category;
  final String? transcript;
  final String? summaryMarkdown;
  final List<TranscriptSegment> transcriptSegments;
  final String? audioPath;

  const NoteModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.status,
    this.category,
    this.transcript,
    this.summaryMarkdown,
    this.transcriptSegments = const [],
    this.audioPath,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    final rawSegments = json['transcriptSegments'] as List<dynamic>?;
    return NoteModel(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: NoteStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => NoteStatus.draft,
      ),
      category: json['category'] as String?,
      transcript: json['transcript'] as String?,
      summaryMarkdown: json['summaryMarkdown'] as String?,
      transcriptSegments: rawSegments
              ?.map((e) =>
                  TranscriptSegment.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      audioPath: json['audioPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'category': category,
      'transcript': transcript,
      'summaryMarkdown': summaryMarkdown,
      'transcriptSegments':
          transcriptSegments.map((e) => e.toJson()).toList(),
      'audioPath': audioPath,
    };
  }

  NoteModel copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    NoteStatus? status,
    String? category,
    String? transcript,
    String? summaryMarkdown,
    List<TranscriptSegment>? transcriptSegments,
    String? audioPath,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      category: category ?? this.category,
      transcript: transcript ?? this.transcript,
      summaryMarkdown: summaryMarkdown ?? this.summaryMarkdown,
      transcriptSegments: transcriptSegments ?? this.transcriptSegments,
      audioPath: audioPath ?? this.audioPath,
    );
  }
}
