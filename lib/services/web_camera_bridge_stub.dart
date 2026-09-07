class WebCameraBridge {
  static Future<bool> startCamera() async => false;
  static void stopCamera() {}
  static void setPipVisible(bool visible) {}
  static bool isRunning() => false;
  static void initEventListener(void Function(Map<String, dynamic>) onPose) {}
}
