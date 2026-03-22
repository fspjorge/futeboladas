import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:futeboladas/screens/auth/login_page.dart';
import 'package:futeboladas/screens/home_dashboard.dart';
import '../../services/auth_service.dart';
import '../../services/game_service.dart';
import '../../services/attendance_service.dart';

class AuthGate extends StatelessWidget {
  final AuthService? authService;
  final GameService? gameService;
  final AttendanceService? attendanceService;

  const AuthGate({
    super.key,
    this.authService,
    this.gameService,
    this.attendanceService,
  });

  AuthService get _auth => authService ?? AuthService.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _auth.authStateChanges,
      builder: (context, snap) {
        final session = snap.data?.session;
        final user = session?.user;

        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (user == null) {
          return LoginPage(authService: _auth);
        }

        // No Supabase, a verificação de email pode ser gerida por políticas de RLS
        // ou verificando o campo email_confirmed_at.
        // Por agora, vamos assumir que o login é suficiente.

        return HomeDashboard(
          user: user,
          gameService: gameService,
          attendanceService: attendanceService,
          authService: _auth,
        );
      },
    );
  }
}
