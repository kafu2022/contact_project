import 'package:uuid/uuid.dart';

class Contact {
  final String id;
  final String name;
  final String phone;
  final String? address;
  final String? company;
  final String? email;
  final String? imagePath;

  Contact({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
    this.company,
    this.email,
    this.imagePath,
  });

  factory Contact.fromMap(Map<String, dynamic> map) => Contact(
    id: map['id'] ?? const Uuid().v4(),
    name: map['name'],
    phone: map['phone'],
    address: map['address'],
    company: map['company'],
    email: map['email'],
    imagePath: map['imagePath'],
  );

  Contact copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? company,
    String? email,
    String? imagePath,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      company: company ?? this.company,
      email: email ?? this.email,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

extension ContactSerializer on Contact {
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'phone': phone,
    'address': address,
    'company': company,
    'email': email,
    'imagePath': imagePath,
  };
}