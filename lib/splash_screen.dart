import 'dart:async';
import 'package:flutter/material.dart';
import 'home/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Sourcing',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Open Sans',  // Définir la police par défaut ici
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Timeout pour rediriger vers l'écran principal après 3 secondes
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Cette couleur sera utilisée pour l'écriture "My Sourcing"
    const splashTextColor = Color(0xFF0085AF);

    return Scaffold(
      backgroundColor: Colors.white, // Fond blanc pour le splash screen
      body: Center(
        child: Text(
          'My Sourcing',  // Texte à afficher
          style: TextStyle(
            color: splashTextColor,  // Appliquer la couleur bleue personnalisée
            fontSize: 32,  // Taille doublée de la police
            fontWeight: FontWeight.w500,  // Poids de la police
            fontFamily: 'Open Sans',  // Police Open Sans
          ),
        ),
      ),
    );
  }
}
