import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/schedule/schedule_event_model.dart';
import '../schedule_detail_page.dart';

class EventCard extends StatelessWidget {
  final ScheduleEvent event;
  final VoidCallback onAttend;
  final VoidCallback onAbsent;

  const EventCard({
    super.key,
    required this.event,
    required this.onAttend,
    required this.onAbsent,
  });

  /// ✅ 지도 열기 함수
  Future<void> _openMap(BuildContext context, String? location) async {
    final safeLocation = location?.trim();
    if (safeLocation == null || safeLocation.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('장소 정보가 없습니다.')));
      return;
    }

    final encodedLocation = Uri.encodeComponent(safeLocation);
    final url = Uri.parse('https://map.naver.com/v5/search/$encodedLocation');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('지도를 열 수 없습니다: $safeLocation')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = event.location?.trim() ?? '';
    final timeText = event.time?.trim() ?? '';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(
          event.type == 'class' ? Icons.class_ : Icons.sports_soccer,
          color: event.type == 'class' ? Colors.blue : Colors.green,
        ),
        title: Text(
          '$timeText @ $location',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('참석자: ${event.attendees.length}명'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: onAttend,
              tooltip: '참석',
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: onAbsent,
              tooltip: '불참',
            ),
            IconButton(
              icon: const Icon(Icons.map, color: Colors.blueGrey),
              onPressed: () => _openMap(context, location),
              tooltip: '지도 열기',
            ),
          ],
        ),
        onTap: () {
          String collectionName;
          switch (event.type) {
            case 'class':
              collectionName = 'classes';
              break;
            case 'match':
              collectionName = 'matches';
              break;
            case 'event':
              collectionName = 'events';
              break;
            default:
              collectionName = 'unknown';
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScheduleDetailPage(
                collectionName: collectionName,
                docId: event.id,
              ),
            ),
          );
        },
      ),
    );
  }
}
