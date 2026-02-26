/// 팀 설정 엔티티
class Setting {
  const Setting({
    required this.settingId,
    required this.type,
    this.userIds,
  });

  final String settingId;
  final SettingType type;
  final List<String>? userIds;

  Setting copyWith({
    String? settingId,
    SettingType? type,
    List<String>? userIds,
  }) {
    return Setting(
      settingId: settingId ?? this.settingId,
      type: type ?? this.type,
      userIds: userIds ?? this.userIds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Setting && other.settingId == settingId;
  }

  @override
  int get hashCode => settingId.hashCode;
}

enum SettingType {
  attendanceManager,
  membershipManager,
  reservationNoticeManager;

  String get value {
    switch (this) {
      case SettingType.attendanceManager:
        return 'attendanceManager';
      case SettingType.membershipManager:
        return 'membershipManager';
      case SettingType.reservationNoticeManager:
        return 'reservationNoticeManager';
    }
  }

  static SettingType? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'attendanceManager':
        return SettingType.attendanceManager;
      case 'membershipManager':
        return SettingType.membershipManager;
      case 'reservationNoticeManager':
        return SettingType.reservationNoticeManager;
      default:
        return null;
    }
  }
}
