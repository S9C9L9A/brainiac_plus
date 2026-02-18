import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/setup_models.dart';

class SetupWizardController extends StateNotifier<SetupWizardState> {
  SetupWizardController() : super(SetupWizardState.initial());

  /// Verifica se il setup iniziale è stato completato
  Future<bool> checkSetupCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('setup_completed') ?? false;
    state = state.copyWith(isSetupCompleted: completed);
    return completed;
  }

  /// Segna il setup come completato
  Future<void> markSetupCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setup_completed', true);
    state = state.copyWith(isSetupCompleted: true);
  }

  /// Resetta il setup (per debug o riconfigurazione)
  Future<void> resetSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setup_completed', false);
    state = SetupWizardState.initial();
  }

  /// Aggiorna lo stato di connessione di un servizio
  void updateServiceStatus(String serviceName, bool isConnected, {Map<String, dynamic>? credentials}) {
    final services = Map<String, ServiceConnectionStatus>.from(state.services);
    services[serviceName] = ServiceConnectionStatus(
      serviceName: serviceName,
      isConnected: isConnected,
      credentials: credentials,
      lastSync: isConnected ? DateTime.now() : null,
    );
    state = state.copyWith(services: services);
  }

  /// Passa allo step successivo
  void nextStep() {
    if (state.currentStep < state.totalSteps - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  /// Torna allo step precedente
  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// Salta il wizard (permetti accesso senza configurazione)
  Future<void> skipWizard() async {
    await markSetupCompleted();
  }

  /// Completa il wizard
  Future<void> completeWizard() async {
    await markSetupCompleted();
  }
}

class SetupWizardState {
  final bool isSetupCompleted;
  final int currentStep;
  final int totalSteps;
  final Map<String, ServiceConnectionStatus> services;

  SetupWizardState({
    required this.isSetupCompleted,
    required this.currentStep,
    required this.totalSteps,
    required this.services,
  });

  factory SetupWizardState.initial() {
    return SetupWizardState(
      isSetupCompleted: false,
      currentStep: 0,
      totalSteps: 4, // Welcome, Facebook, Instagram, Complete
      services: {
        'facebook': ServiceConnectionStatus(serviceName: 'facebook'),
        'instagram': ServiceConnectionStatus(serviceName: 'instagram'),
        'youtube': ServiceConnectionStatus(serviceName: 'youtube'),
        'twitter': ServiceConnectionStatus(serviceName: 'twitter'),
      },
    );
  }

  SetupWizardState copyWith({
    bool? isSetupCompleted,
    int? currentStep,
    int? totalSteps,
    Map<String, ServiceConnectionStatus>? services,
  }) {
    return SetupWizardState(
      isSetupCompleted: isSetupCompleted ?? this.isSetupCompleted,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      services: services ?? this.services,
    );
  }

  /// Ottiene il numero di servizi connessi
  int get connectedServicesCount =>
      services.values.where((s) => s.isConnected).length;

  /// Verifica se almeno un servizio è connesso
  bool get hasAnyServiceConnected => connectedServicesCount > 0;
}

// Provider
final setupWizardControllerProvider =
    StateNotifierProvider<SetupWizardController, SetupWizardState>((ref) {
  return SetupWizardController();
});
