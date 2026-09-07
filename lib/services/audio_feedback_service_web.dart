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
  static void playPinch() {
    try {
      _jsPlayPinch();
    } catch (_) {}
  }

  static void playRelease() {
    try {
      _jsPlayRelease();
    } catch (_) {}
  }

  static void playSuccess() {
    try {
      _jsPlaySuccess();
    } catch (_) {}
  }

  static void playError() {
    try {
      _jsPlayError();
    } catch (_) {}
  }

  static void playHoldTick([double progress = 0.0]) {
    try {
      _jsPlayHoldTick(progress.toJS);
    } catch (_) {}
  }

  static void playGestureMatch() {
    try {
      _jsPlayGestureMatch();
    } catch (_) {}
  }

  static void playLevelComplete() {
    try {
      _jsPlayLevelComplete();
    } catch (_) {}
  }
}
