import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'api/dtos/job_dto.dart';

final jobsRepositoryProvider = Provider<JobsRepository>((ref) {
  final apiClient = ApiClient();
  return JobsRepository(apiClient);
});

class JobsRepository {
  final ApiClient _apiClient;

  JobsRepository(this._apiClient);

  /// Create a new job
  Future<JobResponse> createJob({
    required String serviceCode,
    required Map<String, dynamic> address,
    String? scheduledStart,
    String? scheduledEnd,
    String? notes,
  }) async {
    final response = await _apiClient.post('/api/jobs', body: {
      'service_code': serviceCode,
      'address': address,
      if (scheduledStart != null) 'scheduled_start': scheduledStart,
      if (scheduledEnd != null) 'scheduled_end': scheduledEnd,
      if (notes != null) 'notes': notes,
    });

    return JobResponse.fromJson(response);
  }

  /// Update job status
  Future<JobStatusResponse> updateJobStatus({
    required String jobId,
    required String status,
    Map<String, dynamic>? location,
  }) async {
    final response = await _apiClient.post('/api/jobs/$jobId/status', body: {
      'status': status,
      if (location != null) 'location': location,
    });

    return JobStatusResponse.fromJson(response);
  }

  /// Trigger matching engine
  Future<MatchResponse> matchJob(String jobId) async {
    final response = await _apiClient.post('/api/jobs/match', body: {
      'job_id': jobId,
    });

    return MatchResponse.fromJson(response);
  }

  /// Get job by ID
  Future<JobResponse> getJob(String jobId) async {
    final response = await _apiClient.get('/api/jobs/$jobId');
    return JobResponse.fromJson(response);
  }

  /// Get user's jobs
  Future<List<JobResponse>> getUserJobs({
    String? status,
    int? limit,
    int? offset,
  }) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (limit != null) queryParams['limit'] = limit.toString();
    if (offset != null) queryParams['offset'] = offset.toString();

    final queryString = queryParams.isEmpty
        ? ''
        : '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';

    final response = await _apiClient.get('/api/jobs$queryString');
    
    // Handle both single object and array responses
    if (response.containsKey('jobs')) {
      final jobs = response['jobs'] as List;
      return jobs.map((job) => JobResponse.fromJson(job as Map<String, dynamic>)).toList();
    } else if (response is List) {
      return (response as List).map((job) => JobResponse.fromJson(job as Map<String, dynamic>)).toList();
    } else {
      return [JobResponse.fromJson(response)];
    }
  }
}

