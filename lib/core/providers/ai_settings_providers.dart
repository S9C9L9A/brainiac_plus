import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/hardware_detection_service.dart';
import '../services/model_suggestions_service.dart';
import '../services/system_metrics_service.dart' show SystemMetricsService, RealtimeSystemMetrics;
import '../services/ollama_service.dart' show OllamaService, OllamaModel, OllamaException;

/// Hardware detection service provider
final hardwareDetectionProvider = Provider<HardwareDetectionService>((ref) {
  return HardwareDetectionService();
});

/// Hardware info provider
final hardwareInfoProvider = FutureProvider<HardwareInfo>((ref) async {
  final service = ref.watch(hardwareDetectionProvider);
  return service.getHardwareInfo();
});

/// Hardware summary provider
final hardwareSummaryProvider = FutureProvider<String>((ref) async {
  final service = ModelSuggestionsService();
  return service.getHardwareSummary();
});

/// Model suggestions service provider
final modelSuggestionsProvider = Provider<ModelSuggestionsService>((ref) {
  return ModelSuggestionsService();
});

/// All available models from Ollama (cached with invalidation)
final ollamaAvailableModelsProvider =
    FutureProvider.family<List<OllamaModel>, String>((ref, baseUrl) async {
  final service = OllamaService(baseUrl: baseUrl);
  try {
    return await service.listModelsDetailed();
  } catch (e) {
    return []; // Return empty list if Ollama not available
  }
});

/// Recommended models based on hardware
final recommendedModelsProvider = FutureProvider<List<OllamaModelInfo>>((ref) async {
  final service = ref.watch(modelSuggestionsProvider);
  return service.getRecommendedModels(limit: 5);
});

/// All models rated for current hardware
final allRatedModelsProvider =
    FutureProvider<List<OllamaModelInfo>>((ref) async {
  final service = ref.watch(modelSuggestionsProvider);
  return service.getAllModelsRated();
});

/// Model info provider by name
final modelInfoProvider = Provider.family<OllamaModelInfo?, String>((ref, modelName) {
  final service = ModelSuggestionsService();
  final allModels = service.getAllModels();
  try {
    return allModels.firstWhere(
      (m) => m.name == modelName || m.displayName == modelName,
    );
  } catch (e) {
    return null;
  }
});

/// Download model status provider
final modelDownloadStatusProvider =
    StateNotifierProvider<ModelDownloadNotifier, ModelDownloadState>((ref) {
  return ModelDownloadNotifier();
});

/// Download state
class ModelDownloadState {
  final bool isDownloading;
  final String? modelName;
  final int progressPercent;
  final String? message;
  final String? error;

  ModelDownloadState({
    this.isDownloading = false,
    this.modelName,
    this.progressPercent = 0,
    this.message,
    this.error,
  });

  ModelDownloadState copyWith({
    bool? isDownloading,
    String? modelName,
    int? progressPercent,
    String? message,
    String? error,
  }) {
    return ModelDownloadState(
      isDownloading: isDownloading ?? this.isDownloading,
      modelName: modelName ?? this.modelName,
      progressPercent: progressPercent ?? this.progressPercent,
      message: message ?? this.message,
      error: error,
    );
  }
}

/// Download notifier
class ModelDownloadNotifier extends StateNotifier<ModelDownloadState> {
  ModelDownloadNotifier() : super(ModelDownloadState());

  void setDownloading(String modelName) {
    state = state.copyWith(
      isDownloading: true,
      modelName: modelName,
      progressPercent: 0,
      message: 'Downloading $modelName...',
      error: null,
    );
  }

  void setProgress(int percent, {String? message}) {
    state = state.copyWith(
      progressPercent: percent,
      message: message ?? state.message,
    );
  }

  void setComplete(String modelName) {
    state = state.copyWith(
      isDownloading: false,
      progressPercent: 100,
      message: '$modelName downloaded successfully',
    );
  }

  void setError(String error) {
    state = state.copyWith(
      isDownloading: false,
      error: error,
      message: 'Download failed: $error',
    );
  }

  void reset() {
    state = ModelDownloadState();
  }
}
