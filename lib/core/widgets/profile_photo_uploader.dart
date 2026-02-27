import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart';
import '../../features/storage/presentation/providers/storage_providers.dart';
import '../../features/teams/presentation/providers/current_team_provider.dart';
import '../../features/teams/presentation/providers/team_providers.dart';

/// 프로필 사진 업로드 위젯 (갤러리에서 선택 → Storage 업로드 → Firestore 반영)
class ProfilePhotoUploader extends ConsumerStatefulWidget {
  const ProfilePhotoUploader({
    super.key,
    this.radius = 28,
    this.photoUrl,
    this.initial,
    this.onUploaded,
  });

  final double radius;
  final String? photoUrl;
  final String? initial;
  final void Function(String url)? onUploaded;

  @override
  ConsumerState<ProfilePhotoUploader> createState() =>
      _ProfilePhotoUploaderState();
}

class _ProfilePhotoUploaderState extends ConsumerState<ProfilePhotoUploader> {
  bool _isUploading = false;

  Future<void> _pickAndUpload() async {
    final user = ref.read(currentUserProvider);
    final teamId = ref.read(currentTeamIdProvider);
    if (user == null || teamId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('팀을 먼저 선택해주세요.')),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (xFile == null || !mounted) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await xFile.readAsBytes();
      final uploadImage = ref.read(uploadImageProvider);
      final photoUrl = await uploadImage.memberProfile(
        teamId: teamId,
        memberId: user.uid,
        bytes: Uint8List.fromList(bytes),
      );

      final teamRepo = ref.read(teamRepositoryProvider);
      await teamRepo.updateMemberPhotoUrl(
        teamId: teamId,
        memberId: user.uid,
        photoUrl: photoUrl,
      );

      widget.onUploaded?.call(photoUrl);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필 사진이 변경되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('업로드 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = widget.photoUrl;
    final initial = widget.initial ?? '?';

    return GestureDetector(
      onTap: _isUploading ? null : _pickAndUpload,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: widget.radius,
            backgroundColor: AppTheme.teamRed.withValues(alpha: 0.2),
            backgroundImage:
                photoUrl != null && photoUrl.isNotEmpty
                    ? CachedNetworkImageProvider(photoUrl)
                    : null,
            child:
                photoUrl == null || photoUrl.isEmpty
                    ? Text(
                        initial,
                        style: TextStyle(
                          color: AppTheme.teamRed,
                          fontSize: widget.radius * 0.8,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
          ),
          if (_isUploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            )
          else
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(Icons.camera_alt, color: Colors.white, size: 14),
              ),
            ),
        ],
      ),
    );
  }
}
