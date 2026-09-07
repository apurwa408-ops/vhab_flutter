import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/exercise_provider.dart';
import 'providers/patient_provider.dart';
import 'providers/therapist_provider.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/patient/patient_shell.dart';
import 'screens/therapist/therapist_shell.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageService = await StorageService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(storageService)),
        ChangeNotifierProvider(create: (_) => ExerciseProvider(storageService)),
        ChangeNotifierProvider(create: (_) => PatientProvider(storageService)),
        ChangeNotifierProvider(create: (_) => TherapistProvider(storageService)),
      ],
      child: const VRRehabApp(),
    ),
  );
}

class VRRehabApp extends StatelessWidget {
  const VRRehabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          switch (auth.currentRole) {
            case UserRole.patient:
              return const PatientShell();
            case UserRole.therapist:
              return const TherapistShell();
            case null:
              return const WelcomeScreen();
          }
        },
      ),
    );
  }
}
