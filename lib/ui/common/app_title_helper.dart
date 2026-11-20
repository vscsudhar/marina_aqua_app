import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

void setAppTitle(String pageName) {
  final fullTitle =
      pageName.trim().isEmpty ? 'DockRent' : '${pageName.trim()} | DockRent';
  SystemChrome.setApplicationSwitcherDescription(
    ApplicationSwitcherDescription(
      label: fullTitle,
      primaryColor: 0xFF0284C7,
    ),
  );
  if (kIsWeb) {
    try {
      web.document.title = fullTitle;
    } catch (_) {}
  }
}
