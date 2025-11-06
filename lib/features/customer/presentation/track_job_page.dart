import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router/routes.dart';
import '../../../shared/data/jobs_repository.dart';
import '../../../shared/data/api/dtos/job_dto.dart';
import '../../../shared/theme/app_theme.dart';

/// Real-time job tracking with live map and status timeline
class TrackJobPage extends ConsumerStatefulWidget {
  const TrackJobPage({super.key, required this.jobId});

  final String jobId;

  @override
  ConsumerState<TrackJobPage> createState() => _TrackJobPageState();
}

class _TrackJobPageState extends ConsumerState<TrackJobPage> {
  JobResponse? _job;
  bool _isLoading = true;
  GoogleMapController? _mapController;
  LatLng? _proLocation;
  LatLng? _jobLocation;

  @override
  void initState() {
    super.initState();
    _loadJob();
    _subscribeToJobUpdates();
  }

  Future<void> _loadJob() async {
    try {
      final jobsRepo = ref.read(jobsRepositoryProvider);
      final job = await jobsRepo.getJob(widget.jobId);
      setState(() {
        _job = job;
        if (job.address['lat'] != null && job.address['lng'] != null) {
          _jobLocation = LatLng(
            job.address['lat'] as double,
            job.address['lng'] as double,
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading job: $e')),
        );
      }
    }
  }

  void _subscribeToJobUpdates() {
    // Subscribe to job status changes via Supabase Realtime
    final supabase = Supabase.instance.client;
    supabase
        .from('jobs')
        .stream(primaryKey: ['id'])
        .eq('id', widget.jobId)
        .listen((data) {
      if (data.isNotEmpty) {
        // TODO: Parse job update from realtime
        _loadJob();
      }
    });

    // Subscribe to job events for location updates
    supabase
        .from('job_events')
        .stream(primaryKey: ['id'])
        .eq('job_id', widget.jobId)
        .order('created_at', ascending: false)
        .limit(1)
        .listen((data) {
      if (data.isNotEmpty) {
        // TODO: Extract pro location from job event
        // _updateProLocation(...)
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_job == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Tracking')),
        body: const Center(child: Text('Job not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Job ${_job!.serviceCode.toUpperCase()}'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status Card
            _buildStatusCard(),
            
            // Map
            Expanded(
              flex: 2,
              child: _buildMap(),
            ),
            
            // Timeline
            Expanded(
              flex: 1,
              child: _buildTimeline(),
            ),
            
            // Pro Info & Actions
            _buildProInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final statusColors = {
      'requested': AppColors.warning,
      'assigned': AppColors.info,
      'en_route': AppColors.secondaryCustomer,
      'arrived': AppColors.primary,
      'in_progress': AppColors.primary,
      'completed': AppColors.success,
      'cancelled': AppColors.error,
    };

    final statusLabels = {
      'requested': 'Pending',
      'assigned': 'Assigned',
      'en_route': 'On the way',
      'arrived': 'Arrived',
      'in_progress': 'In Progress',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
    };

    final color = statusColors[_job!.status] ?? AppColors.warning;
    final label = statusLabels[_job!.status] ?? _job!.status;

    return Container(
      padding: const EdgeInsets.all(AppTokens.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: color, width: 2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppTokens.spacingM),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_job!.status == 'en_route' || _job!.status == 'in_progress')
            Text(
              'ETA: 15 min',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (_jobLocation == null) {
      return const Center(child: Text('Location not available'));
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _jobLocation!,
        zoom: 14,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
      },
      markers: {
        // Job location marker
        Marker(
          markerId: const MarkerId('job'),
          position: _jobLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Job Location'),
        ),
        // Pro location marker (if available)
        if (_proLocation != null)
          Marker(
            markerId: const MarkerId('pro'),
            position: _proLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: const InfoWindow(title: 'Pro Location'),
          ),
      },
      polylines: _proLocation != null
          ? {
              Polyline(
                polylineId: const PolylineId('route'),
                points: [_proLocation!, _jobLocation!],
                color: AppColors.primary,
                width: 3,
              ),
            }
          : {},
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }

  Widget _buildTimeline() {
    final statuses = [
      {'status': 'requested', 'label': 'Requested', 'icon': Icons.schedule},
      {'status': 'assigned', 'label': 'Assigned', 'icon': Icons.person_add},
      {'status': 'en_route', 'label': 'On the way', 'icon': Icons.directions_car},
      {'status': 'arrived', 'label': 'Arrived', 'icon': Icons.location_on},
      {'status': 'in_progress', 'label': 'In Progress', 'icon': Icons.build},
      {'status': 'completed', 'label': 'Completed', 'icon': Icons.check_circle},
    ];

    final currentStatusIndex = statuses.indexWhere(
      (s) => s['status'] == _job!.status,
    );

    return Container(
      padding: const EdgeInsets.all(AppTokens.spacingM),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: statuses.length,
        itemBuilder: (context, index) {
          final status = statuses[index];
          final isCompleted = index <= currentStatusIndex;
          final isCurrent = index == currentStatusIndex;

          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: AppTokens.spacingM),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.primary : AppColors.borderCustomer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    status['icon'] as IconData,
                    color: isCompleted ? Colors.white : AppColors.textSecondaryCustomer,
                    size: 20,
                  ),
                ),
                const SizedBox(height: AppTokens.spacingS),
                Text(
                  status['label'] as String,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isCompleted ? AppColors.primary : AppColors.textSecondaryCustomer,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (index < statuses.length - 1)
                  Container(
                    width: 50,
                    height: 2,
                    margin: const EdgeInsets.only(top: AppTokens.spacingS),
                    color: isCompleted ? AppColors.primary : AppColors.borderCustomer,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProInfo() {
    // TODO: Fetch pro info from API
    final proName = 'John D.';
    final proRating = 4.8;
    final proExperience = '5 years';

    return Container(
      padding: const EdgeInsets.all(AppTokens.spacingM),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: AppTokens.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text('$proRating', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(width: AppTokens.spacingM),
                        Text('$proExperience experience', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spacingM),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement Twilio Proxy calling
                  },
                  icon: const Icon(Icons.phone),
                  label: const Text('Call'),
                ),
              ),
              const SizedBox(width: AppTokens.spacingM),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    // TODO: Navigate to messaging
                  },
                  icon: const Icon(Icons.message),
                  label: const Text('Message'),
                ),
              ),
            ],
          ),
          if (_job?.status == 'completed') ...[
            const SizedBox(height: AppTokens.spacingM),
            FilledButton.icon(
              onPressed: () {
                context.push('${AppRoute.customerRatings.path}/${_job!.id}');
              },
              icon: const Icon(Icons.star),
              label: const Text('Rate This Job'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondaryCustomer,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
