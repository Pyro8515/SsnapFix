import 'dart:convert';

import 'api_client.dart';
import 'api/dtos/error_response.dart';
import 'api/dtos/offer_dto.dart';

class OffersRepository {
  OffersRepository(this._client);

  final ApiClient _client;

  Future<List<Offer>> fetchOffers({
    String? trade,
    double? lat,
    double? lng,
    double? maxDistance,
  }) async {
    final queryParams = <String, String>{};
    if (trade != null) queryParams['trade'] = trade;
    if (lat != null) queryParams['lat'] = lat.toString();
    if (lng != null) queryParams['lng'] = lng.toString();
    if (maxDistance != null) queryParams['max_distance'] = maxDistance.toString();

    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final path = queryString.isNotEmpty ? '/api/offers?$queryString' : '/api/offers';

    final response = await _client.get(path);
    final offersJson = response as List<dynamic>? ?? [];
    return offersJson
        .map((json) => Offer.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<OfferAcceptResponse> acceptOffer({
    required String offerId,
    double? lat,
    double? lng,
    double? maxDistance,
  }) async {
    try {
      final body = <String, dynamic>{'offer_id': offerId};
      if (lat != null) body['lat'] = lat;
      if (lng != null) body['lng'] = lng;
      if (maxDistance != null) body['max_distance'] = maxDistance;

      final response = await _client.post('/api/pro/offers/accept', body: body);
      return OfferAcceptResponse.fromJson(response);
    } on ApiException catch (e) {
      if (e.statusCode == 409 && e.body != null) {
        // Parse error response with reasons
        final errorJson = jsonDecode(e.body!) as Map<String, dynamic>;
        final errorResponse = ErrorResponse.fromJson(errorJson);
        throw OfferAcceptException(
          error: errorResponse.error,
          reasons: errorResponse.reasons ?? [],
        );
      }
      rethrow;
    }
  }
}

class OfferAcceptException implements Exception {
  OfferAcceptException({
    required this.error,
    required this.reasons,
  });

  final String error;
  final List<String> reasons;

  @override
  String toString() => 'OfferAcceptException: $error\nReasons: ${reasons.join(', ')}';
}

