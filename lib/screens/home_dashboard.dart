import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'jogos/jogos_lista.dart';
import 'jogos/jogos_maps.dart';
import 'perfil/perfil_page.dart';
import '../widgets/grid_backdrop.dart';

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
        toolbarHeight: 56,
        title: _tab == 0
            ? _buildSearchBarCompact(cs)
            : Text(
                'Mapa',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, size: 22),
            color: Colors.white70,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PerfilPage(user: widget.user),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(color: Theme.of(context).scaffoldBackgroundColor),
          ),
          const Positioned.fill(child: GridBackdrop(opacity: 0.03)),
          SafeArea(child: _tab == 0 ? _buildLista(cs) : _buildMapa()),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(cs),
      floatingActionButton: _tab == 0 ? _buildFAB(cs) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  Widget _buildFAB(ColorScheme cs) {
    return FloatingActionButton.extended(
      onPressed: () async {
        final ok = await Navigator.of(context).pushNamed('/jogos/novo');
        if (ok == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Jogo agendado com sucesso! ⚽',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      icon: const Icon(Icons.add_rounded),
      label: Text(
        'AGENDAR',
        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
      ),
      backgroundColor: cs.primary,
      foregroundColor: const Color(0xFF0F172A),
      elevation: 4,
      highlightElevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildSearchBarCompact(ColorScheme cs) {
    final hasText = _searchQuery.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      constraints: const BoxConstraints(maxWidth: 240, maxHeight: 38),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasText
              ? cs.primary.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  color: hasText
                      ? cs.primary.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Pesquisar...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: hasText ? cs.primary : Colors.white24,
                  size: 16,
                ),
                suffixIcon: hasText
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white24,
                          size: 14,
                        ),
                        onPressed: () => setState(() {
                          _searchCtrl.clear();
                          _searchQuery = '';
                        }),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                isDense: true,
              ),
            ),
          ],
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          const SizedBox(height: 12),
          JogosLista(searchQuery: _searchQuery),
        ],
      ),
    );
  }

  Widget _buildMapa() => const JogosMapa();

  Widget _buildBottomBar(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.85),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
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
          color: selected
              ? cs.primary.withValues(alpha: 0.1)
              : Colors.transparent,
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
