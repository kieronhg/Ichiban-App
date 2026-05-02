import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class KioskModeState {
  const KioskModeState({this.isActive = false, this.exitPinHash});

  final bool isActive;
  final String? exitPinHash;

  bool checkPin(String pin) {
    if (exitPinHash == null) return false;
    return sha256.convert(utf8.encode(pin)).toString() == exitPinHash;
  }
}

class KioskModeNotifier extends Notifier<KioskModeState> {
  @override
  KioskModeState build() => const KioskModeState();

  void activate(String exitPin) {
    final hash = sha256.convert(utf8.encode(exitPin)).toString();
    state = KioskModeState(isActive: true, exitPinHash: hash);
  }

  void deactivate() => state = const KioskModeState();
}

final kioskModeProvider = NotifierProvider<KioskModeNotifier, KioskModeState>(
  KioskModeNotifier.new,
);
