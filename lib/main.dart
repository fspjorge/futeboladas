import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:futeboladas/screens/home_dashboard.dart';
import 'package:futeboladas/screens/jogos/jogos_maps.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'screens/auth/reset_password.dart';
import 'package:futeboladas/screens/jogos/jogos_form.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_options.dart';

final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Tenta capturar links de redefiniÃ§Ã£o de password (Dynamic Links ou link direto no web)
  await _setupPasswordResetLinkHandling();
  runApp(const FuteboladasApp());
}

class FuteboladasApp extends StatelessWidget {
  const FuteboladasApp({super.key});

  @override
  Widget build(BuildContext context) {
    final seed = const Color(0xFF2ECC71); // verde relva

    return MaterialApp(
      navigatorKey: _navKey,
      title: 'Futeboladas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          primary: seed,
          secondary: const Color(0xFF34495E), // urbano
          surface: const Color(0xFFEAEDED),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFEAEDED),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2ECC71),
          foregroundColor: Colors.white,
          elevation: 4,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: seed,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: seed,
            side: BorderSide(color: seed),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        chipTheme: const ChipThemeData(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        ),
      ),
      home: const AuthGate(),
      routes: {
        '/jogos/mapa': (_) => const JogosMapa(),
        '/jogos/novo': (_) => const JogosForm(),
        // fallback manual (caso queira abrir via url interna /auth/reset?oobCode=...)
        '/auth/reset': (ctx) {
          final uri = Uri.base;
          final code = uri.queryParameters['oobCode'];
          if (code == null || code.isEmpty) {
            return const Scaffold(body: Center(child: Text('CÃ³digo em falta.')));
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
    if (uri.queryParameters['mode'] == 'resetPassword' && uri.queryParameters['oobCode'] != null) {
      final code = uri.queryParameters['oobCode']!;
      // Abre a pÃ¡gina de reset dentro da app (no web funciona com rotas)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navKey.currentState?.push(MaterialPageRoute(builder: (_) => ResetPasswordPage(oobCode: code)));
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
      _navKey.currentState?.push(MaterialPageRoute(builder: (_) => ResetPasswordPage(oobCode: code)));
    }
  }
  handle(initial);
  FirebaseDynamicLinks.instance.onLink.listen(handle);
}

/// Mostra login se nÃ£o estiver autenticado.
/// Se estiver autenticado mas o email nÃ£o estiver verificado (e for email/password),
/// mostra ecrÃ£ para verificar.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  bool _needsEmailVerification(User user) {
    final providerData = user.providerData;
    final isEmailUser =
        providerData.any((p) => p.providerId == 'password'); // email/pass
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

        // nÃ£o autenticado
        if (user == null) {
          return const LoginPage();
        }

        // autenticado mas sem email verificado
        if (_needsEmailVerification(user)) {
          return VerifyEmailPage(user: user);
        }

        // autenticado e ok
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

  // para login/registo por email
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _isLoginMode = true;
  bool _isBusy = false;

  // Google Sign-In
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
        // no web o Firebase Auth jÃ¡ faz o popup
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
        // login
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: pass,
        );
      } else {
        // registo
        final cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: pass,
        );

        // atualizar nome
        if (name.isNotEmpty) {
          await cred.user?.updateDisplayName(name);
        }

        // enviar email de verificaÃ§Ã£o
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Enviar')),
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
      _showInfo('Se existir uma conta para $email, enviÃ¡mos um email de recuperaÃ§Ã£o.');
    } on FirebaseAuthException catch (e) {
      _showError(_mapFirebaseError(e));
    } catch (e) {
      _showError('Erro ao enviar recuperaÃ§Ã£o: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'JÃ¡ existe uma conta com esse email.';
      case 'invalid-email':
        return 'Email invÃ¡lido.';
      case 'user-not-found':
      case 'wrong-password':
        return 'Credenciais invÃ¡lidas.';
      case 'weak-password':
        return 'Password demasiado fraca.';
      default:
        return e.message ?? 'Ocorreu um erro.';
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _showInfo(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
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
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.15),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sports_soccer, size: 34, color: Color(0xFF2ECC71)),
                    const SizedBox(width: 8),
                    Text(
                      'Futeboladas',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: const Color(0xFF2C3E50),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  _isLoginMode ? 'Entrar' : 'Criar conta',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 20),

                // email
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
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
                      child: const Text('Esqueci-me da password'),
                    ),
                  ),
                if (!_isLoginMode) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'SerÃ¡ enviado um email de verificaÃ§Ã£o.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isBusy ? null : _submitEmail,
                    icon: _isBusy
                        ? const SizedBox(
                            width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: Text(_isLoginMode ? 'Entrar' : 'Criar conta'),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_isLoginMode ? 'Ainda nÃ£o tens conta?' : 'JÃ¡ tens conta?'),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLoginMode = !_isLoginMode;
                        });
                      },
                      child: Text(_isLoginMode ? 'Registar' : 'Entrar'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isBusy ? null : _signInWithGoogle,
                    icon: Image.network(
                      'https://developers.google.com/identity/images/g-logo.png',
                      width: 18,
                      height: 18,
                    ),
                    label: const Text('Entrar com Google'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// EcrÃ£ mostrado quando a conta de email existe mas ainda nÃ£o foi verificada.
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
    setState(() {
      _busy = true;
    });
    await widget.user.sendEmailVerification();
    setState(() {
      _sent = true;
      _busy = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email de verificaÃ§Ã£o enviado.')),
    );
  }

  Future<void> _refresh() async {
    await widget.user.reload();
    final refreshed = FirebaseAuth.instance.currentUser;
    if (refreshed != null && refreshed.emailVerified) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email verificado.')),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ainda nÃ£o estÃ¡ verificado.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.user.email ?? '(sem email)';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar email'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'EnviÃ¡mos um email de verificaÃ§Ã£o para:',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                email,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _busy ? null : _resend,
                child: Text(_sent ? 'Reenviar novamente' : 'Reenviar email'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _refresh,
                child: const Text('JÃ¡ confirmei'),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                child: const Text('Sair'),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Guardar')),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nome atualizado.')),
    );
  }

  Future<void> _changePassword() async {
    // sÃ³ para email/pass
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
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
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
      // reautenticar
      final cred = EmailAuthProvider.credential(
        email: _user.email!,
        password: currentPass,
      );
      await _user.reauthenticateWithCredential(cred);

      // alterar
      await _user.updatePassword(newPass);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password alterada.')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${e.message}')),
      );
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
              'Tens a certeza? Isto elimina a tua conta desta app.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      await _user.delete();
      // terminar sessÃ£o tambÃ©m
      await _signOut();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // temos de reautenticar
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
      // pedir password
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
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${e.message}')),
        );
      }
    } else {
      // Google
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao reautenticar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _user.email ?? '(sem email)';
    final name = _user.displayName ?? 'Sem nome';
    final photo = _user.photoURL;
    final provider =
        _isEmailUser ? 'Email/Password' : 'Google (${_user.providerData.first.providerId})';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Futeboladas'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Terminar sessÃ£o',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                        ? const Icon(Icons.person, color: Colors.white, size: 34)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600)),
                        Text(email),
                        const SizedBox(height: 4),
                        Text(
                          provider,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
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
              title: const Text('Reenviar email de verificaÃ§Ã£o'),
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
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
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


