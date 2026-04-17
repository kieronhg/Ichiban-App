import 'package:equatable/equatable.dart';

class Discipline extends Equatable {
  final String id;
  final String name;
  final String? description;
  final bool isActive;

  const Discipline({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
  });

  Discipline copyWith({
    String? id,
    String? name,
    String? description,
    bool? isActive,
  }) {
    return Discipline(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [id, name, description, isActive];
}
