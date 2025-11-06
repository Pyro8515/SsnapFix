/// Rating-related DTOs
class RatingResponse {
  final String id;
  final String jobId;
  final String customerId;
  final String proUserId;
  final int rating;
  final String? comment;
  final String? createdAt;
  final String? updatedAt;

  RatingResponse({
    required this.id,
    required this.jobId,
    required this.customerId,
    required this.proUserId,
    required this.rating,
    this.comment,
    this.createdAt,
    this.updatedAt,
  });

  factory RatingResponse.fromJson(Map<String, dynamic> json) {
    return RatingResponse(
      id: json['id'] as String,
      jobId: json['job_id'] as String,
      customerId: json['customer_id'] as String,
      proUserId: json['pro_user_id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_id': jobId,
      'customer_id': customerId,
      'pro_user_id': proUserId,
      'rating': rating,
      if (comment != null) 'comment': comment,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }
}

class RatingCreateRequest {
  final int rating;
  final String? comment;

  RatingCreateRequest({
    required this.rating,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      if (comment != null) 'comment': comment,
    };
  }
}

