class LessonFeeModel {
  final String id;
  final String teamId; // ✅ 추가됨
  final String yearMonth; // YYYY-MM
  final int feePerSession;

  LessonFeeModel({
    required this.id,
    required this.teamId,
    required this.yearMonth,
    required this.feePerSession,
  });

  factory LessonFeeModel.fromDoc(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LessonFeeModel(
      id: doc.id,
      teamId: data['teamId'] ?? '',
      yearMonth: data['yearMonth'] ?? '',
      feePerSession: data['feePerSession'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'yearMonth': yearMonth,
      'feePerSession': feePerSession,
    };
  }
}
