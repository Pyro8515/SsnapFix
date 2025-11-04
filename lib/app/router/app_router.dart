import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/magic_link_page.dart';
import '../../features/customer/presentation/booking_page.dart';
import '../../features/customer/presentation/customer_dashboard_page.dart';
import '../../features/customer/presentation/track_job_page.dart';
import '../../features/pro/presentation/account_page.dart';
import '../../features/pro/presentation/jobs_page.dart';
import '../../features/pro/presentation/map_page.dart';
import '../../features/pro/presentation/messages_page.dart';
import '../../features/pro/presentation/pro_dashboard_page.dart';
import '../../features/pro/presentation/verification/verification_page.dart';
import '../../features/splash/presentation/splash_page.dart';
import '../../shared/data/models/account_profile.dart';
import '../../shared/state/account_controller.dart';
import 'routes.dart';

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  final notifier = RouterNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);
  return GoRouter(
    initialLocation: AppRoute.splash.path,
    refreshListenable: notifier,
    routes: [
      GoRoute(
        path: AppRoute.splash.path,
        name: AppRoute.splash.name,
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoute.authLogin.path,
        name: AppRoute.authLogin.name,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoute.authMagicLink.path,
        name: AppRoute.authMagicLink.name,
        builder: (_, __) => const MagicLinkPage(),
      ),
      GoRoute(
        path: AppRoute.customerDashboard.path,
        name: AppRoute.customerDashboard.name,
        builder: (_, state) => const CustomerDashboardPage(),
      ),
      GoRoute(
        path: AppRoute.customerBooking.path,
        name: AppRoute.customerBooking.name,
        builder: (_, state) => BookingPage(service: state.extra as String?),
      ),
      GoRoute(
        path: AppRoute.customerTrack.path,
        name: AppRoute.customerTrack.name,
        builder: (_, state) => TrackJobPage(jobId: state.pathParameters['jobId'] ?? ''),
      ),
      GoRoute(
        path: AppRoute.proDashboard.path,
        name: AppRoute.proDashboard.name,
        builder: (_, __) => const ProDashboardPage(),
      ),
      GoRoute(
        path: AppRoute.proJobs.path,
        name: AppRoute.proJobs.name,
        builder: (_, __) => const ProJobsPage(),
      ),
      GoRoute(
        path: AppRoute.proMap.path,
        name: AppRoute.proMap.name,
        builder: (_, __) => const ProMapPage(),
      ),
      GoRoute(
        path: AppRoute.proMessages.path,
        name: AppRoute.proMessages.name,
        builder: (_, __) => const ProMessagesPage(),
      ),
      GoRoute(
        path: AppRoute.proAccount.path,
        name: AppRoute.proAccount.name,
        builder: (_, __) => const ProAccountPage(),
      ),
      GoRoute(
        path: AppRoute.proVerification.path,
        name: AppRoute.proVerification.name,
        builder: (_, __) => const VerificationWizardPage(),
      ),
    ],
    redirect: notifier.handleRedirect,
  );
});

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this.ref) {
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
    _accountSub = ref.listen<AccountState>(accountControllerProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref ref;
  late final StreamSubscription<AuthState> _authSub;
  late final ProviderSubscription<AccountState> _accountSub;

  bool get isAuthenticated => Supabase.instance.client.auth.currentSession != null;

  @override
  void dispose() {
    _authSub.cancel();
    _accountSub.close();
    super.dispose();
  }

  String? handleRedirect(BuildContext context, GoRouterState state) {
    final loggingIn = state.matchedLocation.startsWith('/auth');
    if (!isAuthenticated) {
      return loggingIn ? null : AppRoute.authLogin.path;
    }

    final accountState = ref.read(accountControllerProvider);
    final profile = accountState.profile;

    if (loggingIn) {
      return _destinationFor(profile);
    }

    if (profile == null) {
      return AppRoute.splash.path;
    }

    if (state.matchedLocation == AppRoute.splash.path) {
      return _destinationFor(profile);
    }

    if (accountState.shouldPromptVerification &&
        state.matchedLocation.startsWith('/pro') &&
        state.matchedLocation != AppRoute.proVerification.path) {
      ref.read(accountControllerProvider.notifier).acknowledgeVerificationPrompt();
      return AppRoute.proVerification.path;
    }

    return null;
  }

  String _destinationFor(AccountProfile? profile) {
    if (profile == null) {
      return AppRoute.splash.path;
    }

    if (profile.activeRole == AccountRole.professional) {
      if (profile.isVerificationApproved) {
        return AppRoute.proDashboard.path;
      }
      return AppRoute.proVerification.path;
    }

    return AppRoute.customerDashboard.path;
  }
}
