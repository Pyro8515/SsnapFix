// Generated from OpenAPI spec: /docs/openapi.yaml
// Single source of truth for API contracts

class UserResponse {
  final String id;
  final AccountType accountType;
  final String activeRole;
  final bool canSwitchRoles;
  final VerificationStatus verificationStatus;
  final String? avatarUrl;
  final ProfessionalProfile? professionalProfile;
  final List<DocumentStatus> documents;
  final List<TradeCompliance> tradeCompliance;

  UserResponse({
    required this.id,
    required this.accountType,
    required this.activeRole,
    required this.canSwitchRoles,
    required this.verificationStatus,
    this.avatarUrl,
    this.professionalProfile,
    required this.documents,
    required this.tradeCompliance,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'] as String,
      accountType: AccountType.fromString(json['account_type'] as String),
      activeRole: json['active_role'] as String,
      canSwitchRoles: json['can_switch_roles'] as bool,
      verificationStatus: VerificationStatus.fromString(
        json['verification_status'] as String,
      ),
      avatarUrl: json['avatar_url'] as String?,
      professionalProfile: json['professional_profile'] != null
          ? ProfessionalProfile.fromJson(
              json['professional_profile'] as Map<String, dynamic>,
            )
          : null,
      documents: (json['documents'] as List<dynamic>?)
              ?.map((e) => DocumentStatus.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tradeCompliance: (json['trade_compliance'] as List<dynamic>?)
              ?.map((e) => TradeCompliance.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account_type': accountType.value,
      'active_role': activeRole,
      'can_switch_roles': canSwitchRoles,
      'verification_status': verificationStatus.value,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (professionalProfile != null)
        'professional_profile': professionalProfile!.toJson(),
      'documents': documents.map((e) => e.toJson()).toList(),
      'trade_compliance': tradeCompliance.map((e) => e.toJson()).toList(),
    };
  }
}

class ProfessionalProfile {
  final List<String> services;
  final String? identityStatus;
  final bool payoutsEnabled;
  final String? payoutsStatus;

  ProfessionalProfile({
    required this.services,
    this.identityStatus,
    required this.payoutsEnabled,
    this.payoutsStatus,
  });

  factory ProfessionalProfile.fromJson(Map<String, dynamic> json) {
    return ProfessionalProfile(
      services: (json['services'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      identityStatus: json['identity_status'] as String?,
      payoutsEnabled: json['payouts_enabled'] as bool,
      payoutsStatus: json['payouts_status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'services': services,
      if (identityStatus != null) 'identity_status': identityStatus,
      'payouts_enabled': payoutsEnabled,
      if (payoutsStatus != null) 'payouts_status': payoutsStatus,
    };
  }
}

class DocumentStatus {
  final String docType;
  final String? docSubtype;
  final DocumentStatusEnum status;
  final String? expiresAt;
  final String? reason;

  DocumentStatus({
    required this.docType,
    this.docSubtype,
    required this.status,
    this.expiresAt,
    this.reason,
  });

  factory DocumentStatus.fromJson(Map<String, dynamic> json) {
    return DocumentStatus(
      docType: json['doc_type'] as String,
      docSubtype: json['doc_subtype'] as String?,
      status: DocumentStatusEnum.fromString(json['status'] as String),
      expiresAt: json['expires_at'] as String?,
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doc_type': docType,
      if (docSubtype != null) 'doc_subtype': docSubtype,
      'status': status.value,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (reason != null) 'reason': reason,
    };
  }
}

class TradeCompliance {
  final String trade;
  final bool compliant;
  final String? reason;

  TradeCompliance({
    required this.trade,
    required this.compliant,
    this.reason,
  });

  factory TradeCompliance.fromJson(Map<String, dynamic> json) {
    return TradeCompliance(
      trade: json['trade'] as String,
      compliant: json['compliant'] as bool,
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trade': trade,
      'compliant': compliant,
      if (reason != null) 'reason': reason,
    };
  }
}

enum AccountType {
  customer('customer'),
  professional('professional');

  final String value;

  const AccountType(this.value);

  static AccountType fromString(String value) {
    return AccountType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AccountType.customer,
    );
  }
}

enum VerificationStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  final String value;

  const VerificationStatus(this.value);

  static VerificationStatus fromString(String value) {
    return VerificationStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => VerificationStatus.pending,
    );
  }
}

enum DocumentStatusEnum {
  pending('pending'),
  approved('approved'),
  rejected('rejected'),
  expired('expired'),
  manualReview('manual_review');

  final String value;

  const DocumentStatusEnum(this.value);

  static DocumentStatusEnum fromString(String value) {
    return DocumentStatusEnum.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DocumentStatusEnum.pending,
    );
  }
}

