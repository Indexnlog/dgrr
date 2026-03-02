import 'dart:html' as html;

/// 웹: #/admin으로 이동 후 강제 리로드
///
/// 해시 변경만으로는 DgrrApp이 rebuild되지 않아 _isAdminPath()가 재평가되지 않음.
/// 강제 리로드로 Flutter 앱을 재시작해 AdminApp이 렌더링되게 함.
void navigateToAdmin() {
  html.window.location.hash = '/admin';
  html.window.location.reload();
}
