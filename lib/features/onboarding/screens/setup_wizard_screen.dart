import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/setup_wizard_controller.dart';
import '../widgets/welcome_step.dart';
import '../widgets/facebook_setup_step.dart';
import '../widgets/instagram_setup_step.dart';
import '../widgets/completion_step.dart';

class SetupWizardScreen extends ConsumerStatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  ConsumerState<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends ConsumerState<SetupWizardScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_pageController.page! < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      ref.read(setupWizardControllerProvider.notifier).nextStep();
    }
  }

  void _previousPage() {
    if (_pageController.page! > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      ref.read(setupWizardControllerProvider.notifier).previousStep();
    }
  }

  void _skipWizard() {
    ref.read(setupWizardControllerProvider.notifier).skipWizard();
    Navigator.of(context).pushReplacementNamed('/');
  }

  void _completeWizard() {
    ref.read(setupWizardControllerProvider.notifier).completeWizard();
    Navigator.of(context).pushReplacementNamed('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(setupWizardControllerProvider);
    final currentStep = state.currentStep;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header con progress indicator
              _buildHeader(context, currentStep, state.totalSteps),

              // Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    WelcomeStep(onNext: _nextPage, onSkip: _skipWizard),
                    FacebookSetupStep(onNext: _nextPage, onBack: _previousPage),
                    InstagramSetupStep(onNext: _nextPage, onBack: _previousPage),
                    CompletionStep(onComplete: _completeWizard, onBack: _previousPage),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int currentStep, int totalSteps) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Logo/Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.rocket_launch,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'BrainiacPlus Setup',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Progress indicator
          Row(
            children: List.generate(
              totalSteps,
              (index) => Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    right: index < totalSteps - 1 ? 8 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: index <= currentStep
                        ? Theme.of(context).primaryColor
                        : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Step counter
          Text(
            'Step ${currentStep + 1} di $totalSteps',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
