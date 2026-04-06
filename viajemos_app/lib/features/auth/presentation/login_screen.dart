import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _googleLoading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Completá todos los campos.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // El router redirige automáticamente al detectar sesión activa.
    } on AuthException catch (e) {
      setState(() => _error = _mapError(e.message));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _googleLoading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: Uri.base.origin,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      // La página redirige a Google → cuando vuelve, Supabase detecta la sesión.
    } on AuthException catch (e) {
      if (mounted) setState(() { _error = _mapError(e.message); _loading = false; _googleLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Error: $e'; _loading = false; _googleLoading = false; });
    }
    // Si el redirect nunca ocurrió (popup bloqueado, etc.), desbloquear el botón.
    await Future.delayed(const Duration(seconds: 3));
    if (mounted && _googleLoading) setState(() { _loading = false; _googleLoading = false; });
  }

  void _cancelGoogleSignIn() {
    setState(() { _loading = false; _googleLoading = false; });
  }

  String _mapError(String msg) {
    if (msg.contains('Invalid login')) return 'Email o contraseña incorrectos.';
    if (msg.contains('Email not confirmed')) return 'Confirmá tu email antes de ingresar.';
    return 'Ocurrió un error. Intentá de nuevo.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Logo / nombre
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A73E8),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.directions_car_rounded,
                          color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 16),
                    const Text('Viajemos',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B))),
                    const SizedBox(height: 6),
                    const Text('Iniciá sesión en tu cuenta',
                        style: TextStyle(
                            fontSize: 15, color: Color(0xFF64748B))),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Card principal
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Email
                    _label('EMAIL'),
                    _inputField(
                      controller: _emailController,
                      hint: 'tu@email.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // Contraseña
                    _label('CONTRASEÑA'),
                    _passwordField(),
                    const SizedBox(height: 8),

                    // Olvidé mi contraseña
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {/* TODO: reset password */},
                        child: const Text('¿Olvidaste tu contraseña?',
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1A73E8),
                                fontWeight: FontWeight.w500)),
                      ),
                    ),

                    // Error
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: Color(0xFFDC2626), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_error!,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFFDC2626))),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Botón login
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A73E8),
                          disabledBackgroundColor:
                              const Color(0xFF1A73E8).withValues(alpha: 0.6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : const Text('Ingresar',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Separador
                    Row(children: [
                      const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('o',
                            style: TextStyle(
                                fontSize: 13, color: Color(0xFF94A3B8))),
                      ),
                      const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                    ]),

                    const SizedBox(height: 20),

                    // Botón Google
                    if (_googleLoading)
                      Container(
                        height: 52,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Color(0xFF1A73E8)),
                            ),
                            const SizedBox(width: 12),
                            const Text('Redirigiendo a Google…',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF64748B))),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: _cancelGoogleSignIn,
                              child: const Text('Cancelar',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A73E8))),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _loading ? null : _signInWithGoogle,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _GoogleLogo(),
                              const SizedBox(width: 10),
                              const Text('Continuar con Google',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B))),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Registro
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    const Text('¿No tenés cuenta? ',
                        style: TextStyle(
                            fontSize: 14, color: Color(0xFF64748B))),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: const Text('Registrate',
                          style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1A73E8),
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B))),
      );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            hintStyle:
                const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
          ),
        ),
      );

  Widget _passwordField() => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _passwordController,
          obscureText: _obscure,
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline_rounded,
                color: Color(0xFF94A3B8), size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF94A3B8),
                size: 20,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            hintStyle:
                const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
          ),
        ),
      );
}

// ── Google logo (4 colores oficiales) ────────────────────────────────────────

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _coloredLetter('G', const Color(0xFF4285F4)),
        _coloredLetter('o', const Color(0xFFEA4335)),
        _coloredLetter('o', const Color(0xFFFBBC05)),
        _coloredLetter('g', const Color(0xFF4285F4)),
        _coloredLetter('l', const Color(0xFF34A853)),
        _coloredLetter('e', const Color(0xFFEA4335)),
      ],
    );
  }

  Widget _coloredLetter(String letter, Color color) => Text(
        letter,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
          height: 1,
        ),
      );
}
