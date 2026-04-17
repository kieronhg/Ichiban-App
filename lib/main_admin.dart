import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

// Entry point for the Admin / Coach / Owner flavor.
// Run with: flutter run -t lib/main_admin.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: IchibanApp(flavor: AppFlavor.admin)));
}
