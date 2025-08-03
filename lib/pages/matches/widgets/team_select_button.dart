import 'package:flutter/material.dart';
import '../../../services/firestore/match_service.dart';
import '../../../widgets/team_select_bottom_sheet.dart';

class TeamSelectButton extends StatelessWidget {
  final String matchId;

  const TeamSelectButton({super.key, required this.matchId});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) {
            return TeamSelectBottomSheet(
              onTeamSelected: (selectedTeamId) async {
                await MatchService.updateMatchTeam(matchId, selectedTeamId);
              },
            );
          },
        );
      },
      child: const Text('상대팀 선택 (수동)'),
    );
  }
}
