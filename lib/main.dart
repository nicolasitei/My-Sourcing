import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:mysourcing2/services/database_service.dart';
import 'package:mysourcing2/services/storage_service.dart';
import 'auth/auth_screen.dart';
import 'home/home_screen.dart';
import 'theme.dart';
import 'firebase_options.dart'; // Assurez-vous que ce fichier existe

void main() async {
  // Initialisation des Widgets et de Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enregistrement des services dans GetIt
  GetIt.I.registerLazySingleton<StorageService>(() => StorageService());
  GetIt.I.registerLazySingleton<DatabaseService>(() => DatabaseService());

  // Close keyboard
  SystemChannels.textInput.invokeMethod('TextInput.hide');

  runApp(MyApp()); // Exécuter l'application après initialisation de Firebase
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key); // Rendre le constructeur de MyApp non-const car il contient une variable dynamique

  final FirebaseFirestore db = FirebaseFirestore.instance; // Initialisation de Firestore

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Formulaires Dynamiques',
      debugShowCheckedModeBanner: false,
      theme: appTheme, // Appliquer le thème personnalisé
      initialRoute: '/', // La route initiale de l'application
      routes: {
        '/': (context) => const Root(), // Définir la route d'accueil
        '/auth': (context) => const AuthScreen(), // Définir la route pour l'écran d'authentification
        '/home': (context) => const HomeScreen(), // Définir la route pour l'écran d'accueil
      },
      onGenerateRoute: (settings) {
        // Gestion des routes dynamiques
        if (settings.name == '/auth') {
          return MaterialPageRoute(builder: (_) => const AuthScreen());
        } else if (settings.name == '/home') {
          return MaterialPageRoute(builder: (_) => const HomeScreen());
        }
        return null; // Si la route n'est pas définie, retourne null
      },
    );
  }
}

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // Écouter les changements d'état d'authentification
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Si l'état est en cours de chargement, afficher un indicateur de progression
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasData) {
          // Si l'utilisateur est connecté, rediriger vers la page d'accueil
          return const HomeScreen();
        } else {
          // Si l'utilisateur n'est pas connecté, afficher l'écran d'authentification
          return const AuthScreen();
        }
      },
    );
  }
}
