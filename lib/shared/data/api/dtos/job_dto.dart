/// Job-related DTOs
class JobResponse {
  final String id;
  final String serviceCode;
  final String status;
  final Map<String, dynamic> address;
  final int priceCents;
  final int? platformFeeCents;
  final int? payoutCents;
  final String currency;
  final String? scheduledStart;
  final String? scheduledEnd;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  JobResponse({
    required this.id,
    required this.serviceCode,
    required this.status,
    required this.address,
    required this.priceCents,
    this.platformFeeCents,
    this.payoutCents,
    this.currency = 'USD',
    this.scheduledStart,
    this.scheduledEnd,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory JobResponse.fromJson(Map<String, dynamic> json) {
    return JobResponse(
      id: json['id'] as String,
      serviceCode: json['service_code'] as String,
      status: json['status'] as String,
      address: json['address'] as Map<String, dynamic>,
      priceCents: json['price_cents'] as int,
      platformFeeCents: json['platform_fee_cents'] as int?,
      payoutCents: json['payout_cents'] as int?,
      currency: json['currency'] as String? ?? 'USD',
      scheduledStart: json['scheduled_start'] as String?,
      scheduledEnd: json['scheduled_end'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_code': serviceCode,
      'status': status,
      'address': address,
      'price_cents': priceCents,
      if (platformFeeCents != null) 'platform_fee_cents': platformFeeCents,
      if (payoutCents != null) 'payout_cents': payoutCents,
      'currency': currency,
      if (scheduledStart != null) 'scheduled_start': scheduledStart,
      if (scheduledEnd != null) 'scheduled_end': scheduledEnd,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }
}

class JobStatusResponse {
  final String id;
  final String status;
  final String? paymentStatus;
  final String? updatedAt;

  JobStatusResponse({
    required this.id,
    required this.status,
    this.paymentStatus,
    this.updatedAt,
  });

  factory JobStatusResponse.fromJson(Map<String, dynamic> json) {
    return JobStatusResponse(
      id: json['id'] as String,
      status: json['status'] as String,
      paymentStatus: json['payment_status'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }
}

class MatchResponse {
  final String message;
  final int matchedCount;
  final List<MatchOffer> offers;

  MatchResponse({
    required this.message,
    required this.matchedCount,
    required this.offers,
  });

  factory MatchResponse.fromJson(Map<String, dynamic> json) {
    return MatchResponse(
      message: json['message'] as String? ?? 'Matching completed',
      matchedCount: json['matched_count'] as int? ?? 0,
      offers: (json['offers'] as List<dynamic>?)
              ?.map((offer) => MatchOffer.fromJson(offer as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'matched_count': matchedCount,
      'offers': offers.map((offer) => offer.toJson()).toList(),
    };
  }
}

class MatchOffer {
  final String id;
  final String proUserId;
  final String status;
  final String? expiresAt;
  final int? payoutCents;

  MatchOffer({
    required this.id,
    required this.proUserId,
    required this.status,
    this.expiresAt,
    this.payoutCents,
  });

  factory MatchOffer.fromJson(Map<String, dynamic> json) {
    return MatchOffer(
      id: json['id'] as String,
      proUserId: json['pro_user_id'] as String,
      status: json['status'] as String,
      expiresAt: json['expires_at'] as String?,
      payoutCents: json['payout_cents'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pro_user_id': proUserId,
      'status': status,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (payoutCents != null) 'payout_cents': payoutCents,
    };
  }
}

