import 'package:material_ui/material_ui.dart';

import '../data/data.dart';
import '../logic/mood.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/plant_avatar.dart';

/// Screen 1. Sign in (M1).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: kUseFirebase ? '' : 'aigul@tamyr.app');
  final _password = TextEditingController();
  bool _loading = false;
  bool _hide = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await authRepository.signIn(_email.text, _password.text);
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Try again');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Hero(),
                    const SizedBox(height: 18),
                    Text('Plants that talk to you', style: nunito(30, FontWeight.w900, height: 1.1, spacing: -0.8)),
                    const SizedBox(height: 6),
                    Text('Eco club of School No. 12, Kyzylorda', style: nunito(14, FontWeight.w700, color: AppColors.muted)),
                    const SizedBox(height: 18),
                    _Field(
                      controller: _email,
                      hint: 'Email',
                      icon: Icons.mail_outline_rounded,
                      keyboard: TextInputType.emailAddress,
                      autofill: AutofillHints.email,
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      controller: _password,
                      hint: 'Password',
                      icon: Icons.lock_outline_rounded,
                      obscure: _hide,
                      autofill: AutofillHints.password,
                      onSubmitted: (_) => _loading ? null : _signIn(),
                      suffix: IconButton(
                        tooltip: _hide ? 'Show password' : 'Hide password',
                        icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.muted),
                        onPressed: () => setState(() => _hide = !_hide),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: const Color(0xFFFFE9E7), borderRadius: BorderRadius.circular(20)),
                        child: Row(children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.red),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!, style: nunito(14, FontWeight.w800, color: const Color(0xFFC62F35)))),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 22),
                    PillButton(label: 'Sign in', loading: _loading, onTap: _signIn),
                    if (!kUseFirebase) ...[
                      const SizedBox(height: 14),
                      Text('Demo: aigul@tamyr.app or school5@tamyr.app · password123',
                          textAlign: TextAlign.center, style: nunito(12, FontWeight.w700, color: AppColors.muted)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 330,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(38),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE4F5DF), Color(0xFFCDEBC6)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: -40,
            right: -40,
            bottom: -80,
            height: 190,
            child: Container(decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(200))),
          ),
          Positioned(
            left: 22,
            top: 24,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const StatusChip(label: 'School greenhouse', background: Color(0xB3FFFFFF), foreground: Color(0xFF3F6B45)),
              const SizedBox(height: 10),
              Text('Tamyr', style: nunito(44, FontWeight.w900, spacing: -1.4, height: 1)),
            ]),
          ),
          const Positioned(right: 22, top: 18, child: _Tilted(-6, PlantAvatar(cropKey: 'greens', mood: Mood.happy, size: 92))),
          const Positioned(left: 6, bottom: 34, child: _Tilted(-10, PlantAvatar(cropKey: 'cucumber', mood: Mood.happy, size: 110))),
          const Positioned(right: 6, bottom: 38, child: _Tilted(9, PlantAvatar(cropKey: 'strawberry', mood: Mood.happy, size: 106))),
          const Align(
            alignment: Alignment(0, 1),
            child: Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: GlowAvatar(cropKey: 'tomato', mood: Mood.happy, size: 138, animate: true),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tilted extends StatelessWidget {
  const _Tilted(this.degrees, this.child);
  final double degrees;
  final Widget child;
  @override
  Widget build(BuildContext context) => Transform.rotate(angle: degrees * 3.14159 / 180, child: child);
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboard,
    this.obscure = false,
    this.autofill,
    this.onSubmitted,
    this.suffix,
  });
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboard;
  final bool obscure;
  final String? autofill;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) => SoftCard(
        radius: 29,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: TextField(
          controller: controller,
          keyboardType: keyboard,
          obscureText: obscure,
          autofillHints: autofill == null ? null : [autofill!],
          onSubmitted: onSubmitted,
          style: nunito(16, FontWeight.w800),
          decoration: InputDecoration(
            hintText: hint,
            labelText: hint,
            floatingLabelBehavior: FloatingLabelBehavior.never,
            fillColor: Colors.white,
            prefixIcon: Icon(icon, color: AppColors.muted),
            suffixIcon: suffix,
          ),
        ),
      );
}
