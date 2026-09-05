import 'package:flutter/material.dart';
import 'emergency_contact.dart';

/// Membership level shown on the profile header.
enum MembershipTier {
  pro,
  free;

  String get label => switch (this) {
        MembershipTier.pro => 'Pro Member',
        MembershipTier.free => 'Free Member',
      };

  IconData get icon => switch (this) {
        MembershipTier.pro => Icons.workspace_premium_rounded,
        MembershipTier.free => Icons.person_rounded,
      };
}

/// The signed-in user's account profile.
///
/// Owned exclusively by [ProfileProvider] (single source of truth).
/// Maps 1:1 with the FastAPI `/api/v1/users/me` resource.
class UserProfile {
  final String name;
  final String email;
  final String phone;
  final DateTime? dateOfBirth;
  final String? gender;
  final DateTime joinedDate;
  final String? avatarUrl;
  final MembershipTier membershipTier;
  final EmergencyContact? emergencyContact;

  const UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    this.dateOfBirth,
    this.gender,
    required this.joinedDate,
    this.avatarUrl,
    this.membershipTier = MembershipTier.pro,
    this.emergencyContact,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    EmergencyContact? contact;
    if (json['emergency_contact_name'] != null || json['emergency_contact'] != null) {
      if (json['emergency_contact'] is Map<String, dynamic>) {
        contact = EmergencyContact.fromJson(json['emergency_contact'] as Map<String, dynamic>);
      } else if (json['emergency_contact_name'] != null) {
        contact = EmergencyContact(
          name: json['emergency_contact_name']?.toString() ?? '',
          relation: json['emergency_contact_relation']?.toString() ?? '',
          phone: json['emergency_contact_phone']?.toString() ?? '',
        );
      }
    }

    final tierStr = (json['membership_tier']?.toString() ?? 'pro').toLowerCase();
    final tier = tierStr == 'free' ? MembershipTier.free : MembershipTier.pro;

    DateTime joined = DateTime.now();
    if (json['joined_at'] != null) {
      joined = DateTime.tryParse(json['joined_at'].toString()) ?? joined;
    } else if (json['joinedDate'] != null) {
      joined = DateTime.tryParse(json['joinedDate'].toString()) ?? joined;
    }

    DateTime? dob;
    if (json['date_of_birth'] != null) {
      dob = DateTime.tryParse(json['date_of_birth'].toString());
    } else if (json['dateOfBirth'] != null) {
      dob = DateTime.tryParse(json['dateOfBirth'].toString());
    }

    return UserProfile(
      name: json['name']?.toString() ?? 'User',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      dateOfBirth: dob,
      gender: json['gender']?.toString(),
      joinedDate: joined,
      avatarUrl: json['avatar_url']?.toString() ?? json['avatarUrl']?.toString(),
      membershipTier: tier,
      emergencyContact: contact,
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      if (dateOfBirth != null)
        'date_of_birth':
            '${dateOfBirth!.year.toString().padLeft(4, '0')}-${dateOfBirth!.month.toString().padLeft(2, '0')}-${dateOfBirth!.day.toString().padLeft(2, '0')}',
      if (gender != null && gender!.isNotEmpty) 'gender': gender,
      if (emergencyContact != null) ...{
        if (emergencyContact!.name.isNotEmpty)
          'emergency_contact_name': emergencyContact!.name,
        if (emergencyContact!.relation.isNotEmpty)
          'emergency_contact_relation': emergencyContact!.relation,
        if (emergencyContact!.phone.isNotEmpty)
          'emergency_contact_phone': emergencyContact!.phone.replaceAll(' ', ''),
      },
    };
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
    DateTime? joinedDate,
    String? avatarUrl,
    MembershipTier? membershipTier,
    EmergencyContact? emergencyContact,
    bool clearDateOfBirth = false,
    bool clearEmergencyContact = false,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: clearDateOfBirth ? null : (dateOfBirth ?? this.dateOfBirth),
      gender: gender ?? this.gender,
      joinedDate: joinedDate ?? this.joinedDate,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      membershipTier: membershipTier ?? this.membershipTier,
      emergencyContact:
          clearEmergencyContact ? null : (emergencyContact ?? this.emergencyContact),
    );
  }
}
