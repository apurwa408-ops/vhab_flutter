class AudioFeedbackService {
  static bool _muted = false;
  static bool get isMuted => _muted;
  static void toggleMuted() => _muted = !_muted;
  static void playPinch() {}
  static void playRelease() {}
  static void playSuccess() {}
  static void playError() {}
  static void playHoldTick([double progress = 0.0]) {}
  static void playGestureMatch() {}
  static void playLevelComplete() {}
}
