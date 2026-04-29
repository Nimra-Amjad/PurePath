enum OnboardingStatus {
  inProgress,
  completed;

  // Convert to string for Firestore
  String toValue() {
    switch (this) {
      case OnboardingStatus.inProgress:
        return 'in_progress';
      case OnboardingStatus.completed:
        return 'completed';
    }
  }

  // Parse from Firestore string
  static OnboardingStatus fromValue(String value) {
    switch (value) {
      case 'in_progress':
        return OnboardingStatus.inProgress;
      case 'completed':
        return OnboardingStatus.completed;
      default:
        return OnboardingStatus.inProgress;
    }
  }
}
