import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../shared/data/api/api_client.dart';
import '../../../shared/data/api/dtos/offer_dto.dart';
import '../../../shared/data/offers_repository.dart';
import '../../../shared/state/account_controller.dart';
import '../../../shared/widgets/role_toggle.dart';
import '../../../shared/widgets/verification_banner.dart';

final offersRepositoryProvider = Provider<OffersRepository>((ref) {
  final apiClient = ApiClient();
  return OffersRepository(apiClient);
});

final recentOffersProvider = FutureProvider<List<Offer>>((ref) async {
  final repository = ref.watch(offersRepositoryProvider);
  final accountState = ref.watch(accountControllerProvider);
  final profile = accountState.profile;

  // For professionals, only show compliant offers
  String? trade;
  if (profile?.activeRole == AccountRole.professional && profile?.services.isNotEmpty == true) {
    trade = null; // Server filters by compliance
  }

  final offers = await repository.fetchOffers(trade: trade);
  // Return first 5 offers
  return offers.take(5).toList();
});

class ProDashboardPage extends ConsumerWidget {
  const ProDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountState = ref.watch(accountControllerProvider);
    final profile = accountState.profile;
    final recentOffersAsync = ref.watch(recentOffersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pro Dashboard'),
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
                onRefresh: () async {
                  ref.invalidate(accountControllerProvider);
                  ref.invalidate(recentOffersProvider);
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Online toggle
                    Card(
                      child: SwitchListTile(
                        title: const Text('Online Status'),
                        subtitle: const Text('Allow GetDone to send you new jobs'),
                        value: accountState.isOnline,
                        onChanged: (value) => ref
                            .read(accountControllerProvider.notifier)
                            .updateOnlineStatus(value),
                        secondary: Icon(
                          accountState.isOnline ? Icons.check_circle : Icons.circle_outlined,
                          color: accountState.isOnline
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Recent offers section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Available Jobs',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                TextButton(
                                  onPressed: () {
                                    context.push(AppRoute.proJobs.path);
                                  },
                                  child: const Text('View All'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            recentOffersAsync.when(
                              data: (offers) {
                                if (offers.isEmpty) {
                                  return Column(
                                    children: [
                                      Icon(
                                        Icons.work_outline,
                                        size: 48,
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No jobs available',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          context.push(AppRoute.proJobs.path);
                                        },
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Check for Jobs'),
                                      ),
                                    ],
                                  );
                                }

                                return Column(
                                  children: [
                                    ...offers.map(
                                      (offer) => ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(offer.jobTitle),
                                        subtitle: Text(
                                          offer.trade.join(', '),
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                        trailing: const Icon(Icons.chevron_right),
                                        onTap: () {
                                          context.push(AppRoute.proJobs.path);
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    FilledButton.icon(
                                      onPressed: () {
                                        context.push(AppRoute.proJobs.path);
                                      },
                                      icon: const Icon(Icons.work_outline),
                                      label: const Text('Browse All Offers'),
                                    ),
                                  ],
                                );
                              },
                              loading: () => const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (_, __) => Column(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Failed to load jobs',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      ref.invalidate(recentOffersProvider);
                                    },
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Account snapshot
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Snapshot',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              label: 'Services',
                              value: profile?.services.join(', ') ?? 'Not set',
                              icon: Icons.build_outlined,
                            ),
                            const SizedBox(height: 8),
                            _InfoRow(
                              label: 'Verification',
                              value: profile?.verificationStatus.label ?? 'Unknown',
                              icon: Icons.verified_outlined,
                              valueColor: profile?.isVerificationApproved == true
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            _InfoRow(
                              label: 'Payouts',
                              value: profile?.payoutsStatus ?? 'Not started',
                              icon: Icons.payments_outlined,
                            ),
                            if (profile?.tradeCompliance != null &&
                                profile!.tradeCompliance!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _InfoRow(
                                label: 'Trade Compliance',
                                value: '${profile.tradeCompliance!.length} trades',
                                icon: Icons.check_circle_outline,
                              ),
                            ],
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              // Already on dashboard
              break;
            case 1:
              context.push(AppRoute.proJobs.path);
              break;
            case 2:
              context.push(AppRoute.proMap.path);
              break;
            case 3:
              context.push(AppRoute.proEarnings.path);
              break;
            case 4:
              context.push(AppRoute.proAccount.path);
              break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.work_outline), label: 'Jobs'),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.attach_money), label: 'Earnings'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
        ),
      ],
    );
  }
}
