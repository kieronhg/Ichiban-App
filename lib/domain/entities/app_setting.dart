import 'package:equatable/equatable.dart';

class AppSetting extends Equatable {
  final String key;
  final dynamic value;

  const AppSetting({required this.key, required this.value});

  AppSetting copyWith({String? key, dynamic value}) {
    return AppSetting(
      key: key ?? this.key,
      value: value ?? this.value,
    );
  }

  int get intValue => (value as num).toInt();
  double get doubleValue => (value as num).toDouble();
  String get stringValue => value as String;
  bool get boolValue => value as bool;

  @override
  List<Object?> get props => [key, value];
}
