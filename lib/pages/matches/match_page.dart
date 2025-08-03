import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/match/match_event_model.dart';
import 'match_detail_page.dart';

class MatchPage extends StatelessWidget {
  final String teamId;
  const MatchPage({super.key, required this.teamId});

  @override
  Widget build(BuildContext context) {
    final matchRef = FirebaseFirestore.instance
        .collection('teams')
        .doc(teamId)
        .collection('matches');

    return Scaffold(
      appBar: AppBar(title: const Text('매치 목록')),
      body: StreamBuilder<QuerySnapshot>(
        stream: matchRef.orderBy('date', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('등록된 매치가 없습니다.'));
          }

          final events = docs
              .map((doc) => MatchEventModel.fromDoc(doc))
              .toList();

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final match = events[index];

              return ListTile(
                title: Text(match.title),
                subtitle: Text('${match.date} | ${match.startTime}'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MatchDetailPage(event: match),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
