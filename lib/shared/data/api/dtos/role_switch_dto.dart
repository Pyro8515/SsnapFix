// Generated from OpenAPI spec: /docs/openapi.yaml
// Single source of truth for API contracts

class RoleSwitchResponse {
  final String activeRole;

  RoleSwitchResponse({required this.activeRole});

  factory RoleSwitchResponse.fromJson(Map<String, dynamic> json) {
    return RoleSwitchResponse(
      activeRole: json['active_role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'active_role': activeRole};
  }
}

