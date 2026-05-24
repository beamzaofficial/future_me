import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/local_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final storage = await LocalStorageService.create();

  runApp(
    FutureMeApp(
      storage: storage,
      authService: AuthService(),
      firestoreService: FirestoreService(),
    ),
  );
}

class FutureMeApp extends StatelessWidget {
  final LocalStorageService storage;
  final AuthService authService;
  final FirestoreService firestoreService;
  const FutureMeApp({
    super.key,
    required this.storage,
    required this.authService,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<LocalStorageService>.value(value: storage),
        Provider<FirestoreService>.value(value: firestoreService),
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider(create: (_) => ThemeProvider(storage)),
      ],
      child: const App(),
    );
  }
}
