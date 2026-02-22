import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:futeboladas/screens/home_dashboard.dart';
import 'package:futeboladas/screens/jogos/jogos_maps.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'screens/auth/reset_password.dart';
import 'package:futeboladas/screens/jogos/jogos_form.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';

final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Locale data for Intl (pt_PT) used in DateFormat across the app
  Intl.defaultLocale = 'pt_PT';
  await initializeDateFormatting('pt_PT', null);
  // Tenta capturar links de redefinição de password (Dynamic Links ou link direto no web)
  await _setupPasswordResetLinkHandling();
  runApp(const FuteboladasApp());
}

class FuteboladasApp extends StatelessWidget {
  const FuteboladasApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF22C55E); // Pitch Green
    const deepSlate = Color(0xFF0F172A); // Background
    const slateBlue = Color(0xFF1E293B); // Surface

    final theme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: const Color(0xFF38BDF8), // Urban Sky Blue
        surface: slateBlue,
        onSurface: Colors.white,
        onSurfaceVariant: Colors.white70,
        error: const Color(0xFFEF4444),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: deepSlate,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: deepSlate,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: slateBlue,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: deepSlate,
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: slateBlue,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIconColor: Colors.white70,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: slateBlue,
        labelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide.none,
      ),
    );

    return MaterialApp(
      navigatorKey: _navKey,
      title: 'Futeboladas',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const AuthGate(),
      routes: {
        '/jogos/mapa': (_) => const JogosMapa(),
        '/jogos/novo': (_) => const JogosForm(),
        // fallback manual (caso queira abrir via url interna /auth/reset?oobCode=...)
        '/auth/reset': (ctx) {
          final uri = Uri.base;
          final code = uri.queryParameters['oobCode'];
          if (code == null || code.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Código em falta.')),
            );
          }
          return ResetPasswordPage(oobCode: code);
        },
      },
    );
  }
}

Future<void> _setupPasswordResetLinkHandling() async {
  if (kIsWeb) {
    final uri = Uri.base;
    if (uri.queryParameters['mode'] == 'resetPassword' &&
        uri.queryParameters['oobCode'] != null) {
      final code = uri.queryParameters['oobCode']!;
      // Abre a página de reset dentro da app (no web funciona com rotas)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navKey.currentState?.push(
          MaterialPageRoute(builder: (_) => ResetPasswordPage(oobCode: code)),
        );
      });
    }
    return;
  }
  // Mobile - Firebase Dynamic Links
  final initial = await FirebaseDynamicLinks.instance.getInitialLink();
  void handle(PendingDynamicLinkData? data) {
    final link = data?.link;
    if (link == null) return;
    final params = link.queryParameters;
    if (params['mode'] == 'resetPassword' && params['oobCode'] != null) {
      final code = params['oobCode']!;
      _navKey.currentState?.push(
        MaterialPageRoute(builder: (_) => ResetPasswordPage(oobCode: code)),
      );
    }
  }

  handle(initial);
  FirebaseDynamicLinks.instance.onLink.listen(handle);
}

/// Mostra login se não estiver autenticado.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  bool _needsEmailVerification(User user) {
    final providerData = user.providerData;
    final isEmailUser = providerData.any((p) => p.providerId == 'password');
    return isEmailUser && !user.emailVerified;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snap) {
        final user = snap.data;

        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (user == null) {
          return const LoginPage();
        }

        if (_needsEmailVerification(user)) {
          return VerifyEmailPage(user: user);
        }

        return HomeDashboard(user: user);
      },
    );
  }
}

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
          // Background Gradient - Urban Night Feel
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A), // Deep Slate
                  Color(0xFF020617), // Near Black
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: CustomPaint(painter: _GridPainter()),
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
                          color: cs.primary.withOpacity(0.1),
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
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
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
                          child: Divider(color: Colors.white.withOpacity(0.1)),
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
                          child: Divider(color: Colors.white.withOpacity(0.1)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.05),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.1),
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

class VerifyEmailPage extends StatefulWidget {
  final User user;
  const VerifyEmailPage({super.key, required this.user});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _sent = false;
  bool _busy = false;

