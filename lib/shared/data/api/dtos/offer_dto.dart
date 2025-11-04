// Generated from OpenAPI spec: /docs/openapi.yaml
// Single source of truth for API contracts

class Offer {
  final String id;
  final String jobTitle;
  final String? description;
  final List<String> trade;
  final double? locationLat;
  final double? locationLng;
  final String? customerUserId;
  final OfferStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Offer({
    required this.id,
    required this.jobTitle,
    this.description,
    required this.trade,
    this.locationLat,
    this.locationLng,
    this.customerUserId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'] as String,
      jobTitle: json['job_title'] as String,
      description: json['description'] as String?,
      trade: (json['trade'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      locationLat: json['location_lat'] != null
          ? (json['location_lat'] as num).toDouble()
          : null,
      locationLng: json['location_lng'] != null
          ? (json['location_lng'] as num).toDouble()
          : null,
      customerUserId: json['customer_user_id'] as String?,
      status: OfferStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_title': jobTitle,
      if (description != null) 'description': description,
      'trade': trade,
      if (locationLat != null) 'location_lat': locationLat,
      if (locationLng != null) 'location_lng': locationLng,
      if (customerUserId != null) 'customer_user_id': customerUserId,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

enum OfferStatus {
  open('open'),
  assigned('assigned'),
  completed('completed'),
  cancelled('cancelled');

  final String value;

  const OfferStatus(this.value);

  static OfferStatus fromString(String value) {
    return OfferStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OfferStatus.open,
    );
  }
}

class OfferAcceptRequest {
  final String offerId;

  OfferAcceptRequest({required this.offerId});

  Map<String, dynamic> toJson() {
    return {'offer_id': offerId};
  }
}

class OfferAcceptResponse {
  final bool success;
  final String offerId;

  OfferAcceptResponse({
    required this.success,
    required this.offerId,
  });

  factory OfferAcceptResponse.fromJson(Map<String, dynamic> json) {
    return OfferAcceptResponse(
      success: json['success'] as bool,
      offerId: json['offer_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'offer_id': offerId,
    };
  }
}

