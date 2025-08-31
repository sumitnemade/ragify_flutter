import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

void setupTestMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock path_provider platform channel
  const MethodChannel channel = MethodChannel(
    'plugins.flutter.io/path_provider',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getApplicationDocumentsDirectory':
            return '/tmp/test_app_documents';
          case 'getApplicationSupportDirectory':
            return '/tmp/test_app_support';
          case 'getLibraryDirectory':
            return '/tmp/test_library';
          case 'getTemporaryDirectory':
            return '/tmp/test_temp';
          case 'getDownloadsDirectory':
            return '/tmp/test_downloads';
          case 'getExternalStorageDirectory':
            return '/tmp/test_external_storage';
          case 'getExternalCacheDirectories':
            return ['/tmp/test_external_cache'];
          case 'getApplicationCacheDirectory':
            return '/tmp/test_app_cache';
          default:
            return null;
        }
      });
}
