import 'dart:js_interop';

@JS('iptvStore.set')
external JSPromise<JSBoolean> _jsSet(JSString key, JSString value);

@JS('iptvStore.get')
external JSPromise<JSAny?> _jsGet(JSString key);

@JS('iptvStore.remove')
external JSPromise<JSBoolean> _jsRemove(JSString key);

class WebStorageHelper {
  static Future<void> setItem(String key, String value) async {
    try {
      await _jsSet(key.toJS, value.toJS).toDart;
    } catch (_) {}
  }

  static Future<String?> getItem(String key) async {
    try {
      final res = await _jsGet(key.toJS).toDart;
      if (res != null && res.isA<JSString>()) {
        return (res as JSString).toDart;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> removeItem(String key) async {
    try {
      await _jsRemove(key.toJS).toDart;
    } catch (_) {}
  }
}
