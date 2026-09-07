import 'dart:math';
import 'package:flutter/material.dart';
import 'web_camera_bridge.dart';

enum HandTrackingMode {
  simulatedPointer,
  webcamComputerVision,
  virtualRealityHardware,
}

class HandPoseState {
  final Offset normalizedPosition;
  final bool isInteracting;
  final double pinchStrength;
  final double gripStrength;
  final String activeGesture;
  final double stabilityIndex; // 0 to 100
  final bool isHandDetected;
  final double pinchDistance;
  final List<Offset> landmarks;

  const HandPoseState({
    this.normalizedPosition = const Offset(0.5, 0.5),
    this.isInteracting = false,
    this.pinchStrength = 0.0,
    this.gripStrength = 0.0,
    this.activeGesture = 'open_hand',
    this.stabilityIndex = 95.0,
    this.isHandDetected = false,
    this.pinchDistance = 0.15,
    this.landmarks = const [],
  });

  HandPoseState copyWith({
    Offset? normalizedPosition,
    bool? isInteracting,
    double? pinchStrength,
    double? gripStrength,
    String? activeGesture,
    double? stabilityIndex,
    bool? isHandDetected,
    double? pinchDistance,
    List<Offset>? landmarks,
  }) {
    return HandPoseState(
      normalizedPosition: normalizedPosition ?? this.normalizedPosition,
      isInteracting: isInteracting ?? this.isInteracting,
      pinchStrength: pinchStrength ?? this.pinchStrength,
      gripStrength: gripStrength ?? this.gripStrength,
      activeGesture: activeGesture ?? this.activeGesture,
      stabilityIndex: stabilityIndex ?? this.stabilityIndex,
      isHandDetected: isHandDetected ?? this.isHandDetected,
      pinchDistance: pinchDistance ?? this.pinchDistance,
      landmarks: landmarks ?? this.landmarks,
    );
  }
}

/// Hand Tracking Input Service (HAL).
/// Connects Google MediaPipe Hands computer vision tracking to all exercises.
class HandTrackingInputService extends ChangeNotifier {
  static final HandTrackingInputService instance =
      HandTrackingInputService._internal();

  factory HandTrackingInputService() => instance;

  HandTrackingInputService._internal() {
    _initBridgeListener();
  }

  HandTrackingMode mode = HandTrackingMode.webcamComputerVision;
  HandPoseState _currentState = const HandPoseState();

  bool _isWebcamActive = false;
  bool _isPipVisible = true;
  final List<Offset> _recentPositions = [];
  static const int _maxPositionHistory = 15;

  HandPoseState get currentState => _currentState;
  bool get isWebcamActive => _isWebcamActive;
  bool get isPipVisible => _isPipVisible;
  bool get isHandDetected => _currentState.isHandDetected;
  Offset get normalizedPosition => _currentState.normalizedPosition;
  bool get isPinching => _currentState.isInteracting;
  double get pinchStrength => _currentState.pinchStrength;
  double get gripStrength => _currentState.gripStrength;
  String get activeGesture => _currentState.activeGesture;
  double get stabilityIndex => _currentState.stabilityIndex;
  List<Offset> get landmarks => _currentState.landmarks;

  void _initBridgeListener() {
    WebCameraBridge.initEventListener((data) {
      updateFromCamera(data);
    });
  }

  Future<bool> startWebcamTracking() async {
    final success = await WebCameraBridge.startCamera();
    _isWebcamActive = success;
    if (success) {
      mode = HandTrackingMode.webcamComputerVision;
      WebCameraBridge.setPipVisible(_isPipVisible);
    }
    notifyListeners();
    return success;
  }

  void stopWebcamTracking() {
    WebCameraBridge.stopCamera();
    WebCameraBridge.setPipVisible(false);
    _isWebcamActive = false;
    _currentState = _currentState.copyWith(isHandDetected: false);
    notifyListeners();
  }

