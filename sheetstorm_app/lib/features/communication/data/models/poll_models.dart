/// Domain models for Communication — Polls

// ─── Poll Status ──────────────────────────────────────────────────────────────

enum PollStatus {
  active('Aktiv'),
  ended('Beendet');

  const PollStatus(this.label);
  final String label;

  static PollStatus fromJson(String value) => switch (value) {
        'active' => PollStatus.active,
        'ended' => PollStatus.ended,
        _ => PollStatus.active,
      };

  String toJson() => name;
}

// ─── Author ───────────────────────────────────────────────────────────────────

class Author {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? role;

  const Author({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.role,
  });

  factory Author.fromJson(Map<String, dynamic> json) => Author(
        id: json['id'] as String,
        name: json['name'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        role: json['role'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarUrl': avatarUrl,
        'role': role,
      };
}

// ─── Poll Option ──────────────────────────────────────────────────────────────

class PollOption {
  final String id;
  final String text;
  final int voteCount;
  final double percentage;
  final bool hasVoted;

  const PollOption({
    required this.id,
    required this.text,
    required this.voteCount,
    required this.percentage,
    required this.hasVoted,
  });

  factory PollOption.fromJson(Map<String, dynamic> json) => PollOption(
        id: json['id'] as String,
        text: json['text'] as String,
        voteCount: json['voteCount'] as int,
        percentage: (json['percentage'] as num).toDouble(),
        hasVoted: json['hasVoted'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'voteCount': voteCount,
        'percentage': percentage,
        'hasVoted': hasVoted,
      };

  PollOption copyWith({
    String? id,
    String? text,
    int? voteCount,
    double? percentage,
    bool? hasVoted,
  }) =>
      PollOption(
        id: id ?? this.id,
        text: text ?? this.text,
        voteCount: voteCount ?? this.voteCount,
        percentage: percentage ?? this.percentage,
        hasVoted: hasVoted ?? this.hasVoted,
      );
}

// ─── Poll ─────────────────────────────────────────────────────────────────────

class Poll {
  final String id;
  final String bandId;
  final Author author;
  final String question;
  final List<PollOption> options;
  final DateTime? deadline;
  final bool isAnonymous;
  final bool isMultiSelect;
  final bool showResultsAfterVoting;
  final PollStatus status;
  final int participantCount;
  final bool hasVoted;
  final List<String> targetSectionIds;
  final DateTime createdAt;

  const Poll({
    required this.id,
    required this.bandId,
    required this.author,
    required this.question,
    required this.options,
    this.deadline,
    this.isAnonymous = true,
    this.isMultiSelect = false,
    this.showResultsAfterVoting = true,
    required this.status,
    this.participantCount = 0,
    this.hasVoted = false,
    this.targetSectionIds = const [],
    required this.createdAt,
  });

  factory Poll.fromJson(Map<String, dynamic> json) => Poll(
        id: json['id'] as String,
        bandId: json['bandId'] as String,
        author: Author.fromJson(json['author'] as Map<String, dynamic>),
        question: json['question'] as String,
        options: (json['options'] as List<dynamic>)
            .map((e) => PollOption.fromJson(e as Map<String, dynamic>))
            .toList(),
        deadline: json['deadline'] != null
            ? DateTime.parse(json['deadline'] as String)
            : null,
        isAnonymous: json['isAnonymous'] as bool? ?? true,
        isMultiSelect: json['isMultiSelect'] as bool? ?? false,
        showResultsAfterVoting:
            json['showResultsAfterVoting'] as bool? ?? true,
        status: PollStatus.fromJson(json['status'] as String),
        participantCount: json['participantCount'] as int? ?? 0,
        hasVoted: json['hasVoted'] as bool? ?? false,
        targetSectionIds: (json['targetSectionIds'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'bandId': bandId,
        'author': author.toJson(),
        'question': question,
        'options': options.map((o) => o.toJson()).toList(),
        'deadline': deadline?.toIso8601String(),
        'isAnonymous': isAnonymous,
        'isMultiSelect': isMultiSelect,
        'showResultsAfterVoting': showResultsAfterVoting,
        'status': status.toJson(),
        'participantCount': participantCount,
        'hasVoted': hasVoted,
        'targetSectionIds': targetSectionIds,
        'createdAt': createdAt.toIso8601String(),
      };

  Duration? get timeRemaining {
    if (deadline == null) return null;
    final now = DateTime.now();
    if (deadline!.isBefore(now)) return Duration.zero;
    return deadline!.difference(now);
  }

  Poll copyWith({
    String? id,
    String? bandId,
    Author? author,
    String? question,
    List<PollOption>? options,
    DateTime? deadline,
    bool? isAnonymous,
    bool? isMultiSelect,
    bool? showResultsAfterVoting,
    PollStatus? status,
    int? participantCount,
    bool? hasVoted,
    List<String>? targetSectionIds,
    DateTime? createdAt,
  }) =>
      Poll(
        id: id ?? this.id,
        bandId: bandId ?? this.bandId,
        author: author ?? this.author,
        question: question ?? this.question,
        options: options ?? this.options,
        deadline: deadline ?? this.deadline,
        isAnonymous: isAnonymous ?? this.isAnonymous,
        isMultiSelect: isMultiSelect ?? this.isMultiSelect,
        showResultsAfterVoting:
            showResultsAfterVoting ?? this.showResultsAfterVoting,
        status: status ?? this.status,
        participantCount: participantCount ?? this.participantCount,
        hasVoted: hasVoted ?? this.hasVoted,
        targetSectionIds: targetSectionIds ?? this.targetSectionIds,
        createdAt: createdAt ?? this.createdAt,
      );
}
