import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

import 'firebase_options.dart';
import 'screens/auth/reset_password.dart';
import 'screens/games/game_form.dart';
import 'screens/games/games_maps.dart';
import 'theme/app_theme.dart';
import 'widgets/auth/auth_gate.dart';

final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Google Maps Android renderer and Hybrid Composition
  final GoogleMapsFlutterPlatform mapsImplementation =
      GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    mapsImplementation.useAndroidViewSurface = true;
    try {
      await mapsImplementation.initializeWithRenderer(
        AndroidMapRenderer.latest,
      );
    } catch (e) {
      debugPrint('Erro ao inicializar renderizador de mapas: $e');
    }
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.deviceCheck,
      // webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    );
  } catch (e) {
    debugPrint('Erro no AppCheck: $e');
  }

  // Locale data for Intl (pt_PT) used in DateFormat across the app
  Intl.defaultLocale = 'pt_PT';
  await initializeDateFormatting('pt_PT', null);

  // Captura links de redefinição de password
  await _setupPasswordResetLinkHandling();

  runApp(const FuteboladasApp());
}

class FuteboladasApp extends StatelessWidget {
  const FuteboladasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'Futeboladas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: const Locale('pt', 'PT'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'PT')],
      home: const AuthGate(),
      routes: {
        '/games/map': (_) => const GamesMaps(),
        '/games/new': (_) => const GameForm(),
        '/auth/reset': (ctx) {
          final uri = Uri.base;
          final code = uri.queryParameters['oobCode'];
          if (code == null || code.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Código em falta.')),
            );
          }
          return ResetPasswordPage(oobCode: code);
        },
      },
    );
  }
}

// ignore_for_file: deprecated_member_use
Future<void> _setupPasswordResetLinkHandling() async {
  if (kIsWeb) {
    final uri = Uri.base;
    if (uri.queryParameters['mode'] == 'resetPassword' &&
        uri.queryParameters['oobCode'] != null) {
      final code = uri.queryParameters['oobCode']!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_navKey.currentState?.context.mounted ?? false) {
          _navKey.currentState?.push(
            MaterialPageRoute(builder: (_) => ResetPasswordPage(oobCode: code)),
          );
        }
      });
    }
    return;
  }

  // Mobile - Firebase Dynamic Links
  final initial = await FirebaseDynamicLinks.instance.getInitialLink();
  void handle(PendingDynamicLinkData? data) {
    final link = data?.link;
    if (link == null) return;
    final params = link.queryParameters;
    if (params['mode'] == 'resetPassword' && params['oobCode'] != null) {
      final code = params['oobCode']!;
      _navKey.currentState?.push(
        MaterialPageRoute(builder: (_) => ResetPasswordPage(oobCode: code)),
      );
    }
  }

  handle(initial);
  FirebaseDynamicLinks.instance.onLink.listen(handle);
}
