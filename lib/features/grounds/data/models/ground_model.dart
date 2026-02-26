import '../../domain/entities/ground.dart';

/// 경기장 모델 (Firestore 변환 포함)
class GroundModel extends Ground {
  const GroundModel({
    required super.groundId,
    required super.name,
    super.url,
    super.address,
    super.active,
    super.priority,
    super.managers,
  });

  factory GroundModel.fromFirestore(String id, Map<String, dynamic> json) {
    return GroundModel(
      groundId: id,
      name: json['name'] as String? ?? '',
      url: json['url'] as String?,
      address: json['address'] as String?,
      active: json['active'] as bool?,
      priority: json['priority'] as int?,
      managers: json['managers'] != null
          ? List<String>.from(json['managers'] as List)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groundId': groundId,
      'name': name,
      if (url != null) 'url': url,
      if (address != null) 'address': address,
      if (active != null) 'active': active,
      if (priority != null) 'priority': priority,
      if (managers != null) 'managers': managers,
    };
  }
}
