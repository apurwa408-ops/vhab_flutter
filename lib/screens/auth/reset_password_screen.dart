import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

/// Shown when a user lands on the app via a Supabase PASSWORD_RECOVERY link.
/// Allows the user to enter and confirm a new password.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _success = false;
  String? _localError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _localError = null);
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final error = await auth.updatePassword(_passwordController.text);
    if (!mounted) return;

    if (error != null) {
      setState(() => _localError = error);
    } else {
      setState(() => _success = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      body: Stack(
        children: [
          const _BackgroundGlow(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 42),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF152420).withOpacity(0.14),
                          blurRadius: 34,
                          offset: const Offset(0, 18),
                        )
                      ],
                    ),
                    child: _success
                        ? _buildSuccess(auth)
                        : _buildForm(auth),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(AuthProvider auth) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo
        _logo(),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF1D7A65).withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded,
              color: Color(0xFF1D7A65), size: 48),
        ),
        const SizedBox(height: 22),
        Text(
          'Password updated!',
          style: GoogleFonts.outfit(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF152420),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Your new password has been saved. You can now sign in with your new credentials.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6C7A73),
              height: 1.55),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => auth.exitPasswordRecoveryMode(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D7A65),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11)),
              elevation: 4,
            ),
            child: Text(
              'Back to Sign In',
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(AuthProvider auth) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo row
          _logo(),
          const SizedBox(height: 30),

          // Title
          Text(
            'Set new password',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF152420),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Enter a strong new password for your V-Hab account.',
            style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFF6C7A73), height: 1.55),
          ),
          const SizedBox(height: 26),

          // New password field
          _field(
            controller: _passwordController,
            label: 'New password',
            icon: Icons.lock_outline_rounded,
            validator: (v) =>
                v == null || v.length < 6 ? 'Use at least 6 characters' : null,
            obscureText: _obscurePassword,
            suffix: IconButton(
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(_obscurePassword
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded),
            ),
          ),
          const SizedBox(height: 14),

          // Confirm password field
          _field(
            controller: _confirmController,
            label: 'Confirm new password',
            icon: Icons.lock_outline_rounded,
            validator: (v) => v != _passwordController.text
                ? 'Passwords do not match'
                : null,
            obscureText: _obscureConfirm,
            suffix: IconButton(
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              icon: Icon(_obscureConfirm
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded),
            ),
          ),

          // Error message
          if (_localError != null) ...[
            const SizedBox(height: 12),
            Text(
              _localError!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ],

          const SizedBox(height: 22),

          // Submit button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: auth.isBusy ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D7A65),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11)),
                elevation: 4,
              ),
              child: auth.isBusy
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Update password',
                          style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => auth.exitPasswordRecoveryMode(),
              child: Text(
                'Cancel – back to sign in',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF6C7A73),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logo() {
    return Row(children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF2F9E86), Color(0xFF4C8FE0)]),
          borderRadius: BorderRadius.circular(9),
        ),
        child:
            const Icon(Icons.pan_tool_alt_rounded, color: Colors.white, size: 17),
      ),
      const SizedBox(width: 9),
      Text('V-Hab',
          style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF152420))),
    ]);
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: GoogleFonts.inter(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6C7A73)),
        prefixIcon: Icon(icon, size: 17, color: const Color(0xFF6C7A73)),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFFBFCFB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: Color(0x14152420))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: Color(0x14152420))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: Color(0xFF1D7A65))),
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(children: [
        Positioned(
            left: -120,
            top: -120,
            child: _blob(const Color(0xFF4C8FE0), 480)),
        Positioned(
            right: -160,
            top: -60,
            child: _blob(const Color(0xFFF2A65A), 520)),
        Positioned(
            left: 180,
            bottom: -260,
            child: _blob(const Color(0xFF2F9E86), 560)),
      ]),
    );
  }

  Widget _blob(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.12),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.18),
                blurRadius: 70,
                spreadRadius: 20)
          ],
        ),
      );
}
