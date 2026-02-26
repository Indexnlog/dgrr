import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/reservation_notice.dart';

/// 예약 공지 모델 (Firestore 변환 포함)
class ReservationNoticeModel extends ReservationNotice {
  const ReservationNoticeModel({
    required super.noticeId,
    required super.targetDate,
    super.targetStartTime,
    super.targetEndTime,
    super.reservedForType,
    super.reservedForId,
    super.venueType,
    super.openAt,
    super.slots,
    super.fallback,
    super.status,
    super.createdBy,
    super.publishedAt,
    super.createdAt,
  });

  factory ReservationNoticeModel.fromFirestore(
    String id,
    Map<String, dynamic> json,
  ) {
    return ReservationNoticeModel(
      noticeId: id,
      targetDate: (json['targetDate'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      targetStartTime: json['targetStartTime'] as String?,
      targetEndTime: json['targetEndTime'] as String?,
      reservedForType: ReservationNoticeForType.fromString(
        json['reservedForType'] as String?,
      ),
      reservedForId: json['reservedForId'] as String?,
      venueType: VenueType.fromString(json['venueType'] as String?),
      openAt: (json['openAt'] as Timestamp?)?.toDate(),
      slots: _parseSlots(json['slots']),
      fallback: _parseFallback(json['fallback']),
      status: ReservationNoticeStatus.fromString(json['status'] as String?),
      createdBy: json['createdBy'] as String?,
      publishedAt: (json['publishedAt'] as Timestamp?)?.toDate(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  static List<ReservationNoticeSlot>? _parseSlots(dynamic data) {
    if (data is! List) return null;
    return data
        .map((e) => e as Map<String, dynamic>)
        .map(_parseSlot)
        .toList();
  }

  static ReservationNoticeSlot _parseSlot(Map<String, dynamic> json) {
    return ReservationNoticeSlot(
      groundId: json['groundId'] as String? ?? '',
      groundName: json['groundName'] as String? ?? '',
      address: json['address'] as String?,
      url: json['url'] as String?,
      managers: json['managers'] != null
          ? List<String>.from(json['managers'] as List)
          : null,
      result: SlotResult.fromString(json['result'] as String?),
      successBy: json['successBy'] as String?,
      successAt: (json['successAt'] as Timestamp?)?.toDate(),
    );
  }

  static ReservationNoticeFallback? _parseFallback(dynamic data) {
    if (data is! Map<String, dynamic>) return null;
    return ReservationNoticeFallback(
      title: data['title'] as String?,
      openAtText: data['openAtText'] as String?,
      targetDateText: data['targetDateText'] as String?,
      targetTime: data['targetTime'] as String?,
      fee: data['fee'] as int?,
      url: data['url'] as String?,
      memo: data['memo'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'targetDate': Timestamp.fromDate(targetDate),
      if (targetStartTime != null) 'targetStartTime': targetStartTime,
      if (targetEndTime != null) 'targetEndTime': targetEndTime,
      if (reservedForType != null) 'reservedForType': reservedForType!.value,
      if (reservedForId != null) 'reservedForId': reservedForId,
      if (venueType != null) 'venueType': venueType!.value,
      if (openAt != null) 'openAt': Timestamp.fromDate(openAt!),
      if (slots != null &&
          slots!.isNotEmpty)
        'slots': slots!.map((s) => _slotToMap(s)).toList(),
      if (fallback != null) 'fallback': _fallbackToMap(fallback!),
      if (status != null) 'status': status!.value,
      if (createdBy != null) 'createdBy': createdBy,
      if (publishedAt != null) 'publishedAt': Timestamp.fromDate(publishedAt!),
      'createdAt': Timestamp.fromDate(createdAt ?? DateTime.now()),
    };
  }

  static Map<String, dynamic> _slotToMap(ReservationNoticeSlot s) {
    return {
      'groundId': s.groundId,
      'groundName': s.groundName,
      if (s.address != null) 'address': s.address,
      if (s.url != null) 'url': s.url,
      if (s.managers != null) 'managers': s.managers,
      if (s.result != null) 'result': s.result!.value,
      if (s.successBy != null) 'successBy': s.successBy,
      if (s.successAt != null) 'successAt': Timestamp.fromDate(s.successAt!),
    };
  }

  static Map<String, dynamic> _fallbackToMap(ReservationNoticeFallback f) {
    return {
      if (f.title != null) 'title': f.title,
      if (f.openAtText != null) 'openAtText': f.openAtText,
      if (f.targetDateText != null) 'targetDateText': f.targetDateText,
      if (f.targetTime != null) 'targetTime': f.targetTime,
      if (f.fee != null) 'fee': f.fee,
      if (f.url != null) 'url': f.url,
      if (f.memo != null) 'memo': f.memo,
    };
  }
}
