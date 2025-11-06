import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../shared/data/ratings_repository.dart';
import '../../../shared/data/api/dtos/rating_dto.dart';
import '../../../shared/data/jobs_repository.dart';
import '../../../shared/data/api/dtos/job_dto.dart';
import '../../../shared/theme/app_theme.dart';

/// Rating page for customers to rate completed jobs
class RatingPage extends ConsumerStatefulWidget {
  const RatingPage({super.key, required this.jobId});

  final String jobId;

  @override
  ConsumerState<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends ConsumerState<RatingPage> {
  int _selectedRating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  JobResponse? _job;
  RatingResponse? _existingRating;

  @override
  void initState() {
    super.initState();
    _loadJob();
    _loadExistingRating();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadJob() async {
    try {
      final jobsRepo = ref.read(jobsRepositoryProvider);
      final job = await jobsRepo.getJob(widget.jobId);
      setState(() => _job = job);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading job: $e')),
        );
      }
    }
  }

  Future<void> _loadExistingRating() async {
    try {
      final ratingsRepo = ref.read(ratingsRepositoryProvider);
      final rating = await ratingsRepo.getRatingForJob(widget.jobId);
      if (rating != null) {
        setState(() {
          _existingRating = rating;
          _selectedRating = rating.rating;
          _commentController.text = rating.comment ?? '';
        });
      }
    } catch (e) {
      // Ignore - no existing rating
    }
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final ratingsRepo = ref.read(ratingsRepositoryProvider);
      await ratingsRepo.createOrUpdateRating(
        jobId: widget.jobId,
        rating: _selectedRating,
        comment: _commentController.text.isEmpty ? null : _commentController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rating submitted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting rating: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Your Experience'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_job != null) ...[
                Text(
                  'How was your service?',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: AppTokens.spacingS),
                Text(
                  '${_job!.serviceCode.toUpperCase()} - ${_job!.address['street'] ?? 'Location'}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ] else
                const Center(child: CircularProgressIndicator()),
              
              const SizedBox(height: AppTokens.spacingXL),
              
              // Star Rating
              Center(
                child: Column(
                  children: [
                    Text(
                      'Tap stars to rate',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTokens.spacingM),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        final rating = index + 1;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedRating = rating),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              rating <= _selectedRating ? Icons.star : Icons.star_border,
                              size: 56,
                              color: rating <= _selectedRating
                                  ? AppColors.warning
                                  : AppColors.borderCustomer,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: AppTokens.spacingS),
                    if (_selectedRating > 0)
                      Text(
                        _getRatingLabel(_selectedRating),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppTokens.spacingXL),
              
              // Comment Field
              Text(
                'Share your experience (Optional)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppTokens.spacingM),
              TextField(
                controller: _commentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Tell others about your experience...',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: AppTokens.spacingXL),
              
              // Submit Button
              FilledButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_existingRating != null ? 'Update Rating' : 'Submit Rating'),
              ),
              
              if (_existingRating != null) ...[
                const SizedBox(height: AppTokens.spacingM),
                TextButton(
                  onPressed: () {
                    // TODO: Delete rating
                  },
                  child: const Text('Remove Rating'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }
}

