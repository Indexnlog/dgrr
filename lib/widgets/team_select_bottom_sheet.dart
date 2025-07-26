import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeamSelectBottomSheet extends StatelessWidget {
  final Function(String teamId) onTeamSelected;

  const TeamSelectBottomSheet({super.key, required this.onTeamSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '상대팀 선택',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('teams')
                  .orderBy('name') // 팀 이름 기준 정렬
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('등록된 팀이 없습니다.'));
                }

                final teams = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: teams.length,
                  itemBuilder: (context, index) {
                    final team = teams[index].data() as Map<String, dynamic>;
                    final teamId = teams[index].id;
                    final teamName = team['name'] ?? '이름 없음';
                    final logoUrl = team['logoUrl'] ?? '';
                    final teamColorHex = team['teamColor'] ?? '#CCCCCC';

                    Color teamColor = _colorFromHex(teamColorHex);

                    return Card(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: teamColor, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: logoUrl.isNotEmpty
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(logoUrl),
                              )
                            : CircleAvatar(
                                backgroundColor: teamColor,
                                child: const Icon(
                                  Icons.sports_soccer,
                                  color: Colors.white,
                                ),
                              ),
                        title: Text(teamName),
                        onTap: () {
                          onTeamSelected(teamId);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // HEX → Color 변환 유틸
  Color _colorFromHex(String hexColor) {
    final buffer = StringBuffer();
    if (hexColor.length == 6 || hexColor.length == 7) buffer.write('ff');
    buffer.write(hexColor.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
