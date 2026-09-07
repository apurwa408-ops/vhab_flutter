import 'dart:js_interop';

@JS('vhabAudio.playPinch')
external void _jsPlayPinch();

@JS('vhabAudio.playRelease')
external void _jsPlayRelease();

@JS('vhabAudio.playSuccess')
external void _jsPlaySuccess();

@JS('vhabAudio.playError')
external void _jsPlayError();

@JS('vhabAudio.playHoldTick')
external void _jsPlayHoldTick(JSNumber progress);

@JS('vhabAudio.playGestureMatch')
external void _jsPlayGestureMatch();

@JS('vhabAudio.playLevelComplete')
external void _jsPlayLevelComplete();

class AudioFeedbackService {
  static bool _muted = false;

  static bool get isMuted => _muted;

  static void toggleMuted() => _muted = !_muted;

  static void playPinch() {
    if (_muted) return;
    try {
      _jsPlayPinch();
    } catch (_) {}
  }

  static void playRelease() {
    if (_muted) return;
    try {
      _jsPlayRelease();
    } catch (_) {}
  }

  static void playSuccess() {
    if (_muted) return;
    try {
      _jsPlaySuccess();
    } catch (_) {}
  }

  static void playError() {
    if (_muted) return;
    try {
      _jsPlayError();
    } catch (_) {}
  }

  static void playHoldTick([double progress = 0.0]) {
    if (_muted) return;
    try {
      _jsPlayHoldTick(progress.toJS);
    } catch (_) {}
  }

  static void playGestureMatch() {
    if (_muted) return;
    try {
      _jsPlayGestureMatch();
    } catch (_) {}
  }

  static void playLevelComplete() {
    if (_muted) return;
    try {
      _jsPlayLevelComplete();
    } catch (_) {}
  }
}
