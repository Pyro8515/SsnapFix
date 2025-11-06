# Storage & Upload Flow Guide

This guide covers the secure presigned upload flows for documents and avatars, with RLS enforcement.

## Overview

- **Documents**: Upload to private `pro-docs` bucket → Submit metadata → Auto-audit → Recompute compliance
- **Avatars**: Upload to temp path → Approve → Move to public path → Update user record

## Document Upload Flow

### 1. Request Presigned URL

**Endpoint**: `POST /api/pro-docs/presign`

**Request**:
```dart
final request = PresignRequest(
  docType: 'license',
  docSubtype: 'plumbing',
  fileName: 'plumbing_license.pdf',
);

final response = await apiClient.post('/api/pro-docs/presign', body: request.toJson());
final presignResponse = PresignResponse.fromJson(response);
```

**Response**:
```json
{
  "url": "https://storage.supabase.co/...",
  "path": "pro-docs/{user_id}/license/plumbing/{uuid}.pdf",
  "token": "upload_token",
  "fields": {}
}
```

### 2. Upload File to Presigned URL

Use the presigned URL to upload the file directly to Supabase Storage.

### 3. Submit Document Metadata

**Endpoint**: `POST /api/pro-docs/submit`

**Request**:
```dart
final submitRequest = DocumentSubmitRequest(
  fileUrl: presignResponse.url, // Use the uploaded file URL
  docType: 'license',
  docSubtype: 'plumbing',
  number: 'PL-12345',
  issuer: 'State Board of Plumbing',
  issuedAt: '2023-01-15',
  expiresAt: '2025-01-15',
);

final submitResponse = await apiClient.post(
  '/api/pro-docs/submit',
  body: submitRequest.toJson(),
);
final document = DocumentSubmitResponse.fromJson(submitResponse);
```

**What Happens**:
- ✅ File existence verified in storage
- ✅ Document record created/updated with status `pending`
- ✅ Audit record automatically created (via trigger)
- ✅ Trade compliance recomputed

## Avatar Upload Flow

### 1. Request Presigned URL (Temp Path)

**Endpoint**: `POST /api/avatar/upload`

**Request**:
```dart
final response = await apiClient.post('/api/avatar/upload', body: {
  'file_name': 'avatar.jpg',
  'auto_approve': false, // Set to true for auto-approve
});
final uploadData = response; // Contains temp_path, final_path, url, token
```

**Response**:
```json
{
  "url": "https://storage.supabase.co/...",
  "path": "avatars-temp/{user_id}/{uuid}.jpg",
  "temp_path": "avatars-temp/{user_id}/{uuid}.jpg",
  "final_path": "pro-avatars/{user_id}/{uuid}.jpg",
  "token": "upload_token",
  "auto_approve": false
}
```

### 2. Upload File to Temp Path

Upload the avatar image to the presigned URL (temp path).

### 3. Approve and Move to Public Path

**Endpoint**: `POST /api/avatar/approve`

**Request**:
```dart
final approveResponse = await apiClient.post('/api/avatar/approve', body: {
  'temp_path': uploadData['temp_path'],
  'final_path': uploadData['final_path'],
});
```

**What Happens**:
- ✅ Temp file verified
- ✅ File moved from temp to public path
- ✅ Temp file deleted
- ✅ User `avatar_url` updated in database

**Auto-Approve** (if `auto_approve: true`):
- Client can automatically call approve endpoint after upload
- Or implement server-side auto-approve in upload handler

## Dart Client Code Snippets

### Complete Document Upload Flow

```dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:getdone/shared/data/api/dtos/dtos.dart';
import 'package:getdone/shared/data/api_client.dart';

class DocumentUploadService {
  final ApiClient apiClient;

  DocumentUploadService(this.apiClient);

  Future<DocumentSubmitResponse> uploadDocument({
    required File file,
    required String docType,
    String? docSubtype,
    String? number,
    String? issuer,
    String? issuedAt,
    String? expiresAt,
  }) async {
    // Step 1: Get presigned URL
    final presignRequest = PresignRequest(
      docType: docType,
      docSubtype: docSubtype,
      fileName: file.path.split('/').last,
    );
    
    final presignResponse = await apiClient.post(
      '/api/pro-docs/presign',
      body: presignRequest.toJson(),
    );
    final presign = PresignResponse.fromJson(presignResponse);

    // Step 2: Upload file to presigned URL
    final uploadRequest = http.MultipartRequest('POST', Uri.parse(presign.url));
    uploadRequest.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );
    
    // Add token if required
    if (presign.token != null) {
      uploadRequest.headers['Authorization'] = 'Bearer ${presign.token}';
    }

    final uploadResponse = await uploadRequest.send();
    if (uploadResponse.statusCode != 200) {
      throw Exception('File upload failed: ${uploadResponse.statusCode}');
    }

    // Step 3: Submit document metadata
    final submitRequest = DocumentSubmitRequest(
      fileUrl: presign.url, // Or construct from presign.path
      docType: docType,
      docSubtype: docSubtype,
      number: number,
      issuer: issuer,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
    );

    final submitResponse = await apiClient.post(
      '/api/pro-docs/submit',
      body: submitRequest.toJson(),
    );

    return DocumentSubmitResponse.fromJson(submitResponse);
  }
}
```

