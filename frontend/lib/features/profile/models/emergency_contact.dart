/// Emergency contact shown on the profile and used by safety features.
class EmergencyContact {
  final String name;
  final String relation;
  final String phone;

  const EmergencyContact({
    required this.name,
    required this.relation,
    required this.phone,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['emergency_contact_name']?.toString() ?? json['name']?.toString() ?? '',
      relation: json['emergency_contact_relation']?.toString() ?? json['relation']?.toString() ?? '',
      phone: json['emergency_contact_phone']?.toString() ?? json['phone']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emergency_contact_name': name,
      'emergency_contact_relation': relation,
      'emergency_contact_phone': phone,
    };
  }

  EmergencyContact copyWith({String? name, String? relation, String? phone}) {
    return EmergencyContact(
      name: name ?? this.name,
      relation: relation ?? this.relation,
      phone: phone ?? this.phone,
    );
  }
}
