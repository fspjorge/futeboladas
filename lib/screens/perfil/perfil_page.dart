import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../widgets/grid_backdrop.dart';

class PerfilPage extends StatefulWidget {
  final User user;
  const PerfilPage({super.key, required this.user});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
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
    if (mounted) Navigator.pop(context);
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
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() => _busy = true);
    try {
      final cred = EmailAuthProvider.credential(
        email: _user.email!,
        password: currentPass,
      );
      await _user.reauthenticateWithCredential(cred);
      if (!mounted) return;
      await _user.updatePassword(newPass);
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Password alterada.')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Erro: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
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
      if (!mounted) return;
      await _signOut();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      if (e.code == 'requires-recent-login') {
        await _handleReauthForDelete();
      } else {
        messenger.showSnackBar(
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
        if (!mounted) return;
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
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao reautenticar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'PERFIL',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: Container(color: const Color(0xFF0F172A))),
          const Positioned.fill(child: GridBackdrop(opacity: 0.03)),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              children: [
                const SizedBox(height: 10),
                _buildHeader(cs),
                const SizedBox(height: 30),
                _buildSectionTitle('DEFINIÇÕES', cs),
                const SizedBox(height: 12),
                _buildOptionTile(
                  icon: Icons.person_outline_rounded,
                  label: 'Alterar nome',
                  onTap: _busy ? () {} : _updateDisplayName,
                  cs: cs,
                ),
                if (_isEmailUser)
                  _buildOptionTile(
                    icon: Icons.lock_outline_rounded,
                    label: 'Alterar password',
                    onTap: _busy ? () {} : _changePassword,
                    cs: cs,
                  ),
                const Divider(color: Colors.white10, height: 30),
                _buildOptionTile(
                  icon: Icons.logout_rounded,
                  label: 'Terminar Sessão',
                  color: Colors.white70,
                  onTap: _busy ? () {} : _signOut,
                  cs: cs,
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('ZONA PERIGOSA', cs),
                const SizedBox(height: 12),
                _buildOptionTile(
                  icon: Icons.delete_outline_rounded,
                  label: 'Eliminar Conta',
                  color: Colors.redAccent,
                  onTap: _busy ? () {} : _deleteAccount,
                  cs: cs,
                ),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: cs.primary.withValues(alpha: 0.2),
                backgroundImage: _user.photoURL != null
                    ? NetworkImage(_user.photoURL!)
                    : null,
                child: _user.photoURL == null
                    ? Icon(Icons.person_rounded, size: 50, color: cs.primary)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                _user.displayName ?? 'Jogador',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _user.email ?? '',
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.white60),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: cs.primary.withValues(alpha: 0.5),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    required ColorScheme cs,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (color ?? Colors.white).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color ?? cs.primary, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: color ?? Colors.white,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white30,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
