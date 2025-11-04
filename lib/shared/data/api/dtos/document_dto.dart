// Generated from OpenAPI spec: /docs/openapi.yaml
// Single source of truth for API contracts

import 'user_response.dart';

class PresignRequest {
  final String docType;
  final String? docSubtype;
  final String fileName;

  PresignRequest({
    required this.docType,
    this.docSubtype,
    required this.fileName,
  });

  Map<String, dynamic> toJson() {
    return {
      'doc_type': docType,
      if (docSubtype != null) 'doc_subtype': docSubtype,
      'file_name': fileName,
    };
  }
}

class PresignResponse {
  final String url;
  final String path;
  final Map<String, String> fields;

  PresignResponse({
    required this.url,
    required this.path,
    required this.fields,
  });

  factory PresignResponse.fromJson(Map<String, dynamic> json) {
    return PresignResponse(
      url: json['url'] as String,
      path: json['path'] as String,
      fields: (json['fields'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, value.toString())) ??
          {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'path': path,
      'fields': fields,
    };
  }
}

class DocumentSubmitRequest {
  final String fileUrl;
  final String docType;
  final String? docSubtype;
  final String? number;
  final String? issuer;
  final String? issuedAt;
  final String? expiresAt;

  DocumentSubmitRequest({
    required this.fileUrl,
    required this.docType,
    this.docSubtype,
    this.number,
    this.issuer,
    this.issuedAt,
    this.expiresAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'file_url': fileUrl,
      'doc_type': docType,
      if (docSubtype != null) 'doc_subtype': docSubtype,
      if (number != null) 'number': number,
      if (issuer != null) 'issuer': issuer,
      if (issuedAt != null) 'issued_at': issuedAt,
      if (expiresAt != null) 'expires_at': expiresAt,
    };
  }
}

class DocumentSubmitResponse {
  final String id;
  final DocumentStatusEnum status;
  final String message;

  DocumentSubmitResponse({
    required this.id,
    required this.status,
    required this.message,
  });

  factory DocumentSubmitResponse.fromJson(Map<String, dynamic> json) {
    return DocumentSubmitResponse(
      id: json['id'] as String,
      status: DocumentStatusEnum.fromString(json['status'] as String),
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status.value,
      'message': message,
    };
  }
}

