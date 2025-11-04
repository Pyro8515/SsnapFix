import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/state/account_controller.dart';
import '../../../../shared/state/verification_step_state.dart';

class VerificationWizardPage extends ConsumerWidget {
  const VerificationWizardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(accountControllerProvider).profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Professional verification')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _VerificationStep(
              step: 1,
              title: 'Profile & services',
              description: 'Complete your bio and select the trades you offer.',
              status: profile?.profileStepStatus ?? StepStatus.pending,
            ),
            _VerificationStep(
              step: 2,
              title: 'Identity verification',
              description: 'Complete Stripe Identity to verify who you are.',
              status: profile?.identityStatus ?? StepStatus.pending,
            ),
            _VerificationStep(
              step: 3,
              title: 'Documents',
              description: 'Upload required trade certifications and insurance.',
              status: profile?.documentsStatus ?? StepStatus.pending,
            ),
            _VerificationStep(
              step: 4,
              title: 'Payouts',
              description: 'Connect a bank account to get paid.',
              status: profile?.payoutsStatusStep ?? StepStatus.pending,
            ),
            _VerificationStep(
              step: 5,
              title: 'Background check',
              description: 'Complete the background screening when available.',
              status: profile?.backgroundStatus ?? StepStatus.pending,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {},
              child: const Text('Continue verification'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationStep extends StatelessWidget {
  const _VerificationStep({
    required this.step,
    required this.title,
    required this.description,
    required this.status,
  });

  final int step;
  final String title;
  final String description;
  final StepStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color statusColor;
    switch (status) {
      case StepStatus.complete:
        statusColor = colorScheme.primary;
        break;
      case StepStatus.inReview:
        statusColor = colorScheme.tertiary;
        break;
      case StepStatus.pending:
      default:
        statusColor = colorScheme.outline;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.1),
              foregroundColor: statusColor,
              child: Text('$step'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(description),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Text(status.label),
          ],
        ),
      ),
    );
  }
}
