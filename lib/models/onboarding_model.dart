class OnboardingPage {
  final String title;
  final String description;
  final bool isLast;

  const OnboardingPage({
    required this.title,
    required this.description,
    this.isLast = false,
  });
}

final List<OnboardingPage> onboardingPages = [
  const OnboardingPage(
    title: 'Make sense of your wastewater\ndata instantly',
    description:
        'Transform complex sensor readings into clear insights, risk levels, and recommended actions you can act on immediately.',
  ),
  const OnboardingPage(
    title: 'Detect wastewater risks before\nthey become violations',
    description:
        'Analyse sensor readings in real time and receive early warnings to prevent harmful discharge and compliance issues.',
  ),
  const OnboardingPage(
    title: 'Compliance & Decision-Making\nFocus',
    description:
        'Monitor key parameters, understand compliance status, and get AI-driven guidance to support confident operational decisions.',
    isLast: true,
  ),
];