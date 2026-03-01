import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = FirebaseAuth.instance;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _isLoginMode = true;
  bool _isBusy = false;

  late final GoogleSignIn _googleSignIn = kIsWeb
      ? GoogleSignIn(
          clientId:
              '704341845387-phrtrpoc86e4d8f1jkmd7unv28vo18vt.apps.googleusercontent.com',
        )
      : GoogleSignIn();

  Future<void> _signInWithGoogle() async {
    setState(() => _isBusy = true);
    try {
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        await _auth.signInWithPopup(googleProvider);
        return;
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Erro no login Google');
    } catch (e) {
      _showError('Erro no login Google: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _submitEmail() async {
    final email = _emailCtrl.text.trim();
    final pass = _passwordCtrl.text.trim();
    final name = _nameCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      _showError('Preenche email e password.');
      return;
    }

    setState(() => _isBusy = true);
    try {
      if (_isLoginMode) {
        await _auth.signInWithEmailAndPassword(email: email, password: pass);
      } else {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: pass,
        );

        if (name.isNotEmpty) {
          await cred.user?.updateDisplayName(name);
        }

        await cred.user?.sendEmailVerification();
        _showInfo('Conta criada. Verifica o teu email.');
      }
    } on FirebaseAuthException catch (e) {
      _showError(_mapFirebaseError(e));
    } catch (e) {
      _showError('Erro: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _forgotPassword() async {
    String email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      final ctrl = TextEditingController();
      final entered = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Recuperar password'),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email da conta'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Enviar'),
            ),
          ],
        ),
      );
      if (entered == null || entered.isEmpty) return;
      email = entered;
    }

    setState(() => _isBusy = true);
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      _showInfo(
        'Se existir uma conta para $email, enviámos um email de recuperação.',
      );
    } on FirebaseAuthException catch (e) {
      _showError(_mapFirebaseError(e));
    } catch (e) {
      _showError('Erro ao enviar recuperação: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Já existe uma conta com esse email.';
      case 'invalid-email':
        return 'Email inválido.';
      case 'user-not-found':
      case 'wrong-password':
        return 'Credenciais inválidas.';
      case 'weak-password':
        return 'Password demasiado fraca.';
      default:
        return e.message ?? 'Ocorreu um erro.';
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showInfo(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F172A), Color(0xFF020617)],
              ),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: CustomPaint(painter: GridPainter()),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Hero(
                      tag: 'app_logo',
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.sports_soccer,
                          size: 64,
                          color: cs.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Futeboladas',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'O teu jogo, a tua cidade.',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Colors.white60,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 48),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _isLoginMode
                                    ? 'Bem-vindo de volta'
                                    : 'Cria a tua conta',
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 24),
                              TextField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _passwordCtrl,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                              ),
                              if (_isLoginMode)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _isBusy ? null : _forgotPassword,
                                    child: Text(
                                      'Esqueci-me da password',
                                      style: TextStyle(
                                        color: cs.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              if (!_isLoginMode) ...[
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _nameCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Nome completo',
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 32),
                              ElevatedButton(
                                onPressed: _isBusy ? null : _submitEmail,
                                child: _isBusy
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: Color(0xFF0F172A),
                                        ),
                                      )
                                    : Text(
                                        _isLoginMode ? 'Entrar' : 'Continuar',
                                      ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isLoginMode
                                        ? 'Ainda não tens conta?'
                                        : 'Já tens conta?',
                                    style: const TextStyle(
                                      color: Colors.white60,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => setState(
                                      () => _isLoginMode = !_isLoginMode,
                                    ),
                                    child: Text(
                                      _isLoginMode ? 'Regista-te' : 'Entra',
                                      style: TextStyle(
                                        color: cs.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OU CONTINUA COM',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.white30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        onPressed: _isBusy ? null : _signInWithGoogle,
                        icon: Image.network(
                          'https://developers.google.com/identity/images/g-logo.png',
                          width: 20,
                          height: 20,
                        ),
                        label: Text(
                          'Google',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
