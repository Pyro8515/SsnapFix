enum StepStatus { pending, inReview, complete }

extension StepStatusLabel on StepStatus {
  String get label {
    switch (this) {
      case StepStatus.pending:
        return 'Pending';
      case StepStatus.inReview:
        return 'In review';
      case StepStatus.complete:
        return 'Complete';
    }
  }
}
