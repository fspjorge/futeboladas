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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user.displayName ?? 'Jogador'),
              accountEmail: Text(user.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.black54),
              ),
              decoration: BoxDecoration(color: colorPrimary),
            ),
            ListTile(
              leading: Icon(Icons.map),
              title: Text('Mapa'),
              onTap: () { Navigator.of(context).pushNamed('/jogos/mapa'); },
            ),
            ListTile(
              leading: Icon(Icons.people),
              title: Text('Jogadores'),
              onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Em breve'))); },
            ),
            ListTile(
              leading: Icon(Icons.bar_chart),
              title: Text('Estatísticas'),
              onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Em breve'))); },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Conta'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => HomePage(user: user)),
                );
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Sair'),
              onTap: () async { await FirebaseAuth.instance.signOut(); },
            ),
          ],
        ),
      ),
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
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-agendar',
        icon: const Icon(Icons.add),
        label: const Text('Agendar'),
        onPressed: () async {
          final ok = await Navigator.of(context).pushNamed('/jogos/novo');
          if (ok == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Jogo agendado.')),
            );
          }
        },
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

