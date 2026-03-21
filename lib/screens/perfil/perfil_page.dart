import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../widgets/grid_backdrop.dart';
import '../../widgets/glass_card.dart';

class PerfilPage extends StatefulWidget {
  final User user;
  final FirebaseAuth? auth;
  const PerfilPage({super.key, required this.user, this.auth});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> with WidgetsBindingObserver {
  late final _auth = widget.auth ?? FirebaseAuth.instance;
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
    setState(() => _busy = true);
    try {
      await _auth.signOut();
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erro ao sair: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _updateDisplayName() async {
    final name = await _showModernEditDialog(
      title: 'Alterar Nome',
      initialValue: _user.displayName ?? '',
      hint: 'O teu nome de jogador',
      icon: Icons.person_outline_rounded,
    );

    if (name == null || name.trim().isEmpty || name == _user.displayName) {
      return;
    }

    setState(() => _busy = true);
    try {
      await _user.updateDisplayName(name.trim());
      await _user.reload();
      _user = _auth.currentUser!;
      if (mounted) {
        _showSnackBar('Nome atualizado com sucesso! 🤝');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erro ao atualizar nome: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _changePassword() async {
    if (!_isEmailUser) {
      return;
    }

    final result = await _showModernEditDialog(
      title: 'Nova Password',
      initialValue: '',
      hint: 'Mínimo 6 caracteres',
      icon: Icons.lock_outline_rounded,
      isPassword: true,
      confirmLabel: 'Alterar',
    );

    if (result == null || result.trim().length < 6) {
      if (result != null) {
        _showSnackBar('Password demasiado curta.', isError: true);
      }
      return;
    }

    setState(() => _busy = true);
    try {
      // For password change, we usually need recent re-auth, but let's try direct update first
      // since the user just logged in or is active.
      await _user.updatePassword(result.trim());
      if (mounted) {
        _showSnackBar('Password alterada com sucesso! 🔐');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login' && mounted) {
        _showSnackBar(
          'Por segurança, precisas de entrar novamente na app.',
          isError: true,
        );
      } else if (mounted) {
        _showSnackBar('Erro: ${e.message}', isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erro inesperado: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ModernConfirmDialog(
        title: 'Eliminar Conta',
        message:
            'Esta ação é irreversível. Perderás todo o teu histórico de jogos e presenças.',
        confirmLabel: 'ELIMINAR',
        isDestructive: true,
      ),
    );

    if (confirm != true) {
      return;
    }

    setState(() => _busy = true);
    try {
      await _user.delete();
      if (mounted) {
        _showSnackBar('Conta eliminada. Sentiremos a tua falta! 👋');
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login' && mounted) {
        _showSnackBar(
          'Para eliminar, precisas de ter feito login recentemente.',
          isError: true,
        );
      } else if (mounted) {
        _showSnackBar('Erro: ${e.message}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<String?> _showModernEditDialog({
    required String title,
    required String initialValue,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    String confirmLabel = 'Guardar',
  }) {
    final ctrl = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xFF10B981), size: 32),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: ctrl,
                obscureText: isPassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.white60),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, ctrl.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: const Color(0xFF0F172A),
                        minimumSize: const Size(0, 48), // Dialog size
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        confirmLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Perfil',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: Container(color: const Color(0xFF0F172A))),
          const Positioned.fill(child: GridBackdrop(opacity: 0.03)),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                _buildProfileHeader(cs),
                const SizedBox(height: 24),
                _buildSectionTitle('CONTA'),
                _buildOptionTile(
                  icon: Icons.person_outline_rounded,
                  label: 'Alterar nome',
                  onTap: _updateDisplayName,
                ),
                if (_isEmailUser)
                  _buildOptionTile(
                    icon: Icons.lock_outline_rounded,
                    label: 'Alterar password',
                    onTap: _changePassword,
                  ),

                const SizedBox(height: 20),
                _buildSectionTitle('APLICAÇÃO'),
                _buildOptionTile(
                  icon: Icons.logout_rounded,
                  label: 'Terminar Sessão',
                  onTap: _signOut,
                ),
                _buildOptionTile(
                  icon: Icons.delete_outline_rounded,
                  label: 'Eliminar Conta',
                  onTap: _deleteAccount,
                  isDestructive: true,
                ),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF10B981),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(ColorScheme cs) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: cs.primary.withValues(alpha: 0.1),
                  backgroundImage: _user.photoURL != null
                      ? NetworkImage(_user.photoURL!)
                      : null,
                  child: _user.photoURL == null
                      ? Icon(Icons.person_rounded, size: 36, color: cs.primary)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _user.displayName ?? 'Jogador',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _user.email ?? '',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.white38,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF10B981).withValues(alpha: 0.4),
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        opacity: 0.03,
        borderRadius: 12,
        child: InkWell(
          onTap: _busy ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? Colors.redAccent.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive
                        ? Colors.redAccent.withValues(alpha: 0.8)
                        : const Color(0xFF10B981),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDestructive
                          ? Colors.redAccent.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.1),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final bool isDestructive;

  const _ModernConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.transparent,
      contentPadding: EdgeInsets.zero,
      content: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDestructive
                  ? Icons.warning_amber_rounded
                  : Icons.help_outline_rounded,
              color: isDestructive ? Colors.redAccent : const Color(0xFF10B981),
              size: 40,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white60),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDestructive
                          ? Colors.redAccent
                          : const Color(0xFF10B981),
                      foregroundColor: const Color(0xFF0F172A),
                      minimumSize: const Size(0, 48), // Dialog size
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      confirmLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
