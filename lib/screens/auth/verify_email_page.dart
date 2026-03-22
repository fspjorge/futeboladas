import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/grid_backdrop.dart';

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
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: widget.user.email,
      );
      setState(() {
        _sent = true;
        _busy = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email de verificação enviado.')),
      );
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao reenviar: $e')));
    }
  }

  Future<void> _refresh() async {
    // No Supabase, refrescar o utilizador para ver se o email_confirmed_at mudou
    await Supabase.instance.client.auth.getUser();
    final refreshed = Supabase.instance.client.auth.currentUser;
    if (refreshed != null && refreshed.emailConfirmedAt != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email verificado.')));
      // Navigator should pop or push to home via AuthGate
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
          const GridBackdrop(opacity: 0.03),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: GlassCard(
                  borderRadius: 32,
                  padding: const EdgeInsets.all(32),
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
                          fontSize: 20,
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
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
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
                        onPressed: () =>
                            Supabase.instance.client.auth.signOut(),
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Sair'),
                      ),
                    ],
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
