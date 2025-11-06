import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app/router/routes.dart';
import '../../../shared/data/jobs_repository.dart';
import '../../../shared/data/api/dtos/job_dto.dart';
import '../../../shared/theme/app_theme.dart';

/// Professional job detail page for managing jobs
class ProJobDetailPage extends ConsumerStatefulWidget {
  const ProJobDetailPage({super.key, required this.jobId});

  final String jobId;

  @override
  ConsumerState<ProJobDetailPage> createState() => _ProJobDetailPageState();
}

class _ProJobDetailPageState extends ConsumerState<ProJobDetailPage> {
  JobResponse? _job;
  bool _isLoading = true;
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _workPhoto;
  final _notesController = TextEditingController();
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _loadJob();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadJob() async {
    try {
      final jobsRepo = ref.read(jobsRepositoryProvider);
      final job = await jobsRepo.getJob(widget.jobId);
      setState(() {
        _job = job;
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

  Future<void> _updateStatus(String status) async {
    setState(() => _isUpdatingStatus = true);
    try {
      final jobsRepo = ref.read(jobsRepositoryProvider);
      await jobsRepo.updateJobStatus(
        jobId: widget.jobId,
        status: status,
      );
      await _loadJob();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_job == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Details')),
        body: const Center(child: Text('Job not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Job #${_job!.id.substring(0, 8)}'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Card
              _buildStatusCard(),
              const SizedBox(height: AppTokens.spacingM),
              
              // Quick Actions
              _buildQuickActions(),
              const SizedBox(height: AppTokens.spacingM),
              
              // Job Details
              _buildJobDetails(),
              const SizedBox(height: AppTokens.spacingM),
              
              // Customer Info
              _buildCustomerInfo(),
              const SizedBox(height: AppTokens.spacingM),
              
              // Location Map
              _buildLocationMap(),
              const SizedBox(height: AppTokens.spacingM),
              
              // Work Photos
              _buildWorkPhotos(),
              const SizedBox(height: AppTokens.spacingM),
              
              // Notes
              _buildNotes(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final statusColors = {
      'assigned': AppColors.info,
      'en_route': AppColors.secondaryCustomer,
      'arrived': AppColors.primary,
      'in_progress': AppColors.primary,
      'completed': AppColors.success,
    };

    final color = statusColors[_job!.status] ?? AppColors.warning;

    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingM),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: color),
            const SizedBox(width: AppTokens.spacingM),
            Expanded(
              child: Text(
                'Status: ${_job!.status.toUpperCase()}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTokens.spacingM),
            Wrap(
              spacing: AppTokens.spacingM,
              runSpacing: AppTokens.spacingM,
              children: [
                if (_job!.status == 'assigned')
                  FilledButton.icon(
                    onPressed: _isUpdatingStatus ? null : () => _updateStatus('en_route'),
                    icon: const Icon(Icons.directions_car),
                    label: const Text('Start Driving'),
                  ),
                if (_job!.status == 'en_route')
                  FilledButton.icon(
                    onPressed: _isUpdatingStatus ? null : () => _updateStatus('arrived'),
                    icon: const Icon(Icons.location_on),
                    label: const Text('Mark Arrived'),
                  ),
                if (_job!.status == 'arrived')
                  FilledButton.icon(
                    onPressed: _isUpdatingStatus ? null : () => _updateStatus('in_progress'),
                    icon: const Icon(Icons.build),
                    label: const Text('Start Work'),
                  ),
                if (_job!.status == 'in_progress')
                  FilledButton.icon(
                    onPressed: _isUpdatingStatus ? null : () => _updateStatus('completed'),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Complete'),
                  ),
                if (_job!.status != 'completed')
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to messaging
                    },
                    icon: const Icon(Icons.message),
                    label: const Text('Message'),
                  ),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Make phone call via Twilio Proxy
                  },
                  icon: const Icon(Icons.phone),
                  label: const Text('Call'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTokens.spacingM),
            _DetailRow(
              label: 'Service',
              value: _job!.serviceCode.toUpperCase(),
            ),
            const SizedBox(height: AppTokens.spacingS),
            _DetailRow(
              label: 'Payout',
              value: '\$${(_job!.payoutCents ?? 0) / 100}',
              valueColor: AppColors.success,
            ),
            if (_job!.scheduledStart != null) ...[
              const SizedBox(height: AppTokens.spacingS),
              _DetailRow(
                label: 'Scheduled Start',
                value: DateTime.parse(_job!.scheduledStart!).toLocal().toString().split('.')[0],
              ),
            ],
            if (_job!.notes != null && _job!.notes!.isNotEmpty) ...[
              const SizedBox(height: AppTokens.spacingS),
              _DetailRow(
                label: 'Notes',
                value: _job!.notes!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    // TODO: Fetch customer info from API
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Info',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTokens.spacingM),
            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: AppTokens.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jane S.',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        '⭐ 4.9 • 47 reviews',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationMap() {
    if (_job!.address['lat'] == null || _job!.address['lng'] == null) {
      return const SizedBox.shrink();
    }

    final location = LatLng(
      _job!.address['lat'] as double,
      _job!.address['lng'] as double,
    );

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTokens.spacingM),
            child: Text(
              'Location',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SizedBox(
            height: 200,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: location,
                zoom: 14,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('job'),
                  position: location,
                  infoWindow: InfoWindow(title: _job!.address['street'] ?? 'Job Location'),
                ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTokens.spacingM),
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Open in maps app
              },
              icon: const Icon(Icons.navigation),
              label: const Text('Open in Maps'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkPhotos() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Work Photos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTokens.spacingM),
            if (_workPhoto != null)
              Stack(
                children: [
                  Image.file(
                    File(_workPhoto!.path),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _workPhoto = null),
                    ),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: () async {
                  final photo = await _imagePicker.pickImage(source: ImageSource.camera);
                  if (photo != null) {
                    setState(() => _workPhoto = photo);
                    // TODO: Upload photo to storage
                  }
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job Notes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTokens.spacingM),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add notes about the job...',
              ),
            ),
            const SizedBox(height: AppTokens.spacingM),
            FilledButton(
              onPressed: () {
                // TODO: Save notes
              },
              child: const Text('Save Notes'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondaryPro,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: valueColor,
              fontWeight: valueColor != null ? FontWeight.bold : null,
            ),
          ),
        ),
      ],
    );
  }
}

