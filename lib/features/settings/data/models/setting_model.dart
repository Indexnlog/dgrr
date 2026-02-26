import '../../domain/entities/setting.dart';

/// 팀 설정 모델 (Firestore 변환 포함)
class SettingModel extends Setting {
  const SettingModel({
    required super.settingId,
    required super.type,
    super.userIds,
  });

  factory SettingModel.fromFirestore(String id, Map<String, dynamic> json) {
    return SettingModel(
      settingId: id,
      type: SettingType.fromString(json['type'] as String?) ??
          SettingType.attendanceManager,
      userIds: json['userIds'] != null
          ? List<String>.from(json['userIds'] as List)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.value,
      if (userIds != null) 'userIds': userIds,
    };
  }
}
