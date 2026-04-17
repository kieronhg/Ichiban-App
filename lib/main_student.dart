import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

// Entry point for the Student shared-device flavor.
// Run with: flutter run -t lib/main_student.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: IchibanApp(flavor: AppFlavor.student)));
}
