import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Realtime service for subscribing to job status updates
class RealtimeService {
  RealtimeService(this._supabase);

  final SupabaseClient _supabase;
  RealtimeChannel? _offersChannel;
  RealtimeChannel? _assignmentsChannel;
  RealtimeChannel? _notificationsChannel;

  /// Subscribe to offers table changes (job status updates)
  StreamSubscription<RealtimePostgresChangesPayload>? subscribeToOffers({
    required Function(Map<String, dynamic>) onInsert,
    required Function(Map<String, dynamic>) onUpdate,
    required Function(Map<String, dynamic>) onDelete,
  }) {
    _offersChannel = _supabase
        .channel('offers')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'offers',
          callback: (payload) => onInsert(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'offers',
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'offers',
          callback: (payload) => onDelete(payload.oldRecord),
        )
        .subscribe();

    // Return subscription for cleanup
    return null; // Supabase handles cleanup via channel
  }

  /// Subscribe to offer_assignments table changes
  StreamSubscription<RealtimePostgresChangesPayload>? subscribeToAssignments({
    required Function(Map<String, dynamic>) onInsert,
    required Function(Map<String, dynamic>) onUpdate,
    required Function(Map<String, dynamic>) onDelete,
  }) {
    _assignmentsChannel = _supabase
        .channel('offer_assignments')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'offer_assignments',
          callback: (payload) => onInsert(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'offer_assignments',
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'offer_assignments',
          callback: (payload) => onDelete(payload.oldRecord),
        )
        .subscribe();

    return null;
  }

  /// Subscribe to notifications table changes (in-app notifications)
  StreamSubscription<RealtimePostgresChangesPayload>? subscribeToNotifications({
    required String userId,
    required Function(Map<String, dynamic>) onInsert,
    required Function(Map<String, dynamic>) onUpdate,
  }) {
    _notificationsChannel = _supabase
        .channel('notifications_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => onInsert(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();

    return null;
  }

  /// Subscribe to specific offer changes (for job tracking)
  StreamSubscription<RealtimePostgresChangesPayload>? subscribeToOffer({
    required String offerId,
    required Function(Map<String, dynamic>) onUpdate,
    required Function(Map<String, dynamic>) onDelete,
  }) {
    final channel = _supabase
        .channel('offer_$offerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'offers',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: offerId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'offers',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: offerId,
          ),
          callback: (payload) => onDelete(payload.oldRecord),
        )
        .subscribe();

    return null;
  }

  /// Unsubscribe from all channels
  Future<void> unsubscribeAll() async {
    await _offersChannel?.unsubscribe();
    await _assignmentsChannel?.unsubscribe();
    await _notificationsChannel?.unsubscribe();
    _offersChannel = null;
    _assignmentsChannel = null;
    _notificationsChannel = null;
  }

  /// Unsubscribe from specific channel
  Future<void> unsubscribe(String channelName) async {
    switch (channelName) {
      case 'offers':
        await _offersChannel?.unsubscribe();
        _offersChannel = null;
        break;
      case 'assignments':
        await _assignmentsChannel?.unsubscribe();
        _assignmentsChannel = null;
        break;
      case 'notifications':
        await _notificationsChannel?.unsubscribe();
        _notificationsChannel = null;
        break;
    }
  }
}

/// Provider for RealtimeService
final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  return RealtimeService(Supabase.instance.client);
});

/// Provider for job status updates stream
final jobStatusUpdatesProvider =
    StreamProvider.autoDispose<Map<String, dynamic>>((ref) {
  final realtimeService = ref.watch(realtimeServiceProvider);
  final controller = StreamController<Map<String, dynamic>>();

  realtimeService.subscribeToOffers(
    onInsert: (data) => controller.add({'event': 'insert', 'data': data}),
    onUpdate: (data) => controller.add({'event': 'update', 'data': data}),
    onDelete: (data) => controller.add({'event': 'delete', 'data': data}),
  );

  ref.onDispose(() {
    realtimeService.unsubscribe('offers');
    controller.close();
  });

  return controller.stream;
});

/// Provider for notifications stream
final notificationsStreamProvider =
    StreamProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, userId) {
    final realtimeService = ref.watch(realtimeServiceProvider);
    final controller = StreamController<Map<String, dynamic>>();

    realtimeService.subscribeToNotifications(
      userId: userId,
      onInsert: (data) => controller.add({'event': 'insert', 'data': data}),
      onUpdate: (data) => controller.add({'event': 'update', 'data': data}),
    );

    ref.onDispose(() {
      realtimeService.unsubscribe('notifications');
      controller.close();
    });

    return controller.stream;
  },
);

