import 'package:equatable/equatable.dart';

class DriverDirectoryModel extends Equatable {
  final String id;
  final String name;
  final String phone;

  const DriverDirectoryModel({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory DriverDirectoryModel.fromMap(Map<String, dynamic> map, String id) {
    return DriverDirectoryModel(
      id: id,
      name: map['Name'] as String? ?? '',
      phone: map['Phone'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'Name': name, 'Phone': phone};
  }

  @override
  List<Object?> get props => [id, name, phone];
}
