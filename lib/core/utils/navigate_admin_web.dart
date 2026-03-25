import 'dart:html' as html;

void navigateToAdminImpl() {
  html.window.location.hash = '/admin';
  html.window.location.reload();
}
