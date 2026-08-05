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

  EmergencyContact copyWith({String? name, String? relation, String? phone}) {
    return EmergencyContact(
      name: name ?? this.name,
      relation: relation ?? this.relation,
      phone: phone ?? this.phone,
    );
  }
}
