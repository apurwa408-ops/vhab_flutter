import 'dart:convert';
import 'dart:js_interop';

@JS('vhabHandTracker.start')
external JSPromise<JSBoolean> _jsStart();

@JS('vhabHandTracker.stop')
external void _jsStop();

@JS('vhabHandTracker.setPipVisible')
external void _jsSetPipVisible(JSBoolean visible);

@JS('vhabHandTracker.isRunning')
external JSBoolean _jsIsRunning();

@JS('vhabOnPoseUpdate')
external set _jsOnPoseUpdate(JSFunction? callback);

class WebCameraBridge {
  static Future<bool> startCamera() async {
    try {
      final res = await _jsStart().toDart;
      return res.toDart;
    } catch (_) {
      return false;
    }
  }

  static void stopCamera() {
    try {
      _jsStop();
    } catch (_) {}
  }

  static void setPipVisible(bool visible) {
    try {
      _jsSetPipVisible(visible.toJS);
    } catch (_) {}
  }

  static bool isRunning() {
    try {
      return _jsIsRunning().toDart;
    } catch (_) {
      return false;
    }
  }

  static void initEventListener(void Function(Map<String, dynamic>) onPose) {
    _jsOnPoseUpdate = ((JSString jsonStr) {
      try {
        final map = jsonDecode(jsonStr.toDart) as Map<String, dynamic>;
        onPose(map);
      } catch (_) {}
    }).toJS;
  }
}
