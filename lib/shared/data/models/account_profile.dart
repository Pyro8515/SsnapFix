import '../../extensions/string_extensions.dart';
import '../../state/verification_step_state.dart';

enum AccountRole { customer, professional }

enum VerificationStatus { pending, approved, rejected }

class AccountProfile {
  AccountProfile({
    required this.accountType,
    required this.activeRole,
    required this.canSwitchRoles,
    required this.verificationStatus,
    required this.services,
    required this.documents,
    this.payoutsStatus,
    this.tradeCompliance,
    this.fullName,
    this.email,
    this.bio,
    this.phone,
    this.avatarUrl,
    this.profileStepStatus,
    this.identityStatus,
    this.documentsStatus,
    this.payoutsStatusStep,
    this.backgroundStatus,
  });

  final AccountRole accountType;
  final AccountRole activeRole;
  final bool canSwitchRoles;
  final VerificationStatus verificationStatus;
  final List<String> services;
  final List<ProDocument> documents;
  final String? payoutsStatus;
  final List<String>? tradeCompliance;
  final String? fullName;
  final String? email;
  final String? bio;
  final String? phone;
  final String? avatarUrl;
  final StepStatus? profileStepStatus;
  final StepStatus? identityStatus;
  final StepStatus? documentsStatus;
  final StepStatus? payoutsStatusStep;
  final StepStatus? backgroundStatus;

  bool get canToggleRole => accountType == AccountRole.professional || canSwitchRoles;

  bool get isVerificationApproved => verificationStatus == VerificationStatus.approved;

  AccountProfile copyWith({
    AccountRole? activeRole,
    VerificationStatus? verificationStatus,
  }) {
    return AccountProfile(
      accountType: accountType,
      activeRole: activeRole ?? this.activeRole,
      canSwitchRoles: canSwitchRoles,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      services: services,
      documents: documents,
      payoutsStatus: payoutsStatus,
      tradeCompliance: tradeCompliance,
      fullName: fullName,
      email: email,
      bio: bio,
      phone: phone,
      avatarUrl: avatarUrl,
      profileStepStatus: profileStepStatus,
      identityStatus: identityStatus,
      documentsStatus: documentsStatus,
      payoutsStatusStep: payoutsStatusStep,
      backgroundStatus: backgroundStatus,
    );
  }

  factory AccountProfile.fromJson(Map<String, dynamic> json) {
    return AccountProfile(
      accountType: (json['account_type'] as String?)?.toAccountRole() ?? AccountRole.customer,
      activeRole: (json['active_role'] as String?)?.toAccountRole() ?? AccountRole.customer,
      canSwitchRoles: json['can_switch_roles'] as bool? ?? false,
      verificationStatus:
          (json['verification_status'] as String?)?.toVerificationStatus() ?? VerificationStatus.pending,
      services: (json['services'] as List<dynamic>? ?? const <dynamic>[])
          .map((service) => service.toString())
          .toList(growable: false),
      documents: (json['docs'] as List<dynamic>? ?? const <dynamic>[])
          .map((doc) => ProDocument.fromJson(doc as Map<String, dynamic>))
          .toList(growable: false),
      payoutsStatus: json['payouts_status'] as String?,
      tradeCompliance: (json['trade_compliance'] as List<dynamic>?)?.map((item) => item.toString()).toList(),
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      bio: json['bio'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      profileStepStatus:
          (json['profile_step_status'] as String?)?.toStepStatus(),
      identityStatus: (json['identity_status'] as String?)?.toStepStatus(),
      documentsStatus: (json['documents_status'] as String?)?.toStepStatus(),
      payoutsStatusStep: (json['payouts_status_step'] as String?)?.toStepStatus(),
      backgroundStatus: (json['background_status'] as String?)?.toStepStatus(),
    );
  }
}

class ProDocument {
  ProDocument({
    required this.id,
    required this.name,
    required this.status,
  });

  final String id;
  final String name;
  final String status;

  factory ProDocument.fromJson(Map<String, dynamic> json) {
    return ProDocument(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Document',
      status: json['status']?.toString() ?? 'pending',
    );
  }
}
