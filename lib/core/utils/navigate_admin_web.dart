import 'dart:html' as html;

/// 웹: #/admin으로 이동 (해시 방식, usePathUrlStrategy 미사용 시 무한로딩 방지)
void navigateToAdmin() {
  html.window.location.href =
      '${html.window.location.origin}${html.window.location.pathname}#/admin';
}
