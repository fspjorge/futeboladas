import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'games/games_list.dart';
import 'games/games_maps.dart';
import 'profile/profile_page.dart';
import '../widgets/grid_backdrop.dart';
import '../main.dart';

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
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        titleSpacing: _tab == 0 ? 16 : NavigationToolbar.kMiddleSpacing,
        title: _tab == 0
            ? _buildSearchBarSofa(cs)
            : Text(
                'Mapa',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, size: 28),
            color: Colors.white,
            padding: const EdgeInsets.only(right: 16),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilePage(user: widget.user),
                ),
              );
            },
          ),
          if (_tab != 0) const SizedBox(width: 12),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildFAB(ColorScheme cs) {
    return FloatingActionButton(
      onPressed: () async {
        final ok = await Navigator.of(context).pushNamed('/games/new');
        if (ok == true && mounted) {
          scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text(
                'Game agendado com sucesso! ⚽',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      backgroundColor: cs.primary,
      foregroundColor: const Color(0xFF0F172A),
      elevation: 4,
      highlightElevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.add_rounded, size: 32),
    );
  }

  Widget _buildSearchBarSofa(ColorScheme cs) {
    final hasText = _searchQuery.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Pesquisar jogos...',
              hintStyle: GoogleFonts.outfit(
                color: Colors.white38,
                fontSize: 15,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Colors.white38,
                size: 22,
              ),
              suffixIcon: hasText
                  ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white38,
                        size: 20,
                      ),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 13,
                horizontal: 12,
              ),
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          const SizedBox(height: 12),
          GamesList(searchQuery: _searchQuery),
        ],
      ),
    );
  }

  Widget _buildMapa() => const GamesMaps();

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
