import 'package:flutter/material.dart';

class TeamProvider with ChangeNotifier {
  String? _teamId;
  String? get teamId => _teamId;

  void setTeamId(String id) {
    _teamId = id;
    notifyListeners();
  }

  void clearTeamId() {
    _teamId = null;
    notifyListeners();
  }
}
