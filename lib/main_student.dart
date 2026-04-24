import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

// Legacy entry point. The app now uses a single shared gateway.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: IchibanApp()));
}