### Complete Avatar Upload Flow

```dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:getdone/shared/data/api_client.dart';

class AvatarUploadService {
  final ApiClient apiClient;

  AvatarUploadService(this.apiClient);

  Future<String> uploadAvatar({
    required File file,
    bool autoApprove = true,
  }) async {
    // Step 1: Get presigned URL (temp path)
    final uploadResponse = await apiClient.post('/api/avatar/upload', body: {
      'file_name': file.path.split('/').last,
      'auto_approve': autoApprove,
    });

    final tempPath = uploadResponse['temp_path'] as String;
    final finalPath = uploadResponse['final_path'] as String;
    final uploadUrl = uploadResponse['url'] as String;
    final token = uploadResponse['token'] as String?;

    // Step 2: Upload file to temp path
    final uploadRequest = http.MultipartRequest('POST', Uri.parse(uploadUrl));
    uploadRequest.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );
    
    if (token != null) {
      uploadRequest.headers['Authorization'] = 'Bearer $token';
    }

    final uploadHttpResponse = await uploadRequest.send();
    if (uploadHttpResponse.statusCode != 200) {
      throw Exception('Avatar upload failed: ${uploadHttpResponse.statusCode}');
    }

    // Step 3: Approve and move to public path
    if (autoApprove) {
      final approveResponse = await apiClient.post('/api/avatar/approve', body: {
        'temp_path': tempPath,
        'final_path': finalPath,
      });
      
      return approveResponse['avatar_url'] as String;
    }

    // If not auto-approved, return temp path for manual approval
    return tempPath;
  }
}
```

### Using Supabase Storage Client (Alternative)

If using Supabase Flutter SDK directly:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class SupabaseStorageUploadService {
  final SupabaseClient supabase;

  SupabaseStorageUploadService(this.supabase);

  // Document upload using Supabase Storage client
  Future<void> uploadDocument(File file, String docType, {String? docSubtype}) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final fileId = DateTime.now().millisecondsSinceEpoch.toString();
    final extension = file.path.split('.').last;
    final path = 'pro-docs/$userId/$docType/${docSubtype ?? 'default'}/$fileId.$extension';

    // Upload directly (RLS enforced)
    await supabase.storage
      .from('pro-docs')
      .upload(path, file, fileOptions: FileOptions(upsert: false));

    // Get file URL
    final fileUrl = supabase.storage
      .from('pro-docs')
      .getPublicUrl(path);

    // Submit metadata via API
    // ... use apiClient.post('/api/pro-docs/submit', ...)
  }

  // Avatar upload using Supabase Storage client
  Future<String> uploadAvatar(File file) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final fileId = DateTime.now().millisecondsSinceEpoch.toString();
    final extension = file.path.split('.').last;
    final tempPath = 'avatars-temp/$userId/$fileId.$extension';
    final finalPath = 'pro-avatars/$userId/$fileId.$extension';

    // Upload to temp path
    await supabase.storage
      .from('pro-avatars')
      .upload(tempPath, file);

    // Move to public path (copy + delete)
    final fileData = await supabase.storage
      .from('pro-avatars')
      .download(tempPath);

    await supabase.storage
      .from('pro-avatars')
      .upload(finalPath, fileData, fileOptions: FileOptions(upsert: true));

    await supabase.storage
      .from('pro-avatars')
      .remove([tempPath]);

    // Get public URL
    final publicUrl = supabase.storage
      .from('pro-avatars')
      .getPublicUrl(finalPath);

    return publicUrl;
  }
}
```

## RLS Enforcement

### Storage Policies

- **pro-docs** (private):
  - Users can only access their own documents
  - Path must start with `{auth.uid()}`
  - Admins can view all documents

- **pro-avatars** (public read):
  - Anyone can read avatars
  - Users can only upload/update/delete their own avatars
  - Path must start with `{auth.uid()}`

### Database Policies

- Document records: Users can only access their own documents
- Audit records: Users can only view their own audit history
- Admin override: Admins can view all records

## Error Handling

```dart
try {
  final document = await documentUploadService.uploadDocument(
    file: file,
    docType: 'license',
    docSubtype: 'plumbing',
  );
  print('Document uploaded: ${document.id}');
} on ApiException catch (e) {
  if (e.statusCode == 403) {
    print('Only professionals can upload documents');
  } else if (e.statusCode == 400) {
    print('Invalid request: ${e.body}');
  } else {
    print('Upload failed: ${e.message}');
  }
}
```

## Best Practices

1. **Always verify file exists** before submitting metadata
2. **Use presigned URLs** for secure direct uploads
3. **Validate file types** on client side
4. **Handle errors gracefully** with user-friendly messages
5. **Show upload progress** for better UX
6. **Implement retry logic** for network failures
7. **Clean up temp files** if upload fails

