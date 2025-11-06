import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../shared/state/account_controller.dart';
import '../../../../shared/state/verification_step_state.dart';

class VerificationWizardPage extends ConsumerWidget {
  const VerificationWizardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(accountControllerProvider).profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Professional Verification'),
        actions: [
          if (profile?.isVerificationApproved == true)
            IconButton(
              icon: const Icon(Icons.check_circle),
              color: Theme.of(context).colorScheme.primary,
              onPressed: () {
                context.pop();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Header
            Text(
              'Complete Your Verification',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete all 5 steps to start accepting jobs',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Step 1: Profile & Services
            _VerificationStepCard(
              step: 1,
              title: 'Profile & Services',
              description: 'Complete your bio and select the trades you offer.',
              status: profile?.profileStepStatus ?? StepStatus.pending,
              onTap: () {
                // TODO: Navigate to profile step
                _showStepDialog(context, 1, 'Profile & Services');
              },
            ),
            const SizedBox(height: 12),

            // Step 2: Identity Verification
            _VerificationStepCard(
              step: 2,
              title: 'Identity Verification',
              description: 'Complete Stripe Identity to verify who you are.',
              status: profile?.identityStatus ?? StepStatus.pending,
              onTap: () {
                // TODO: Navigate to Stripe Identity
                _showStepDialog(context, 2, 'Identity Verification');
              },
            ),
            const SizedBox(height: 12),

            // Step 3: Documents
            _VerificationStepCard(
              step: 3,
              title: 'Documents',
              description: 'Upload required trade certifications and insurance.',
              status: profile?.documentsStatus ?? StepStatus.pending,
              onTap: () {
                // TODO: Navigate to documents step
                _showStepDialog(context, 3, 'Documents');
              },
            ),
            const SizedBox(height: 12),

            // Step 4: Payouts
            _VerificationStepCard(
              step: 4,
              title: 'Payouts',
              description: 'Connect a bank account to get paid.',
              status: profile?.payoutsStatusStep ?? StepStatus.pending,
              onTap: () {
                // TODO: Navigate to payouts setup
                _showStepDialog(context, 4, 'Payouts');
              },
            ),
            const SizedBox(height: 12),

            // Step 5: Background Check
            _VerificationStepCard(
              step: 5,
              title: 'Background Check',
              description: 'Complete the background screening when available.',
              status: profile?.backgroundStatus ?? StepStatus.pending,
              onTap: () {
                // TODO: Navigate to background check
                _showStepDialog(context, 5, 'Background Check');
              },
            ),

            const SizedBox(height: 32),

            // Continue button
            FilledButton(
              onPressed: () {
                // Find first incomplete step
                final steps = [
                  (profile?.profileStepStatus ?? StepStatus.pending, 1),
                  (profile?.identityStatus ?? StepStatus.pending, 2),
                  (profile?.documentsStatus ?? StepStatus.pending, 3),
                  (profile?.payoutsStatusStep ?? StepStatus.pending, 4),
                  (profile?.backgroundStatus ?? StepStatus.pending, 5),
                ];

                final incompleteStep = steps.firstWhere(
                  (s) => s.$1 != StepStatus.complete,
                  orElse: () => (StepStatus.complete, 0),
                );

                if (incompleteStep.$2 == 0) {
                  // All complete
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All verification steps are complete!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  context.pop();
                } else {
                  _showStepDialog(context, incompleteStep.$2, 'Next Step');
                }
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Continue Verification'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStepDialog(BuildContext context, int step, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Step $step: $title'),
        content: Text('This step will be implemented in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _VerificationStepCard extends StatelessWidget {
  const _VerificationStepCard({
    required this.step,
    required this.title,
    required this.description,
    required this.status,
    this.onTap,
  });

  final int step;
  final String title;
  final String description;
  final StepStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color statusColor;
    final IconData statusIcon;

    switch (status) {
      case StepStatus.complete:
        statusColor = colorScheme.primary;
        statusIcon = Icons.check_circle;
        break;
      case StepStatus.inReview:
        statusColor = colorScheme.tertiary;
        statusIcon = Icons.hourglass_empty;
        break;
      case StepStatus.pending:
      default:
        statusColor = colorScheme.outline;
        statusIcon = Icons.circle_outlined;
        break;
    }

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.1),
                foregroundColor: statusColor,
                radius: 24,
                child: status == StepStatus.complete
                    ? Icon(statusIcon, size: 24)
                    : Text(
                        '$step',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        Icon(
                          statusIcon,
                          size: 20,
                          color: statusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      status.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
