import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/exercise.dart';
import 'games/gesture_match_game.dart';
import 'games/path_trace_game.dart';
import 'games/pinch_master_game.dart';
import 'games/shape_drag_game.dart';
import 'games/steady_hold_game.dart';

class GameLauncher {
  static Widget createGameWidget(ExerciseModel exercise, ExerciseLevel level) {
    switch (exercise.id) {
      case AppConstants.exercisePinching:
        return PinchMasterGame(exercise: exercise, level: level);
      case AppConstants.exerciseHolding:
        return SteadyHoldGame(exercise: exercise, level: level);
      case AppConstants.exerciseTracing:
        return PathTraceGame(exercise: exercise, level: level);
      case AppConstants.exerciseDragging:
        return ShapeDragGame(exercise: exercise, level: level);
      case AppConstants.exerciseGesture:
        return GestureMatchGame(exercise: exercise, level: level);
      default:
        return PinchMasterGame(exercise: exercise, level: level);
    }
  }

  static void launchGame(
      BuildContext context, ExerciseModel exercise, ExerciseLevel level) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => createGameWidget(exercise, level),
      ),
    );
  }
}
