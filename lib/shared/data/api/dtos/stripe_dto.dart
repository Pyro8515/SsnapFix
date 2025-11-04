// Generated from OpenAPI spec: /docs/openapi.yaml
// Single source of truth for API contracts

class IdentityStartResponse {
  final String verificationSessionId;
  final String clientSecret;
  final String url;

  IdentityStartResponse({
    required this.verificationSessionId,
    required this.clientSecret,
    required this.url,
  });

  factory IdentityStartResponse.fromJson(Map<String, dynamic> json) {
    return IdentityStartResponse(
      verificationSessionId: json['verification_session_id'] as String,
      clientSecret: json['client_secret'] as String,
      url: json['url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'verification_session_id': verificationSessionId,
      'client_secret': clientSecret,
      'url': url,
    };
  }
}

class PaymentsStartResponse {
  final String url;
  final int expiresAt;
  final String accountId;

  PaymentsStartResponse({
    required this.url,
    required this.expiresAt,
    required this.accountId,
  });

  factory PaymentsStartResponse.fromJson(Map<String, dynamic> json) {
    return PaymentsStartResponse(
      url: json['url'] as String,
      expiresAt: json['expires_at'] as int,
      accountId: json['account_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'expires_at': expiresAt,
      'account_id': accountId,
    };
  }
}

class StripeWebhookEvent {
  final String id;
  final StripeWebhookEventType type;
  final StripeWebhookEventData data;
  final int created;
  final bool livemode;

  StripeWebhookEvent({
    required this.id,
    required this.type,
    required this.data,
    required this.created,
    required this.livemode,
  });

  factory StripeWebhookEvent.fromJson(Map<String, dynamic> json) {
    return StripeWebhookEvent(
      id: json['id'] as String,
      type: StripeWebhookEventType.fromString(json['type'] as String),
      data: StripeWebhookEventData.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
      created: json['created'] as int,
      livemode: json['livemode'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'data': data.toJson(),
      'created': created,
      'livemode': livemode,
    };
  }
}

class StripeWebhookEventData {
  final Map<String, dynamic> object;

  StripeWebhookEventData({required this.object});

  factory StripeWebhookEventData.fromJson(Map<String, dynamic> json) {
    return StripeWebhookEventData(
      object: json['object'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {'object': object};
  }
}

enum StripeWebhookEventType {
  identityVerificationSessionVerified('identity.verification_session.verified'),
  identityVerificationSessionRequiresInput('identity.verification_session.requires_input'),
  identityVerificationSessionProcessing('identity.verification_session.processing'),
  identityVerificationSessionCanceled('identity.verification_session.canceled'),
  accountUpdated('account.updated'),
  accountApplicationDeauthorized('account.application.deauthorized');

  final String value;

  const StripeWebhookEventType(this.value);

  static StripeWebhookEventType fromString(String value) {
    return StripeWebhookEventType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => StripeWebhookEventType.accountUpdated,
    );
  }
}

class BackgroundStartResponse {
  final String backgroundCheckId;
  final BackgroundCheckStatus status;
  final String message;

  BackgroundStartResponse({
    required this.backgroundCheckId,
    required this.status,
    required this.message,
  });

  factory BackgroundStartResponse.fromJson(Map<String, dynamic> json) {
    return BackgroundStartResponse(
      backgroundCheckId: json['background_check_id'] as String,
      status: BackgroundCheckStatus.fromString(json['status'] as String),
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'background_check_id': backgroundCheckId,
      'status': status.value,
      'message': message,
    };
  }
}

enum BackgroundCheckStatus {
  pending('pending'),
  inProgress('in_progress'),
  completed('completed'),
  failed('failed');

  final String value;

  const BackgroundCheckStatus(this.value);

  static BackgroundCheckStatus fromString(String value) {
    return BackgroundCheckStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BackgroundCheckStatus.pending,
    );
  }
}

