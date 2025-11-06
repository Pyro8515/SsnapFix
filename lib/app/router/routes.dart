enum AppRoute {
  splash('/'),
  authLogin('/auth/login'),
  authMagicLink('/auth/magic-link'),
  customerOnboarding('/customer/onboarding'),
  customerDashboard('/customer'),
  customerBooking('/customer/booking'),
  customerTrack('/customer/track/:jobId'),
  customerJobs('/customer/jobs'),
  customerHistory('/customer/history'),
  customerRatings('/customer/ratings/:jobId'),
  proOnboarding('/pro/onboarding'),
  proDashboard('/pro'),
  proJobs('/pro/jobs'),
  proJobDetail('/pro/jobs/:jobId'),
  proMap('/pro/map'),
  proMessages('/pro/messages'),
  proAccount('/pro/account'),
  proVerification('/pro/verification'),
  proEarnings('/pro/earnings');

  const AppRoute(this.path);
  final String path;
}
