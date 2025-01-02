// filepath: /home/kirtan/avatar_app/lib/services/platform_impl.dart
import 'dart:io';

String getPlatformOperatingSystem() {
  return Platform.operatingSystem;
}

bool get isMobile => Platform.isIOS || Platform.isAndroid;