enum AppRoute {
  splash('/'),
  authLogin('/auth/login'),
  authMagicLink('/auth/magic-link'),
  customerDashboard('/customer'),
  customerBooking('/customer/booking'),
  customerTrack('/customer/track/:jobId'),
  proDashboard('/pro'),
  proJobs('/pro/jobs'),
  proMap('/pro/map'),
  proMessages('/pro/messages'),
  proAccount('/pro/account'),
  proVerification('/pro/verification');

  const AppRoute(this.path);
  final String path;
}
