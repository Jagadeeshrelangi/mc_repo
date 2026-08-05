/// Channel toggles that control how Mecha Connect reaches the user.
///
/// Persisted locally (SharedPreferences) so settings survive restarts without
/// any backend call.
class NotificationSettings {
  final bool push;
  final bool email;
  final bool sms;
  final bool marketing;
  final bool emergencyAlerts;

  const NotificationSettings({
    this.push = true,
    this.email = true,
    this.sms = true,
    this.marketing = false,
    this.emergencyAlerts = true,
  });

  NotificationSettings copyWith({
    bool? push,
    bool? email,
    bool? sms,
    bool? marketing,
    bool? emergencyAlerts,
  }) {
    return NotificationSettings(
      push: push ?? this.push,
      email: email ?? this.email,
      sms: sms ?? this.sms,
      marketing: marketing ?? this.marketing,
      emergencyAlerts: emergencyAlerts ?? this.emergencyAlerts,
    );
  }

  Map<String, dynamic> toJson() => {
        'push': push,
        'email': email,
        'sms': sms,
        'marketing': marketing,
        'emergencyAlerts': emergencyAlerts,
      };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      push: json['push'] as bool? ?? true,
      email: json['email'] as bool? ?? true,
      sms: json['sms'] as bool? ?? true,
      marketing: json['marketing'] as bool? ?? false,
      emergencyAlerts: json['emergencyAlerts'] as bool? ?? true,
    );
  }
}
