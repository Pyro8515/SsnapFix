import '../data/models/account_profile.dart';
import '../state/verification_step_state.dart';

extension RoleParser on String {
  AccountRole toAccountRole() {
    switch (toLowerCase()) {
      case 'professional':
        return AccountRole.professional;
      case 'customer':
      default:
        return AccountRole.customer;
    }
  }

  VerificationStatus toVerificationStatus() {
    switch (toLowerCase()) {
      case 'approved':
        return VerificationStatus.approved;
      case 'rejected':
        return VerificationStatus.rejected;
      case 'pending':
      default:
        return VerificationStatus.pending;
    }
  }

  StepStatus toStepStatus() {
    switch (toLowerCase()) {
      case 'approved':
      case 'complete':
        return StepStatus.complete;
      case 'requires_input':
      case 'in_review':
        return StepStatus.inReview;
      case 'pending':
      default:
        return StepStatus.pending;
    }
  }
}
