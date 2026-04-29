import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class IchibanApp extends ConsumerStatefulWidget {
  const IchibanApp({super.key});

  @override
  ConsumerState<IchibanApp> createState() => _IchibanAppState();
}

class _IchibanAppState extends ConsumerState<IchibanApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.router(ref: ref);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Ichiban',
      theme: AppTheme.light,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
