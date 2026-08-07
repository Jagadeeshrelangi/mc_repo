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
/// Owned exclusively by [ProfileProvider] (single source of truth). In Sprint 2
/// this maps 1:1 to the backend `/me` resource.
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
