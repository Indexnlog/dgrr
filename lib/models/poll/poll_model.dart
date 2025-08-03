import 'package:cloud_firestore/cloud_firestore.dart';

class PollModel {
  final String id;
  final String teamId;
  final String title;
  final String description;
  final String type; // text 또는 date
  final int maxSelections;
  final bool canChangeVote;
  final bool showResultBeforeDeadline;
  final bool anonymous;
  final String linkedEventId;
  final Timestamp expiresAt;
  final Timestamp? resultFinalizedAt;
  final bool isActive;
  final Timestamp createdAt;
  final String createdBy;
  final List<PollOption> options;

  PollModel({
    required this.id,
    required this.teamId,
    required this.title,
    required this.description,
    required this.type,
    required this.maxSelections,
    required this.canChangeVote,
    required this.showResultBeforeDeadline,
    required this.anonymous,
    required this.linkedEventId,
    required this.expiresAt,
    required this.resultFinalizedAt,
    required this.isActive,
    required this.createdAt,
    required this.createdBy,
    required this.options,
  });

  factory PollModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PollModel(
      id: doc.id,
      teamId: data['teamId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'text',
      maxSelections: data['maxSelections'] ?? 1,
      canChangeVote: data['canChangeVote'] ?? false,
      showResultBeforeDeadline: data['showResultBeforeDeadline'] ?? false,
      anonymous: data['anonymous'] ?? false,
      linkedEventId: data['linkedEventId'] ?? '',
      expiresAt: data['expiresAt'],
      resultFinalizedAt: data['resultFinalizedAt'],
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'],
      createdBy: data['createdBy'] ?? '',
      options: (data['options'] as List<dynamic>? ?? [])
          .map((e) => PollOption.fromMap(e, data['type'] ?? 'text'))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'title': title,
      'description': description,
      'type': type,
      'maxSelections': maxSelections,
      'canChangeVote': canChangeVote,
      'showResultBeforeDeadline': showResultBeforeDeadline,
      'anonymous': anonymous,
      'linkedEventId': linkedEventId,
      'expiresAt': expiresAt,
      'resultFinalizedAt': resultFinalizedAt,
      'isActive': isActive,
      'createdAt': createdAt,
      'createdBy': createdBy,
      'options': options.map((e) => e.toMap()).toList(),
    };
  }
}

class PollOption {
  final String id;
  final String? text;
  final Timestamp? date;
  final List<String> votes;
  final int voteCount;

  PollOption({
    required this.id,
    this.text,
    this.date,
    required this.votes,
    required this.voteCount,
  });

  factory PollOption.fromMap(Map<String, dynamic> map, String type) {
    return PollOption(
      id: map['id'] ?? '',
      text: type == 'text' ? map['text'] ?? '' : null,
      date: type == 'date' ? map['date'] : null,
      votes: List<String>.from(map['votes'] ?? []),
      voteCount: map['voteCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (text != null) 'text': text,
      if (date != null) 'date': date,
      'votes': votes,
      'voteCount': voteCount,
    };
  }
}
