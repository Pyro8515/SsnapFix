import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../shared/data/api/dtos/user_response.dart';
import '../../../shared/state/account_controller.dart';
import '../../../shared/widgets/doc_upload_tile.dart';

class ProAccountPage extends ConsumerWidget {
  const ProAccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountState = ref.watch(accountControllerProvider);
    final profile = accountState.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(accountControllerProvider.notifier).loadProfile(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage: profile?.avatarUrl != null
                            ? NetworkImage(profile!.avatarUrl!)
                            : null,
                        child: profile?.avatarUrl == null
                            ? const Icon(Icons.person_outline, size: 32)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile?.fullName ?? 'Complete your profile',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            if (profile?.email != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                profile!.email!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                            if (profile?.verificationStatus != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    profile!.isVerificationApproved
                                        ? Icons.verified
                                        : Icons.pending,
                                    size: 16,
                                    color: profile.isVerificationApproved
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.outline,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    profile.verificationStatus.label,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: profile.isVerificationApproved
                                              ? Theme.of(context).colorScheme.primary
                                              : null,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () {
                          context.push(AppRoute.proVerification.path);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Documents section
              if (profile?.documents != null && profile!.documents.isNotEmpty) ...[
                Text(
                  'Documents',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...profile.documents.map(
                  (doc) => DocUploadTile(
                    docType: doc.name,
                    status: doc.status,
                    onTap: () {
                      // TODO: Navigate to document details
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Services section
              Card(
                child: ListTile(
                  leading: const Icon(Icons.build_outlined),
                  title: const Text('Services'),
                  subtitle: Text(
                    profile?.services.join(', ') ?? 'Not set',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push(AppRoute.proVerification.path);
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Payouts section
              Card(
                child: ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: const Text('Payouts'),
                  subtitle: Text(
                    profile?.payoutsStatus ?? 'Not started',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to payouts setup
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Trade compliance section
              if (profile?.tradeCompliance != null && profile!.tradeCompliance!.isNotEmpty) ...[
                Card(
                  child: ExpansionTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: const Text('Trade Compliance'),
                    subtitle: Text('${profile.tradeCompliance!.length} trades'),
                    children: [
                      // TODO: Show detailed compliance info
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Compliance details coming soon'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Verification section
              Card(
                child: ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: const Text('Verification'),
                  subtitle: const Text('Complete all verification steps'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push(AppRoute.proVerification.path);
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Sign out
              FilledButton.icon(
                onPressed: () async {
                  await ref.read(accountControllerProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go(AppRoute.splash.path);
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
