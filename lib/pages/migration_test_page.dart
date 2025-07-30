// lib/pages/migration_test_page.dart

import 'package:flutter/material.dart';
import '../services/admin_migration_service.dart';
import '../services/admin_team_migration_service.dart';

class MigrationTestPage extends StatelessWidget {
  final migrationService = AdminMigrationService();
  final teamMigrationService = AdminTeamMigrationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('마이그레이션 테스트')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ 전체 컬렉션 복사 (posts 포함)
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('📦 전체 컬렉션 마이그레이션 (posts 포함)'),
              onPressed: () async {
                await migrationService
                    .migrateAllCollections(); // 🔄 posts 포함하는 함수

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🎉 전체 컬렉션 마이그레이션 완료!')),
                );
              },
            ),
            const SizedBox(height: 20),

            // ✅ 특정 팀 복사: ID 지정 마이그레이션
            ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('🧬 팀 문서 복사 (ID 변경)'),
              onPressed: () async {
                const oldId = 'foreverone_fc'; // 🔁 기존 팀 문서 ID 입력
                const newId = 'foreverone_fc'; // ✅ 새로운 팀 ID

                await teamMigrationService.migrateTeamToNamedId(
                  oldId: oldId,
                  newId: newId,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ 팀 복사 완료: foreverone_fc')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
