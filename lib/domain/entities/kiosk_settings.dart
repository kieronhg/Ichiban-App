import 'package:equatable/equatable.dart';

class KioskSettings extends Equatable {
  final String kioskExitPinHash;
  final DateTime kioskExitPinSetAt;
  final String kioskExitPinSetByAdminId;

  const KioskSettings({
    required this.kioskExitPinHash,
    required this.kioskExitPinSetAt,
    required this.kioskExitPinSetByAdminId,
  });

  KioskSettings copyWith({
    String? kioskExitPinHash,
    DateTime? kioskExitPinSetAt,
    String? kioskExitPinSetByAdminId,
  }) {
    return KioskSettings(
      kioskExitPinHash: kioskExitPinHash ?? this.kioskExitPinHash,
      kioskExitPinSetAt: kioskExitPinSetAt ?? this.kioskExitPinSetAt,
      kioskExitPinSetByAdminId:
          kioskExitPinSetByAdminId ?? this.kioskExitPinSetByAdminId,
    );
  }

  @override
  List<Object?> get props => [
    kioskExitPinHash,
    kioskExitPinSetAt,
    kioskExitPinSetByAdminId,
  ];
}
