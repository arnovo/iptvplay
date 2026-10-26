import 'web_storage_stub.dart' if (dart.library.js_interop) 'web_storage_web.dart' as impl;

class WebStorageService {
  static Future<void> setItem(String key, String value) => impl.WebStorageHelper.setItem(key, value);
  static Future<String?> getItem(String key) => impl.WebStorageHelper.getItem(key);
  static Future<void> removeItem(String key) => impl.WebStorageHelper.removeItem(key);
}
