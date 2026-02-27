import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/opponent.dart';

/// 상대팀 모델 (Firestore 변환)
class OpponentModel extends Opponent {
  const OpponentModel({
    required super.opponentId,
    super.name,
    super.contact,
    super.status,
    super.recentResults,
    super.records,
    super.createdAt,
    super.updatedAt,
  });

  factory OpponentModel.fromFirestore(String id, Map<String, dynamic> json) {
    OpponentRecords? records;
    if (json['records'] is Map) {
      final r = json['records'] as Map<String, dynamic>;
      records = OpponentRecords(
        wins: r['wins'] as int? ?? 0,
        draws: r['draws'] as int? ?? 0,
        losses: r['losses'] as int? ?? 0,
      );
    }
    return OpponentModel(
      opponentId: id,
      name: json['name'] as String?,
      contact: json['contact'] as String?,
      status: json['status'] as String?,
      recentResults: json['recentResults'] != null
          ? List<String>.from(json['recentResults'] as List)
          : null,
      records: records,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (name != null) 'name': name,
      if (contact != null) 'contact': contact,
      if (status != null) 'status': status,
      if (recentResults != null) 'recentResults': recentResults,
      if (records != null)
        'records': {
          'wins': records!.wins,
          'draws': records!.draws,
          'losses': records!.losses,
        },
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