  Future<void> _resend() async {
    setState(() => _busy = true);
    await widget.user.sendEmailVerification();
    setState(() {
      _sent = true;
      _busy = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email de verificação enviado.')),
    );
  }

  Future<void> _refresh() async {
    await widget.user.reload();
    final refreshed = FirebaseAuth.instance.currentUser;
    if (refreshed != null && refreshed.emailVerified) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email verificado.')));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ainda não está verificado.')),
      );
    }
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
              child: CustomPaint(painter: _GridPainter()),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.mark_email_unread_outlined,
                            size: 64,
                            color: cs.primary,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Verifica o teu email',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Enviámos um link de confirmação para:\n${widget.user.email}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white60),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: _busy ? null : _refresh,
                            child: _busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Color(0xFF0F172A),
                                    ),
                                  )
                                : const Text('Já verifiquei'),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _busy ? null : _resend,
                            child: Text(
                              _sent ? 'Reenviado!' : 'Reenviar email',
                              style: TextStyle(
                                color: _sent ? Colors.white30 : cs.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () => FirebaseAuth.instance.signOut(),
                            icon: const Icon(Icons.logout, size: 18),
                            label: const Text('Sair'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
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

class HomePage extends StatefulWidget {
  final User user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late User _user;
  bool _busy = false;

  late final GoogleSignIn _googleSignIn = kIsWeb
      ? GoogleSignIn(
          clientId:
              '704341845387-phrtrpoc86e4d8f1jkmd7unv28vo18vt.apps.googleusercontent.com',
        )
      : GoogleSignIn();

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  bool get _isEmailUser =>
      _user.providerData.any((p) => p.providerId == 'password');

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
  }

  Future<void> _updateDisplayName() async {
    final ctrl = TextEditingController(text: _user.displayName ?? '');
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Alterar nome'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'Nome'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (newName == null || newName.isEmpty) return;

    setState(() => _busy = true);
    await _user.updateDisplayName(newName);
    await _user.reload();
    _user = FirebaseAuth.instance.currentUser!;
    setState(() => _busy = false);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Nome atualizado.')));
  }

  Future<void> _changePassword() async {
    if (!_isEmailUser) return;

    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Alterar password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password atual'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: newPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nova password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    final currentPass = currentPassCtrl.text.trim();
    final newPass = newPassCtrl.text.trim();
    if (currentPass.isEmpty || newPass.isEmpty) return;

    setState(() => _busy = true);
    try {
      final cred = EmailAuthProvider.credential(
        email: _user.email!,
        password: currentPass,
      );
      await _user.reauthenticateWithCredential(cred);
      await _user.updatePassword(newPass);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password alterada.')));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: ${e.message}')));
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Eliminar conta'),
          content: const Text(
            'Tens a certeza? Isto elimina a tua conta desta app.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      await _user.delete();
      await _signOut();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        await _handleReauthForDelete();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao eliminar: ${e.message}')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleReauthForDelete() async {
    if (_isEmailUser) {
      final passCtrl = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Confirmar identidade'),
            content: TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirmar'),
              ),
            ],
          );
        },
      );

      if (ok != true) return;
      final pass = passCtrl.text.trim();
      if (pass.isEmpty) return;

      try {
        final cred = EmailAuthProvider.credential(
          email: _user.email!,
          password: pass,
        );
        await _user.reauthenticateWithCredential(cred);
        await _user.delete();
        await _signOut();
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: ${e.message}')));
      }
    } else {
      try {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return;
        final googleAuth = await googleUser.authentication;
        final cred = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await _user.reauthenticateWithCredential(cred);
        await _user.delete();
        await _signOut();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao reautenticar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _user.email ?? '(sem email)';
    final name = _user.displayName ?? 'Sem nome';
    final photo = _user.photoURL;
    final provider = _isEmailUser
        ? 'Email/Password'
        : 'Google (${_user.providerData.first.providerId})';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Futeboladas'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Terminar sessão',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: const Color(0xFF2ECC71),
                    backgroundImage: photo != null ? NetworkImage(photo) : null,
                    child: photo == null
                        ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 34,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(email),
                        const SizedBox(height: 4),
                        Text(
                          provider,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_busy) const CircularProgressIndicator(strokeWidth: 2),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Conta',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Alterar nome'),
            onTap: _busy ? null : _updateDisplayName,
          ),
          if (_isEmailUser)
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Alterar password'),
              onTap: _busy ? null : _changePassword,
            ),
          if (_isEmailUser && !_user.emailVerified)
            ListTile(
              leading: const Icon(Icons.mark_email_unread_outlined),
              title: const Text('Reenviar email de verificação'),
              onTap: _busy
                  ? null
                  : () async {
                      await _user.sendEmailVerification();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Email enviado.')),
                      );
                    },
            ),
          const SizedBox(height: 24),
          const Text(
            'Zona perigosa',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Eliminar conta'),
            iconColor: Colors.red,
            textColor: Colors.red,
            onTap: _busy ? null : _deleteAccount,
          ),
        ],
      ),
    );
  }
}
