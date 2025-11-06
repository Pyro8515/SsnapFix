import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'api/dtos/rating_dto.dart';

final ratingsRepositoryProvider = Provider<RatingsRepository>((ref) {
  final apiClient = ApiClient();
  return RatingsRepository(apiClient);
});

class RatingsRepository {
  final ApiClient _apiClient;

  RatingsRepository(this._apiClient);

  /// Get user's ratings
  Future<List<RatingResponse>> getUserRatings() async {
    final response = await _apiClient.get('/api/ratings');
    
    if (response is List) {
      return (response as List).map((r) => RatingResponse.fromJson(r as Map<String, dynamic>)).toList();
    }
    
    return [];
  }

  /// Get rating for a specific job
  Future<RatingResponse?> getRatingForJob(String jobId) async {
    try {
      final response = await _apiClient.get('/api/ratings/$jobId');
      return RatingResponse.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Create or update rating for a job
  Future<RatingResponse> createOrUpdateRating({
    required String jobId,
    required int rating,
    String? comment,
  }) async {
    final response = await _apiClient.post(
      '/api/ratings/$jobId',
      body: {
        'rating': rating,
        if (comment != null) 'comment': comment,
      },
    );

    return RatingResponse.fromJson(response);
  }
}

