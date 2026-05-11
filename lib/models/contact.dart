class Contact {
  final int? id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String note;

  Contact({
    this.id,
    required this.name,
    required this.phone,
    this.email = '',
    this.address = '',
    this.note = '',
  });

  // Convert Contact to a Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'note': note,
    };
  }

  // Create a Contact from a SQLite Map
  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      note: map['note'] ?? '',
    );
  }

  // Used when editing — copy with new values
  Contact copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? note,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      note: note ?? this.note,
    );
  }
}
