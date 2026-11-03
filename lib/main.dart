import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme.dart';
import 'firebase_options.dart'; // dibuat oleh: flutterfire configure
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Offline persistence: transaksi tetap bisa dicatat tanpa internet.
  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: true);
  await initializeDateFormatting('id_ID');
  runApp(const FinansialKuApp());
}

class FinansialKuApp extends StatelessWidget {
  const FinansialKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinansialKu',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}
