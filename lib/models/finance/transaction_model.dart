import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String teamId; // ✅ 팀 구분용
  final double amount;
  final String type; // 'income' or 'expense'
  final String category; // 예: '회비', '행사비'
  final String memo;
  final Timestamp date; // 실제 지출/입금일
  final Timestamp createdAt; // 기록 생성일
  final String createdBy; // 관리자 ID 또는 이름
  final bool isManual; // 수동 입력 여부
  final String? memberId; // 관련 멤버 ID (nullable)
  final String? feeId; // membership_fees 연동 ID (nullable)
  final String? eventId; // 클래스/매치 등 연동 ID (nullable)

  TransactionModel({
    required this.id,
    required this.teamId,
    required this.amount,
    required this.type,
    required this.category,
    required this.memo,
    required this.date,
    required this.createdAt,
    required this.createdBy,
    required this.isManual,
    this.memberId,
    this.feeId,
    this.eventId,
  });

  factory TransactionModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      teamId: data['teamId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      type: data['type'] ?? '',
      category: data['category'] ?? '',
      memo: data['memo'] ?? '',
      date: data['date'] ?? Timestamp.now(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      createdBy: data['createdBy'] ?? '',
      isManual: data['isManual'] ?? true,
      memberId: data['memberId'],
      feeId: data['feeId'],
      eventId: data['eventId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'amount': amount,
      'type': type,
      'category': category,
      'memo': memo,
      'date': date,
      'createdAt': createdAt,
      'createdBy': createdBy,
      'isManual': isManual,
      'memberId': memberId,
      'feeId': feeId,
      'eventId': eventId,
    };
  }
}
