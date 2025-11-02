import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ResetPasswordPage extends StatefulWidget {
  final String oobCode;
  const ResetPasswordPage({super.key, required this.oobCode});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  bool _busy = false;
  String? _email;

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    try {
      final email = await FirebaseAuth.instance.verifyPasswordResetCode(widget.oobCode);
      setState(() => _email = email);
    } on FirebaseAuthException catch (e) {
      _show('Código inválido ou expirado (${e.code}).', true);
    } catch (e) {
      _show('Falha ao validar código: $e', true);
    }
  }

  void _show(String msg, bool error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? Colors.red : null),
    );
  }

  Future<void> _confirm() async {
    final p1 = _passCtrl.text.trim();
    final p2 = _pass2Ctrl.text.trim();
    if (p1.isEmpty || p2.isEmpty) {
      _show('Preenche ambas as passwords.', true);
      return;
    }
    if (p1 != p2) {
      _show('As passwords não coincidem.', true);
      return;
    }
    if (p1.length < 6) {
      _show('A password deve ter pelo menos 6 caracteres.', true);
      return;
    }
    setState(() => _busy = true);
    try {
      await FirebaseAuth.instance.confirmPasswordReset(code: widget.oobCode, newPassword: p1);
      if (!mounted) return;
      _show('Password atualizada. Já podes entrar com a nova password.', false);
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on FirebaseAuthException catch (e) {
      _show(e.message ?? 'Erro ao atualizar password (${e.code}).', true);
    } catch (e) {
      _show('Erro inesperado: $e', true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Definir nova password')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_email != null)
                  Text('Conta: $_email', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Nova password', prefixIcon: Icon(Icons.lock_outline)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pass2Ctrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirmar password', prefixIcon: Icon(Icons.lock_outline)),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _confirm,
                  child: _busy
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Guardar nova password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

