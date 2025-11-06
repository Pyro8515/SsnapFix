import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../shared/state/account_controller.dart';
import '../../../shared/widgets/role_toggle.dart';

class CustomerDashboardPage extends ConsumerWidget {
  const CustomerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountState = ref.watch(accountControllerProvider);
    final services = accountState.profile?.services ?? const <String>[
      'Plumbing',
      'Electrical',
      'HVAC',
      'Locksmith',
      'Handyman',
      'Cleaning',
      'Landscaping',
      'Painting',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('GetDone'),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: RoleToggle(),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(accountControllerProvider.notifier).loadProfile(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What do you need fixed?',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: services
                            .map(
                              (service) => ActionChip(
                                label: Text(service),
                                onPressed: () {
                                  context.push(AppRoute.customerBooking.path, extra: service);
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Book again',
                subtitle: 'Quickly rebook professionals you loved working with.',
                icon: Icons.history,
                actionLabel: 'View pros',
                onPressed: () {},
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Active & upcoming jobs',
                subtitle: 'Track progress and arrival times.',
                icon: Icons.map,
                onPressed: () {
                  context.push(AppRoute.customerJobs.path);
                },
                actionLabel: 'See timeline',
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Saved addresses',
                subtitle: 'Manage your frequent service locations.',
                icon: Icons.home_work_outlined,
                onPressed: () {},
                actionLabel: 'Manage',
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Recent activity',
                subtitle: 'Keep track of bookings, payments, and updates.',
                icon: Icons.receipt_long,
                onPressed: () {
                  context.push(AppRoute.customerHistory.path);
                },
                actionLabel: 'View history',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onPressed,
    this.actionLabel,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onPressed;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onPressed,
                child: Text(actionLabel ?? 'Open'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
