enum NoteStatus { draft, uploading, processed, error }

class NoteModel {
  final String id;
  final String title;
  final DateTime createdAt;
  final NoteStatus status;
  final String? transcript;
  final String? summaryMarkdown;

  const NoteModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.status,
    this.transcript,
    this.summaryMarkdown,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: NoteStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => NoteStatus.draft,
      ),
      transcript: json['transcript'] as String?,
      summaryMarkdown: json['summaryMarkdown'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'transcript': transcript,
      'summaryMarkdown': summaryMarkdown,
    };
  }

  NoteModel copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    NoteStatus? status,
    String? transcript,
    String? summaryMarkdown,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      transcript: transcript ?? this.transcript,
      summaryMarkdown: summaryMarkdown ?? this.summaryMarkdown,
    );
  }
}
