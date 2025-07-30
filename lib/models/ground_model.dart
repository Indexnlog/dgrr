class GroundModel {
  final String id;
  final String teamId; // ✅ 추가됨
  final String groundId;
  final String name;
  final int priority;
  final List<String> managers;
  final String url;
  final bool active;

  GroundModel({
    required this.id,
    required this.teamId,
    required this.groundId,
    required this.name,
    required this.priority,
    required this.managers,
    required this.url,
    required this.active,
  });

  factory GroundModel.fromDoc(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroundModel(
      id: doc.id,
      teamId: data['teamId'] ?? '',
      groundId: data['groundId'] ?? '',
      name: data['name'] ?? '',
      priority: data['priority'] ?? 99,
      managers: List<String>.from(data['managers'] ?? []),
      url: data['url'] ?? '',
      active: data['active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'groundId': groundId,
      'name': name,
      'priority': priority,
      'managers': managers,
      'url': url,
      'active': active,
    };
  }
}
