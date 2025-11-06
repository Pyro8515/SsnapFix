import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/state/account_controller.dart';
import '../shared/theme/app_theme.dart';
import 'router/app_router.dart';

class GetDoneApp extends ConsumerWidget {
  const GetDoneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final accountState = ref.watch(accountControllerProvider);
    
    // Determine theme based on active role
    final isPro = accountState.profile?.activeRole == AccountRole.professional;
    final theme = isPro ? ProfessionalTheme.theme : CustomerTheme.theme;

    return MaterialApp.router(
      title: 'GetDone',
      routerConfig: router,
      theme: theme,
      debugShowCheckedModeBanner: false,
    );
  }
}
