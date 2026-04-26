import 'package:equatable/equatable.dart';

class AppSetup extends Equatable {
  const AppSetup({
    required this.setupComplete,
    this.setupCompletedAt,
    this.setupCompletedByAdminId,
  });

  final bool setupComplete;
  final DateTime? setupCompletedAt;
  final String? setupCompletedByAdminId;

  @override
  List<Object?> get props => [
    setupComplete,
    setupCompletedAt,
    setupCompletedByAdminId,
  ];
}
