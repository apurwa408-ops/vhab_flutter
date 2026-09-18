import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/exercise_provider.dart';
import 'providers/patient_provider.dart';
import 'providers/therapist_provider.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/patient/patient_shell.dart';
import 'screens/therapist/therapist_shell.dart';
import 'services/storage_service.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageService = await StorageService.init();
  await SupabaseService.instance.init(storage: storageService);

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

class VRRehabApp extends StatefulWidget {
  const VRRehabApp({super.key});

  @override
  State<VRRehabApp> createState() => _VRRehabAppState();
}

class _VRRehabAppState extends State<VRRehabApp> {
  @override
  void initState() {
    super.initState();
    // Listen for Supabase PASSWORD_RECOVERY events.
    // When received, notify AuthProvider so it can show the reset screen.
    final stream = SupabaseService.instance.authStateStream;
    if (stream != null) {
      stream.listen((authState) {
        if (!mounted) return;
        if (authState.event == AuthChangeEvent.passwordRecovery) {
          debugPrint('[VRRehabApp] PASSWORD_RECOVERY event received.');
          context.read<AuthProvider>().enterPasswordRecoveryMode();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // PASSWORD_RECOVERY: user arrived via reset link — show set-new-password screen
          if (auth.passwordRecoveryMode) {
            return const ResetPasswordScreen();
          }
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
