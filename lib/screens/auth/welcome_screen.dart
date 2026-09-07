import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/rehab_motion_panel.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistering = false;
  bool _obscurePassword = true;
  UserRole _role = UserRole.patient;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    auth.clearError();
    if (_isRegistering) {
      await auth.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        role: _role,
      );
    } else {
      await auth.login(_emailController.text, _passwordController.text);
    }
  }

  void _setMode(bool registering) {
    context.read<AuthProvider>().clearError();
    setState(() => _isRegistering = registering);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final wide = MediaQuery.sizeOf(context).width >= 680;
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
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 13, child: _buildHero()),
                            const SizedBox(width: 22),
                            Expanded(flex: 10, child: _buildAuth(auth)),
                          ],
                        )
                      : Column(
                          children: [
                            _buildHero(compact: true),
                            const SizedBox(height: 18),
                            _buildAuth(auth),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero({bool compact = false}) {
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 420 : 650),
      padding: EdgeInsets.fromLTRB(compact ? 26 : 42, compact ? 30 : 44, compact ? 26 : 42, 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D7A65), Color(0xFF2F9E86), Color(0xFF4C8FE0), Color(0xFF6C7FE3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: const Color(0xFF1D7A65).withOpacity(0.28), blurRadius: 34, offset: const Offset(0, 18))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _glassPill(Icons.pan_tool_alt_rounded, 'Hand rehabilitation'),
          const SizedBox(height: 20),
          Text(
            'Train with purpose.\nRecover with confidence.',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: compact ? 32 : 42, fontWeight: FontWeight.w600, height: 1.08),
          ),
          const SizedBox(height: 14),
          Text(
            'Interactive upper-limb rehabilitation with adaptive exercises, real-time hand tracking, and clinically useful progress insights.',
            style: GoogleFonts.inter(color: Colors.white.withOpacity(0.86), fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: compact ? 220 : 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(width: compact ? 300 : 390, child: const RehabMotionPanel()),
                Positioned(top: 18, left: compact ? 0 : 10, child: _heroStat(Icons.track_changes_rounded, 'Grip strength', '+12% this week')),
                Positioned(bottom: 18, right: compact ? 0 : 12, child: _heroStat(Icons.local_fire_department_rounded, '6-day streak', 'Keep it up')),
                Positioned(top: 30, right: compact ? 0 : 28, child: _heroStat(Icons.star_rounded, '4.9 / 5', 'from patients')),
              ],
            ),
          ),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              _heroChip(Icons.sports_esports_rounded, 'Motor games'),
              _heroChip(Icons.insights_rounded, 'Progress analytics'),
              _heroChip(Icons.pan_tool_alt_rounded, 'Hand tracking'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuth(AuthProvider auth) {
    return Container(
      constraints: const BoxConstraints(minHeight: 650),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 42),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: const Color(0xFF152420).withOpacity(0.14), blurRadius: 34, offset: const Offset(0, 18))],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 350),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Container(width: 32, height: 32, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF2F9E86), Color(0xFF4C8FE0)]), borderRadius: BorderRadius.circular(9)), child: const Icon(Icons.pan_tool_alt_rounded, color: Colors.white, size: 17)),
                      const SizedBox(width: 9),
                      Text('V-Hab', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w600, color: const Color(0xFF152420))),
                    ]),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Color(0xFFE3F4EF), borderRadius: BorderRadius.all(Radius.circular(11))),
                      child: Row(children: [
                        _tab('Sign in', !_isRegistering),
                        _tab('Create account', _isRegistering),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 34),
                Text(_isRegistering ? 'Create your account' : 'Welcome back', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w600, color: const Color(0xFF152420))),
                const SizedBox(height: 7),
                Text(_isRegistering ? 'Set up your rehabilitation profile and start building consistency.' : 'Sign in with your email and password to continue your recovery plan.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6C7A73), height: 1.55)),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.local_hospital_outlined, size: 16),
                  label: Text('Continue with clinic SSO', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF152420),
                    disabledForegroundColor: const Color(0xFF152420),
                    minimumSize: const Size.fromHeight(44),
                    side: const BorderSide(color: Color(0x14152420)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(child: Divider(color: Color(0x14152420))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or continue with email', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF6C7A73))),
                    ),
                    const Expanded(child: Divider(color: Color(0x14152420))),
                  ],
                ),
                const SizedBox(height: 20),
                if (_isRegistering) ...[
                  _field(_nameController, 'Full name', Icons.person_outline_rounded, (v) => v == null || v.trim().length < 2 ? 'Enter your full name' : null),
                  const SizedBox(height: 14),
                  SegmentedButton<UserRole>(
                    segments: const [
                      ButtonSegment(value: UserRole.patient, label: Text('Patient'), icon: Icon(Icons.person_rounded)),
                      ButtonSegment(value: UserRole.therapist, label: Text('Therapist'), icon: Icon(Icons.medical_services_rounded)),
                    ],
                    selected: {_role},
                    onSelectionChanged: (values) => setState(() => _role = values.first),
                  ),
                  const SizedBox(height: 14),
                ],
                _field(_emailController, 'Email address', Icons.mail_outline_rounded, (v) => v == null || !v.contains('@') ? 'Enter a valid email address' : null, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 14),
                _field(_passwordController, 'Password', Icons.lock_outline_rounded, (v) => v == null || v.length < 6 ? 'Use at least 6 characters' : null, obscureText: _obscurePassword, suffix: IconButton(onPressed: () => setState(() => _obscurePassword = !_obscurePassword), icon: Icon(_obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded))),
                if (!_isRegistering) ...[
                  const SizedBox(height: 12),
                  Row(children: [const Icon(Icons.check_box_outline_blank_rounded, size: 16, color: Color(0xFF6C7A73)), const SizedBox(width: 7), Text('Remember me', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6C7A73))), const Spacer(), Text('Forgot password?', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1D7A65)))]),
                ],
                if (auth.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(auth.errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: auth.isBusy ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D7A65), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)), elevation: 4),
                    child: auth.isBusy ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_isRegistering ? 'Create account' : 'Sign in', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)), const SizedBox(width: 8), const Icon(Icons.arrow_forward_rounded, size: 18)]),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_isRegistering ? 'Already have an account? ' : 'New to V-Hab? ', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6C7A73))),
                    GestureDetector(onTap: () => _setMode(!_isRegistering), child: Text(_isRegistering ? 'Sign in' : 'Create an account', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1D7A65)))),
                  ],
                ),
                const SizedBox(height: 20),
                Text('V-HAB is a clinically-informed rehabilitation training prototype, not a diagnostic system.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF9AA6A0), height: 1.55)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(String label, bool selected) {
    return GestureDetector(
      onTap: () => _setMode(label == 'Create account'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: selected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(8), boxShadow: selected ? [const BoxShadow(color: Color(0x1A152420), blurRadius: 5)] : null),
        child: Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: selected ? const Color(0xFF152420) : const Color(0xFF6C7A73))),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon, String? Function(String?) validator, {TextInputType? keyboardType, bool obscureText = false, Widget? suffix}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: GoogleFonts.inter(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6C7A73)),
        prefixIcon: Icon(icon, size: 17, color: const Color(0xFF6C7A73)),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFFBFCFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: Color(0x14152420))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: Color(0x14152420))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: Color(0xFF1D7A65))),
      ),
    );
  }

  Widget _glassPill(IconData icon, String label) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), border: Border.all(color: Colors.white.withOpacity(0.28)), borderRadius: BorderRadius.circular(30)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white, size: 15), const SizedBox(width: 7), Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))]));

  Widget _heroChip(IconData icon, String label) => Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), border: Border.all(color: Colors.white.withOpacity(0.24)), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white, size: 15), const SizedBox(width: 7), Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600))]));

  Widget _heroStat(IconData icon, String title, String subtitle) => Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9), decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), border: Border.all(color: Colors.white.withOpacity(0.28)), borderRadius: BorderRadius.circular(14)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: const Color(0xFFFFCE7A), size: 19), const SizedBox(width: 7), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)), Text(subtitle, style: GoogleFonts.inter(color: Colors.white70, fontSize: 8))])]));
}

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(children: [
        Positioned(left: -120, top: -120, child: _blob(const Color(0xFF4C8FE0), 480)),
        Positioned(right: -160, top: -60, child: _blob(const Color(0xFFF2A65A), 520)),
        Positioned(left: 180, bottom: -260, child: _blob(const Color(0xFF2F9E86), 560)),
      ]),
    );
  }

  Widget _blob(Color color, double size) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.12), boxShadow: [BoxShadow(color: color.withOpacity(0.18), blurRadius: 70, spreadRadius: 20)]));
}
