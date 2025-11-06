import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../shared/data/api/api_client.dart';
import '../../../shared/data/api/dtos/error_response.dart';
import '../../../shared/data/api/dtos/offer_dto.dart';
import '../../../shared/data/models/account_profile.dart';
import '../../../shared/data/offers_repository.dart';
import '../../../shared/state/account_controller.dart';

final offersRepositoryProvider = Provider<OffersRepository>((ref) {
  final apiClient = ApiClient();
  return OffersRepository(apiClient);
});

final offersProvider = FutureProvider<List<Offer>>((ref) async {
  final repository = ref.watch(offersRepositoryProvider);
  final accountState = ref.watch(accountControllerProvider);
  final profile = accountState.profile;

  // For professionals, filter by their compliant trades
  String? trade;
  if (profile?.activeRole == AccountRole.professional && profile?.services.isNotEmpty == true) {
    // For now, show all offers - server will filter by compliance
    trade = null;
  }

  return repository.fetchOffers(trade: trade);
});

class ProJobsPage extends ConsumerWidget {
  const ProJobsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(offersProvider);
    final accountState = ref.watch(accountControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Jobs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(offersProvider);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: offersAsync.when(
          data: (offers) {
            if (offers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.work_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No jobs available',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back later for new opportunities',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(offersProvider);
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: offers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final offer = offers[index];
                  return _OfferCard(
                    offer: offer,
                    onAccept: () => _handleAccept(context, ref, offer, accountState),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load jobs',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    ref.invalidate(offersProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAccept(
    BuildContext context,
    WidgetRef ref,
    Offer offer,
    AccountState accountState,
  ) async {
    if (!context.mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final repository = ref.read(offersRepositoryProvider);
      
      // TODO: Get user location if available
      await repository.acceptOffer(offerId: offer.id);

      if (!context.mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully accepted: ${offer.jobTitle}'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh offers list
      ref.invalidate(offersProvider);
    } on OfferAcceptException catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      // Show error with reasons
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot Accept Offer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.error),
              if (e.reasons.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Reasons:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...e.reasons.map(
                  (reason) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(reason)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            if (e.reasons.any((r) => r.toLowerCase().contains('verification')))
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push(AppRoute.proVerification.path);
                },
                child: const Text('Review Verification'),
              ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.onAccept,
  });

  final Offer offer;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.jobTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (offer.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          offer.description!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (offer.locationLat != null && offer.locationLng != null)
                  Icon(
                    Icons.location_on_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...offer.trade.map(
                  (t) => Chip(
                    label: Text(t),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Posted ${_formatDate(offer.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                FilledButton(
                  onPressed: onAccept,
                  child: const Text('Accept'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    }
    return 'Just now';
  }
}
