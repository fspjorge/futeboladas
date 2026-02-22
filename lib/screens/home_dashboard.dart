import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'jogos/jogos_lista.dart';
import 'package:futeboladas/main.dart' show HomePage;

class HomeDashboard extends StatelessWidget {
  final User user;
  const HomeDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(context, cs),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Futeboladas',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(color: Theme.of(context).scaffoldBackgroundColor),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: CustomPaint(painter: _GridBackdropPainter()),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                _headerSection(context, user, cs),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Próximos Jogos',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const JogosLista(),
                const SizedBox(height: 80), // Space for FAB
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-agendar',
        backgroundColor: cs.primary,
        foregroundColor: const Color(0xFF0F172A),
        icon: const Icon(Icons.add, weight: 700),
        label: Text(
          'AGENDAR JOGO',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        onPressed: () async {
          final ok = await Navigator.of(context).pushNamed('/jogos/novo');
          if (ok == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Jogo agendado com sucesso!')),
            );
          }
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, ColorScheme cs) {
    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              user.displayName ?? 'Jogador',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            accountEmail: Text(user.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: cs.primary.withOpacity(0.2),
              child: user.photoURL != null
                  ? ClipOval(child: Image.network(user.photoURL!))
                  : Icon(Icons.person, color: cs.primary, size: 32),
            ),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
            ),
          ),
          _drawerItem(
            Icons.map_outlined,
            'Explorar Mapa',
            () => Navigator.of(context).pushNamed('/jogos/mapa'),
          ),
          _drawerItem(Icons.people_outline, 'Meus Amigos', () {}),
          _drawerItem(Icons.emoji_events_outlined, 'Estatísticas', () {}),
          const Spacer(),
          Divider(color: Colors.white.withOpacity(0.05)),
          _drawerItem(Icons.settings_outlined, 'Definições da Conta', () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => HomePage(user: user)));
          }),
          _drawerItem(Icons.logout, 'Terminar Sessão', () async {
            await FirebaseAuth.instance.signOut();
          }, color: Colors.redAccent),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _drawerItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white70, size: 24),
      title: Text(
        label,
        style: TextStyle(
          color: color ?? Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _headerSection(BuildContext context, User user, ColorScheme cs) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: cs.primary.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage: user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : null,
                  backgroundColor: cs.primary.withOpacity(0.1),
                  child: user.photoURL == null
                      ? Icon(Icons.person, color: cs.primary, size: 30)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, ${user.displayName?.split(' ').first ?? 'Jogador'}!',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'CRAQUE URBANO',
                        style: GoogleFonts.outfit(
                          color: cs.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
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
}

class _GridBackdropPainter extends CustomPainter {
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