  void togglePip() {
    _isPipVisible = !_isPipVisible;
    if (_isWebcamActive) {
      WebCameraBridge.setPipVisible(_isPipVisible);
    }
    notifyListeners();
  }

  void setPipVisible(bool visible) {
    _isPipVisible = visible;
    if (_isWebcamActive) {
      WebCameraBridge.setPipVisible(visible);
    }
    notifyListeners();
  }

  void updateFromCamera(Map<String, dynamic> data) {
    final isDetected = data['isHandDetected'] as bool? ?? false;
    if (!isDetected) {
      _currentState = _currentState.copyWith(
        isHandDetected: false,
        isInteracting: false,
      );
      notifyListeners();
      return;
    }

    final x = (data['x'] as num?)?.toDouble() ?? 0.5;
    final y = (data['y'] as num?)?.toDouble() ?? 0.5;
    final isPinch = data['isPinching'] as bool? ?? false;
    final pinchStr = (data['pinchStrength'] as num?)?.toDouble() ?? 0.0;
    final gripStr = (data['gripStrength'] as num?)?.toDouble() ?? 0.0;
    final gesture = data['gesture'] as String? ?? 'open_hand';
    final stability = (data['stability'] as num?)?.toDouble() ?? 92.0;
    final pinchDist = (data['pinchDistance'] as num?)?.toDouble() ?? 0.15;

    final rawLandmarks = data['landmarks'] as List<dynamic>? ?? [];
    final List<Offset> parsedLandmarks = rawLandmarks.map((pt) {
      final m = pt as Map<String, dynamic>;
      final lx = (m['x'] as num?)?.toDouble() ?? 0.0;
      final ly = (m['y'] as num?)?.toDouble() ?? 0.0;
      return Offset(lx, ly);
    }).toList();

    _currentState = HandPoseState(
      normalizedPosition: Offset(x, y),
      isInteracting: isPinch,
      pinchStrength: pinchStr,
      gripStrength: gripStr,
      activeGesture: gesture,
      stabilityIndex: stability,
      isHandDetected: true,
      pinchDistance: pinchDist,
      landmarks: parsedLandmarks,
    );

    notifyListeners();
  }

  void updatePointer(Offset localPos, Size bounds, {bool isPressed = false}) {
    final nx = (localPos.dx / bounds.width).clamp(0.0, 1.0);
    final ny = (localPos.dy / bounds.height).clamp(0.0, 1.0);
    final normPos = Offset(nx, ny);

    _recentPositions.add(normPos);
    if (_recentPositions.length > _maxPositionHistory) {
      _recentPositions.removeAt(0);
    }

    final stability = _computeStability();

    _currentState = _currentState.copyWith(
      normalizedPosition: normPos,
      isInteracting: isPressed,
      pinchStrength: isPressed ? 1.0 : 0.0,
      gripStrength: isPressed ? 0.9 : 0.0,
      stabilityIndex: stability,
      isHandDetected: true,
    );
    notifyListeners();
  }

  void setGesture(String gesture) {
    _currentState = _currentState.copyWith(activeGesture: gesture);
    notifyListeners();
  }

  double _computeStability() {
    if (_recentPositions.length < 3) return 95.0;
    double totalVariance = 0.0;
    for (int i = 1; i < _recentPositions.length; i++) {
      final p1 = _recentPositions[i - 1];
      final p2 = _recentPositions[i];
      final dist = sqrt(pow(p2.dx - p1.dx, 2) + pow(p2.dy - p1.dy, 2));
      totalVariance += dist;
    }
    final avgDelta = totalVariance / (_recentPositions.length - 1);
    final stability = (100.0 - (avgDelta * 800)).clamp(30.0, 99.0);
    return double.parse(stability.toStringAsFixed(1));
  }

  void reset() {
    _recentPositions.clear();
    _currentState = const HandPoseState();
    notifyListeners();
  }
}
