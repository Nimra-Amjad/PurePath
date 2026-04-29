enum OnboardingStatus {
  inProgress,
  completed;

  String toValue() {
    switch (this) {
      case OnboardingStatus.inProgress:
        return 'in_progress';
      case OnboardingStatus.completed:
        return 'completed';
    }
  }

  static OnboardingStatus fromValue(String value) {
    switch (value) {
      case 'completed':
        return OnboardingStatus.completed;
      default:
        return OnboardingStatus.inProgress;
    }
  }
}
