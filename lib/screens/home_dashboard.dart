import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'jogos/jogos_lista.dart';
import 'jogos/jogos_maps.dart';
import 'perfil_page.dart'; // nova página de perfil (criar depois)
import 'package:futeboladas/main.dart' show HomePage;

class HomeDashboard extends StatefulWidget {
  final User user;
  const HomeDashboard({super.key, required this.user});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  int _tab = 0;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Título dinâmico: searchbar na tab Lista, título normal na tab Mapa
        title: _tab == 0
            ? _buildSearchBarCompact(cs)
            : Text(
                'Mapa',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
        // Ações: ícone do perfil sempre visível
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            color: Colors.white70,
            onPressed: () {
              // Navegar para a página de perfil (substitui o drawer)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PerfilPage(user: widget.user),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
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
            child: _tab == 0
                ? _buildLista(cs) // sem searchbar aqui
                : _buildMapa(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(cs),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              heroTag: 'fab-agendar',
              backgroundColor: cs.primary,
              foregroundColor: const Color(0xFF0F172A),
              icon: const Icon(Icons.add, weight: 700),
              label: Text(
                'AGENDAR',
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
            )
          : null,
    );
  }

  // Versão compacta da searchbar para caber na AppBar
  Widget _buildSearchBarCompact(ColorScheme cs) {
    final hasText = _searchQuery.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(maxWidth: 280),
          decoration: BoxDecoration(
            color: hasText
                ? cs.primary.withOpacity(0.08)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasText
                  ? cs.primary.withOpacity(0.4)
                  : Colors.white.withOpacity(0.08),
              width: hasText ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Pesquisar jogos...',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: hasText ? cs.primary : Colors.white30,
                size: 18,
              ),
              suffixIcon: hasText
                  ? IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.white30,
                        size: 16,
                      ),
                      onPressed: () => setState(() {
                        _searchCtrl.clear();
                        _searchQuery = '';
                      }),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              isDense: true,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLista(ColorScheme cs) {
    return RefreshIndicator(
      onRefresh: () async =>
          await Future.delayed(const Duration(milliseconds: 500)),
      color: cs.primary,
      backgroundColor: const Color(0xFF1E293B),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        children: [
          // Searchbar removida daqui – agora está na AppBar
          const SizedBox(height: 20),
          JogosLista(searchQuery: _searchQuery),
        ],
      ),
    );
  }

  Widget _buildMapa() => const JogosMapa();

  Widget _buildBottomBar(ColorScheme cs) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.85),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.06)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Expanded(child: _tabItem(0, Icons.list_rounded, 'Lista', cs)),
                  Expanded(child: _tabItem(1, Icons.map_outlined, 'Mapa', cs)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabItem(int index, IconData icon, String label, ColorScheme cs) {
    final selected = _tab == index;
    return InkWell(
      onTap: () => setState(() => _tab = index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected
                  ? (index == 0 ? Icons.list_rounded : Icons.map_rounded)
                  : icon,
              color: selected ? cs.primary : Colors.white30,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: selected ? cs.primary : Colors.white30,
              ),
            ),
          ],
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
