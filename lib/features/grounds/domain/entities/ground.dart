/// 경기장 엔티티
class Ground {
  const Ground({
    required this.groundId,
    required this.name,
    this.url,
    this.address,
    this.active,
    this.priority,
    this.managers,
  });

  final String groundId;
  final String name;
  final String? url;
  /// 주소 (예: 서울 금천구 가산동 562-3)
  final String? address;
  final bool? active;
  final int? priority;
  final List<String>? managers;

  Ground copyWith({
    String? groundId,
    String? name,
    String? url,
    String? address,
    bool? active,
    int? priority,
    List<String>? managers,
  }) {
    return Ground(
      groundId: groundId ?? this.groundId,
      name: name ?? this.name,
      url: url ?? this.url,
      address: address ?? this.address,
      active: active ?? this.active,
      priority: priority ?? this.priority,
      managers: managers ?? this.managers,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Ground && other.groundId == groundId;
  }

  @override
  int get hashCode => groundId.hashCode;
}
