import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/state/account_controller.dart';

class ProAccountPage extends ConsumerWidget {
  const ProAccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountState = ref.watch(accountControllerProvider);
    final profile = accountState.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(profile?.fullName ?? 'Complete your profile'),
              subtitle: Text(profile?.email ?? 'Add contact info'),
              trailing: IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {},
              ),
            ),
            const Divider(height: 32),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Documents'),
              subtitle: Text('${profile?.documents.length ?? 0} uploaded'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Payouts'),
              subtitle: Text(profile?.payoutsStatus ?? 'Not started'),
              onTap: () {},
            ),
            const Divider(height: 32),
            FilledButton.icon(
              onPressed: () async {
                await ref.read(accountControllerProvider.notifier).signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
