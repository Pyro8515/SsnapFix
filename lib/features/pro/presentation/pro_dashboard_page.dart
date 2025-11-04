import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../shared/state/account_controller.dart';
import '../../../shared/widgets/role_toggle.dart';
import '../../../shared/widgets/verification_banner.dart';

class ProDashboardPage extends ConsumerWidget {
  const ProDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountState = ref.watch(accountControllerProvider);
    final profile = accountState.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pro home'),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: RoleToggle(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            VerificationBanner(profile: profile),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(accountControllerProvider.notifier).loadProfile(),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SwitchListTile(
                      title: const Text('Online status'),
                      subtitle: const Text('Allow GetDone to send you new jobs.'),
                      value: accountState.isOnline,
                      onChanged: (value) => ref
                          .read(accountControllerProvider.notifier)
                          .updateOnlineStatus(value),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available jobs',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Jobs you are eligible for will appear here. Accept quickly to secure the work.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () {
                                context.push(AppRoute.proJobs.path);
                              },
                              icon: const Icon(Icons.work_outline),
                              label: const Text('Browse offers'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account snapshot',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text('Services: ${profile?.services.join(', ') ?? 'Not set'}'),
                            const SizedBox(height: 4),
                            Text('Verification: ${profile?.verificationStatus.label ?? 'Unknown'}'),
                            const SizedBox(height: 4),
                            Text('Payouts: ${profile?.payoutsStatus ?? 'Unknown'}'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
