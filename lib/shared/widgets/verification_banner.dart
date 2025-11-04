import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../data/models/account_profile.dart';

class VerificationBanner extends StatelessWidget {
  const VerificationBanner({super.key, required this.profile});

  final AccountProfile? profile;

  @override
  Widget build(BuildContext context) {
    final shouldShow = profile != null &&
        profile!.activeRole == AccountRole.professional &&
        !profile!.isVerificationApproved;
    if (!shouldShow) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.verified_outlined,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your professional account is awaiting verification. Complete the steps to go live.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () {
                  context.push(AppRoute.proVerification.path);
                },
                child: const Text('Review'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
