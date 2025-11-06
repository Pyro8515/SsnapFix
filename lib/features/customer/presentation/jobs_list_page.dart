import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../shared/data/jobs_repository.dart';
import '../../../shared/data/api/dtos/job_dto.dart';
import '../../../shared/theme/app_theme.dart';

/// Customer jobs list page showing active and past jobs
final customerJobsProvider = FutureProvider.family<List<JobResponse>, String?>((ref, status) async {
  final jobsRepo = ref.read(jobsRepositoryProvider);
  return jobsRepo.getUserJobs(status: status);
});

class CustomerJobsListPage extends ConsumerWidget {
  const CustomerJobsListPage({super.key, this.status});

  final String? status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(customerJobsProvider(status));

    return Scaffold(
      appBar: AppBar(
        title: Text(status == null ? 'All Jobs' : 'Active Jobs'),
      ),
      body: SafeArea(
        child: jobsAsync.when(
          data: (jobs) {
            if (jobs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.work_outline,
                      size: 64,
                      color: AppColors.textSecondaryCustomer,
                    ),
                    const SizedBox(height: AppTokens.spacingM),
                    Text(
                      'No jobs found',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppTokens.spacingS),
                    Text(
                      'Your jobs will appear here',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(customerJobsProvider(status));
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(AppTokens.spacingM),
                itemCount: jobs.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppTokens.spacingM),
                itemBuilder: (context, index) {
                  final job = jobs[index];
                  return _JobCard(job: job);
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: AppTokens.spacingM),
                Text(
                  'Failed to load jobs',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppTokens.spacingS),
                FilledButton.icon(
                  onPressed: () {
                    ref.invalidate(customerJobsProvider(status));
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job});

  final JobResponse job;

  @override
  Widget build(BuildContext context) {
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

    final color = statusColors[job.status] ?? AppColors.warning;
    final label = statusLabels[job.status] ?? job.status;

    return Card(
      child: InkWell(
        onTap: () {
          context.push('${AppRoute.customerTrack.path}/${job.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.spacingS,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: color),
                    ),
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '\$${(job.priceCents / 100).toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.spacingM),
              Text(
                job.serviceCode.toUpperCase(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (job.address['street'] != null) ...[
                const SizedBox(height: AppTokens.spacingS),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: AppColors.textSecondaryCustomer),
                    const SizedBox(width: AppTokens.spacingS),
                    Expanded(
                      child: Text(
                        job.address['street'] ?? 'Location',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
              if (job.scheduledStart != null) ...[
                const SizedBox(height: AppTokens.spacingS),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: AppColors.textSecondaryCustomer),
                    const SizedBox(width: AppTokens.spacingS),
                    Text(
                      DateTime.parse(job.scheduledStart!).toLocal().toString().split('.')[0],
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppTokens.spacingM),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      context.push('${AppRoute.customerTrack.path}/${job.id}');
                    },
                    child: const Text('View Details'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

