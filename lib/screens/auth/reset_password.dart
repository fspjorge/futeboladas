import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';

class ResetPasswordPage extends StatefulWidget {
  // O Supabase lida com o token/sessão automaticamente via deep link.
  // Já não precisamos obrigatoriamente do código aqui, mas mantemos o parâmetro
  // para compatibilidade de rotas se necessário.
  final String? oobCode;
  const ResetPasswordPage({super.key, this.oobCode});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  bool _busy = false;

  void _show(String msg, bool error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
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
      await AuthService.instance.updatePassword(p1);
      _show('Password atualizada com sucesso!', false);
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      _show('Erro ao atualizar password: $e', true);
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
    final user = Supabase.instance.client.auth.currentUser;

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
                if (user?.email != null)
                  Text(
                    'Conta: ${user!.email}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nova password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pass2Ctrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Confirmar password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _busy ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 56),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Color(0xFF0F172A),
                          ),
                        )
                      : const Text('GUARDAR NOVA PASSWORD'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
