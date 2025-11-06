# Storage & Upload Flow - Dart Client Snippets

Quick reference for implementing document and avatar uploads in Flutter.

## Document Upload (Complete Flow)

```dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:getdone/shared/data/api/dtos/dtos.dart';
import 'package:getdone/shared/data/api_client.dart';

Future<DocumentSubmitResponse> uploadDocument({
  required File file,
  required String docType,
  String? docSubtype,
  String? number,
  String? issuer,
  String? issuedAt,
  String? expiresAt,
}) async {
  final apiClient = ApiClient();

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

  // Step 2: Upload file using presigned URL
  final uploadRequest = http.MultipartRequest('POST', Uri.parse(presign.url));
  uploadRequest.files.add(
    await http.MultipartFile.fromPath('file', file.path),
  );
  
  if (presign.token != null) {
    uploadRequest.headers['Authorization'] = 'Bearer ${presign.token}';
  }

  final uploadResponse = await uploadRequest.send();
  if (uploadResponse.statusCode != 200) {
    throw Exception('Upload failed: ${uploadResponse.statusCode}');
  }

  // Step 3: Submit document metadata
  final submitRequest = DocumentSubmitRequest(
    fileUrl: presign.url,
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
```

## Avatar Upload (Complete Flow)

```dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:getdone/shared/data/api_client.dart';

Future<String> uploadAvatar({
  required File file,
  bool autoApprove = true,
}) async {
  final apiClient = ApiClient();

  // Step 1: Get presigned URL for temp path
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

  return tempPath; // Return temp path for manual approval
}
```

## Using Supabase Storage Client (Alternative)

If you prefer using Supabase Flutter SDK directly:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

// Document upload
Future<void> uploadDocumentDirect(File file, String docType, {String? docSubtype}) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) throw Exception('Not authenticated');

  final fileId = DateTime.now().millisecondsSinceEpoch.toString();
  final extension = file.path.split('.').last;
  final path = 'pro-docs/$userId/$docType/${docSubtype ?? 'default'}/$fileId.$extension';

  // Upload directly (RLS enforced)
  await supabase.storage
    .from('pro-docs')
    .upload(path, file, fileOptions: FileOptions(upsert: false));

  // Get file URL for metadata submission
  final fileUrl = supabase.storage
    .from('pro-docs')
    .getPublicUrl(path);

  // Submit metadata via API
  final apiClient = ApiClient();
  await apiClient.post('/api/pro-docs/submit', body: {
    'file_url': fileUrl,
    'doc_type': docType,
    'doc_subtype': docSubtype,
    // ... other fields
  });
}

// Avatar upload
Future<String> uploadAvatarDirect(File file) async {
  final supabase = Supabase.instance.client;
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

  // Move to public path
  final fileData = await supabase.storage
    .from('pro-avatars')
    .download(tempPath);

  await supabase.storage
    .from('pro-avatars')
    .upload(finalPath, fileData, fileOptions: FileOptions(upsert: true));

  // Delete temp file
  await supabase.storage
    .from('pro-avatars')
    .remove([tempPath]);

  // Get public URL
  final publicUrl = supabase.storage
    .from('pro-avatars')
    .getPublicUrl(finalPath);

  // Update user avatar_url via API
  final apiClient = ApiClient();
  await apiClient.post('/api/me', body: {
    'avatar_url': publicUrl,
  });

  return publicUrl;
}
```

## Error Handling Example

```dart
try {
  final document = await uploadDocument(
    file: File('/path/to/license.pdf'),
    docType: 'license',
    docSubtype: 'plumbing',
    number: 'PL-12345',
    issuer: 'State Board',
    expiresAt: '2025-12-31',
  );
  print('Document uploaded: ${document.id}, Status: ${document.status}');
} on ApiException catch (e) {
  if (e.statusCode == 403) {
    print('Error: Only professionals can upload documents');
  } else if (e.statusCode == 400) {
    final error = ErrorResponse.fromJson(jsonDecode(e.body));
    print('Error: ${error.error}');
    if (error.reasons != null) {
      error.reasons!.forEach((reason) => print('  - $reason'));
    }
  } else {
    print('Upload failed: ${e.message}');
  }
}
```

## Usage Example

```dart
// In your widget
Future<void> handleDocumentUpload() async {
  final file = await pickFile(); // Use file_picker package
  
  try {
    final document = await uploadDocument(
      file: file,
      docType: 'license',
      docSubtype: 'plumbing',
      number: 'PL-12345',
      issuer: 'State Board of Plumbing',
      issuedAt: '2023-01-15',
      expiresAt: '2025-01-15',
    );
    
    setState(() {
      _uploadedDocument = document;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Document uploaded: ${document.message}')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Upload failed: $e')),
    );
  }
}

Future<void> handleAvatarUpload() async {
  final file = await pickImage(); // Use image_picker package
  
  try {
    final avatarUrl = await uploadAvatar(
      file: file,
      autoApprove: true,
    );
    
    setState(() {
      _avatarUrl = avatarUrl;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Avatar uploaded successfully')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Avatar upload failed: $e')),
    );
  }
}
```

## Notes

- **RLS Enforcement**: All storage operations are enforced by Row Level Security policies
- **Path Structure**: Documents use `pro-docs/{user_id}/{doc_type}/{doc_subtype}/{uuid}.{ext}`
- **Avatar Flow**: Upload to temp → approve → move to public path
- **Audit Trail**: Document submissions automatically create audit records
- **Compliance**: Document submissions trigger compliance recomputation

