import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:futeboladas/screens/auth/login_page.dart';
import 'package:futeboladas/screens/auth/verify_email_page.dart';
import 'package:futeboladas/screens/home_dashboard.dart';

class AuthGate extends StatelessWidget {
  final FirebaseAuth? auth;
  const AuthGate({super.key, this.auth});

  bool _needsEmailVerification(User user) {
    final providerData = user.providerData;
    final isEmailUser = providerData.any((p) => p.providerId == 'password');
    return isEmailUser && !user.emailVerified;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: (auth ?? FirebaseAuth.instance).userChanges(),
      builder: (context, snap) {
        final user = snap.data;

        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (user == null) {
          return LoginPage(auth: auth);
        }

        if (_needsEmailVerification(user)) {
          return VerifyEmailPage(user: user);
        }

        return HomeDashboard(user: user);
      },
    );
  }
}
