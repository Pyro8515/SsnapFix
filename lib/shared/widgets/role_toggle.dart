import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/account_profile.dart';
import '../state/account_controller.dart';

class RoleToggle extends ConsumerWidget {
  const RoleToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountState = ref.watch(accountControllerProvider);
    final profile = accountState.profile;
    if (profile == null || !profile.canToggleRole) {
      return const SizedBox.shrink();
    }

    final selection = <AccountRole>{profile.activeRole};

    return SegmentedButton<AccountRole>(
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      segments: const [
        ButtonSegment<AccountRole>(
          value: AccountRole.customer,
          label: Text('Customer'),
          icon: Icon(Icons.home_outlined),
        ),
        ButtonSegment<AccountRole>(
          value: AccountRole.professional,
          label: Text('Pro'),
          icon: Icon(Icons.handyman_outlined),
        ),
      ],
      selected: selection,
      onSelectionChanged: (newSelection) async {
        final target = newSelection.first;
        final success = await ref.read(accountControllerProvider.notifier).switchRole(target);
        if (!success && target == AccountRole.professional) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Complete verification to access professional tools.'),
              ),
            );
          }
        }
      },
    );
  }
}
