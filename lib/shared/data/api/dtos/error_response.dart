// Generated from OpenAPI spec: /docs/openapi.yaml
// Single source of truth for API contracts

class ErrorResponse {
  final String error;
  final List<String>? reasons;
  final Map<String, dynamic>? details;

  ErrorResponse({
    required this.error,
    this.reasons,
    this.details,
  });

  factory ErrorResponse.fromJson(Map<String, dynamic> json) {
    return ErrorResponse(
      error: json['error'] as String,
      reasons: json['reasons'] != null
          ? (json['reasons'] as List<dynamic>)
              .map((e) => e as String)
              .toList()
          : null,
      details: json['details'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      if (reasons != null) 'reasons': reasons,
      if (details != null) 'details': details,
    };
  }
}

