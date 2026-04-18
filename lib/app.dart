import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

enum AppFlavor { admin, student }

class IchibanApp extends ConsumerWidget {
  final AppFlavor flavor;
  const IchibanApp({super.key, required this.flavor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = flavor == AppFlavor.admin
        ? AppRouter.adminRouter(ref: ref)
        : AppRouter.studentRouter(ref: ref);

    return MaterialApp.router(
      title: 'Ichiban',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
