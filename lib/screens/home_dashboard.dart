import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'jogos/jogos_lista.dart';
import 'package:futeboladas/main.dart' show HomePage;

class HomeDashboard extends StatelessWidget {
  final User user;
  const HomeDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final colorPrimary = const Color(0xFF2ECC71);
    final colorAccent = const Color(0xFF1A1A1A);
    final colorCard = Colors.white.withValues(alpha: 0.95);

    return Scaffold(
      backgroundColor: colorAccent,
      appBar: AppBar(
        backgroundColor: colorAccent,
        elevation: 0,
        title: const Text(
          'Futeboladas',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _headerSection(user, colorPrimary),
            const SizedBox(height: 30),
            _sectionTitle('Próximos Jogos'),
            const SizedBox(height: 10),
            const JogosLista(),
            const SizedBox(height: 30),
            _sectionTitle('Atalhos rapidos'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _quickButton(Icons.map, 'Mapa', colorPrimary, colorCard, () {
                  Navigator.of(context).pushNamed('/jogos/mapa');
                }),
                _quickButton(Icons.add, 'Agendar', colorPrimary, colorCard, () async {
                  final ok = await Navigator.of(context).pushNamed('/jogos/novo');
                  if (ok == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Jogo agendado.')),
                    );
                  }
                }),
                _quickButton(Icons.people, 'Jogadores', colorPrimary, colorCard, () {}),
                _quickButton(Icons.bar_chart, 'Estatísticas', colorPrimary, colorCard, () {}),
                _quickButton(Icons.settings, 'Conta', colorPrimary, colorCard, () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => HomePage(user: user)),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerSection(User user, Color colorPrimary) {
    return Row(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
          backgroundColor: colorPrimary.withValues(alpha: 0.2),
          child: user.photoURL == null
              ? const Icon(Icons.person, color: Colors.white, size: 40)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName ?? 'Jogador',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                user.email ?? '',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    );
  }

  Widget _quickButton(IconData icon, String label, Color colorPrimary, Color colorCard, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: colorPrimary),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}



