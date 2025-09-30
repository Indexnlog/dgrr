import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeamColorPickerDialog extends StatefulWidget {
  final String teamId;
  final String? currentColor;
  const TeamColorPickerDialog({
    super.key,
    required this.teamId,
    this.currentColor,
  });

  @override
  State<TeamColorPickerDialog> createState() => _TeamColorPickerDialogState();
}

class _TeamColorPickerDialogState extends State<TeamColorPickerDialog> {
  Color pickerColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    if (widget.currentColor != null && widget.currentColor!.isNotEmpty) {
      pickerColor = _hexToColor(widget.currentColor!);
    }
  }

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('팀 컬러 선택'),
      content: SingleChildScrollView(
        child: BlockPicker(
          pickerColor: pickerColor,
          onColorChanged: (color) {
            setState(() {
              pickerColor = color;
            });
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () async {
            final hex = _colorToHex(pickerColor);
            await FirebaseFirestore.instance
                .collection('teams')
                .doc(widget.teamId)
                .update({'teamColor': hex});
            Navigator.pop(context);
          },
          child: const Text('저장'),
        ),
      ],
    );
  }
}
