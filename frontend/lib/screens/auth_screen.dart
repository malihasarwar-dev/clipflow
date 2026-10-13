import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../services/api_service.dart';
import '../state/auth_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';
import '../widgets/gradient_button.dart';

/// Sign up / Log in / Continue with Google. Routing to '/' happens automatically via go_router.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signup = false, _busy = false, _obscure = true;
  String? _error;

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthState>();
    _run(() => _signup
        ? auth.signup(_name.text, _email.text, _password.text)
        : auth.login(_email.text, _password.text));
  }

  Widget _pitch() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  gradient: CF.brandGradient, borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.bolt_rounded, size: 26),
            ),
            const SizedBox(width: 12),
            const Text('ClipFlow',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          ]),
          const SizedBox(height: 40),
          ShaderMask(
            shaderCallback: (r) => CF.brandGradient.createShader(r),
            child: const Text('One long video.\nA week of Shorts.',
                style: TextStyle(
                    fontSize: 52, height: 1.05, fontWeight: FontWeight.w800, letterSpacing: -1.5)),
          ),
          const SizedBox(height: 20),
          const Text(
              'Paste a YouTube link. ClipFlow finds the strongest hooks, crops to vertical and burns in captions.',
              style: TextStyle(fontSize: 17, height: 1.5, color: CF.textDim)),
        ],
      );

  Widget _googleButton() => OutlinedButton(
        onPressed: _busy ? null : () => _run(context.read<AuthState>().signInWithGoogle),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
          backgroundColor: Colors.white.withValues(alpha: 0.06),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Text('G',
                style: TextStyle(
                    color: Color(0xFF4285F4), fontWeight: FontWeight.w900, fontSize: 14)),
          ),
          const SizedBox(width: 12),
          const Text('Continue with Google',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
        ]),
      );

  Widget _formCard() => GlassCard(
        glow: CF.violet,
        padding: const EdgeInsets.all(30),
        child: Form(
          key: _form,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(_signup ? 'Create your account' : 'Welcome back',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(_signup ? 'Start turning videos into Shorts.' : 'Log in to your clipper dashboard.',
                style: const TextStyle(color: CF.textDim)),
            const SizedBox(height: 24),
            _googleButton(),
            const SizedBox(height: 20),
            Row(children: [
              const Expanded(child: Divider(color: Colors.white12)),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or use email', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12.5))),
              const Expanded(child: Divider(color: Colors.white12)),
            ]),
            const SizedBox(height: 20),
            if (_signup) ...[
              TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(hintText: 'Name'),
                  textInputAction: TextInputAction.next),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(hintText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim()))
                  ? 'Enter a valid email address.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  (_signup && (v == null || v.length < 8)) ? 'Use at least 8 characters.' : (v == null || v.isEmpty ? 'Enter your password.' : null),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: const TextStyle(color: CF.danger, fontSize: 13.5)),
            ],
            const SizedBox(height: 22),
            GradientButton(
                label: _signup ? 'Create account' : 'Log in',
                expanded: true,
                loading: _busy,
                onPressed: _submit),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _busy ? null : () => setState(() {
                  _signup = !_signup;
                  _error = null;
                }),
                child: Text(_signup ? 'Have an account? Log in' : 'New here? Create an account',
                    style: const TextStyle(color: CF.cyan, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth >= 960;
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1160),
                  child: Padding(
                    padding: EdgeInsets.all(wide ? 48 : 20),
                    child: wide
                        ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                            Expanded(flex: 6, child: _pitch()),
                            const SizedBox(width: 64),
                            Expanded(flex: 5, child: _formCard()),
                          ])
                        : Column(mainAxisSize: MainAxisSize.min, children: [
                            const SizedBox(height: 16),
                            _formCard(),
                          ]),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
