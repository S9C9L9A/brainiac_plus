import 'hardware_detection_service.dart';

/// Model recommendation rating
enum ModelRecommendationRating {
  optimal, // Perfectly fits hardware
  good, // Works well
  acceptable, // Will work but slower
  minimal, // Barely fits
  unsuitable, // Not recommended
}

/// Available Ollama models with metadata
class OllamaModelInfo {
  final String name;
  final String displayName;
  final String description;
  final double sizeGB;
  final int vramRequiredMB;
  final List<String> tags;
  final ModelRecommendationRating rating;
  final String reason;
  final bool isQuantized;
  final String quantization; // q4, q5, fp16, etc.

  OllamaModelInfo({
    required this.name,
    required this.displayName,
    required this.description,
    required this.sizeGB,
    required this.vramRequiredMB,
    required this.tags,
    required this.rating,
    required this.reason,
    this.isQuantized = false,
    this.quantization = '',
  });

  /// Get visual indicator for rating
  String get ratingIcon {
    switch (rating) {
      case ModelRecommendationRating.optimal:
        return '⭐ Optimal';
      case ModelRecommendationRating.good:
        return '✅ Good';
      case ModelRecommendationRating.acceptable:
        return '⚠️ Acceptable';
      case ModelRecommendationRating.minimal:
        return '⚡ Minimal';
      case ModelRecommendationRating.unsuitable:
        return '❌ Unsuitable';
    }
  }

  /// Get color representation
  String get ratingColor {
    switch (rating) {
      case ModelRecommendationRating.optimal:
        return '#10B981'; // Green
      case ModelRecommendationRating.good:
        return '#3B82F6'; // Blue
      case ModelRecommendationRating.acceptable:
        return '#F59E0B'; // Amber
      case ModelRecommendationRating.minimal:
        return '#EF4444'; // Red
      case ModelRecommendationRating.unsuitable:
        return '#6B7280'; // Gray
    }
  }

  @override
  String toString() => '$displayName ($name) - $vramRequiredMB MB - $sizeGB GB';
}

/// Service for suggesting optimal models based on hardware
class ModelSuggestionsService {
  static final _instance = ModelSuggestionsService._();
  final HardwareDetectionService _hardwareService = HardwareDetectionService();

  factory ModelSuggestionsService() {
    return _instance;
  }

  ModelSuggestionsService._();

  /// Known Ollama models with metadata
  static final _modelDatabase = <OllamaModelInfo>[
    // Ultra-lightweight (under 1GB, <1GB RAM)
    OllamaModelInfo(
      name: 'tinyllama:latest',
      displayName: 'TinyLLaMA',
      description: 'Lightweight model, great for low-end devices',
      sizeGB: 0.4,
      vramRequiredMB: 512,
      tags: ['tiny', 'lightweight', 'fast'],
      rating: ModelRecommendationRating.optimal,
      reason: 'Optimal for devices with limited resources',
      isQuantized: true,
      quantization: 'q4',
    ),
    // Small models (1-3GB)
    OllamaModelInfo(
      name: 'mistral:latest',
      displayName: 'Mistral 7B',
      description: 'Balanced performance and quality',
      sizeGB: 2.7,
      vramRequiredMB: 2048,
      tags: ['small', 'balanced', 'popular'],
      rating: ModelRecommendationRating.good,
      reason: 'Good balance between speed and quality',
      isQuantized: true,
      quantization: 'q4',
    ),
    OllamaModelInfo(
      name: 'neural-chat:latest',
      displayName: 'Neural Chat',
      description: 'Optimized for conversation',
      sizeGB: 2.4,
      vramRequiredMB: 2048,
      tags: ['chat', 'conversation', 'small'],
      rating: ModelRecommendationRating.good,
      reason: 'Excellent for chat use cases',
      isQuantized: true,
      quantization: 'q4',
    ),
    OllamaModelInfo(
      name: 'orca-mini:latest',
      displayName: 'Orca Mini',
      description: 'Instruction-tuned mini model',
      sizeGB: 1.7,
      vramRequiredMB: 1536,
      tags: ['small', 'instruction', 'lightweight'],
      rating: ModelRecommendationRating.good,
      reason: 'Lightweight instruction model',
      isQuantized: true,
      quantization: 'q4',
    ),
    // Medium models (3-8GB)
    OllamaModelInfo(
      name: 'llama3.1:8b',
      displayName: 'Llama 3.1 8B',
      description: 'Latest Llama model, good quality',
      sizeGB: 4.7,
      vramRequiredMB: 3072,
      tags: ['medium', 'llama', 'popular'],
      rating: ModelRecommendationRating.good,
      reason: 'Solid general-purpose model',
      isQuantized: true,
      quantization: 'q4',
    ),
    OllamaModelInfo(
      name: 'llama2:latest',
      displayName: 'Llama 2 7B',
      description: 'Previous Llama generation',
      sizeGB: 3.9,
      vramRequiredMB: 2560,
      tags: ['medium', 'llama', 'stable'],
      rating: ModelRecommendationRating.good,
      reason: 'Stable and reliable',
      isQuantized: true,
      quantization: 'q4',
    ),
    OllamaModelInfo(
      name: 'zephyr:latest',
      displayName: 'Zephyr 7B',
      description: 'Instruction-tuned Mistral model',
      sizeGB: 3.7,
      vramRequiredMB: 2560,
      tags: ['medium', 'instruction', 'chat'],
      rating: ModelRecommendationRating.good,
      reason: 'Strong instruction-following abilities',
      isQuantized: true,
      quantization: 'q4',
    ),
    // Larger models (8-15GB)
    OllamaModelInfo(
      name: 'llama3.1:70b',
      displayName: 'Llama 3.1 70B',
      description: 'Powerful large model',
      sizeGB: 41.0,
      vramRequiredMB: 24576,
      tags: ['large', 'powerful', 'llama'],
      rating: ModelRecommendationRating.acceptable,
      reason: 'Requires 24GB+ RAM, best on high-end systems',
      isQuantized: true,
      quantization: 'q4',
    ),
    OllamaModelInfo(
      name: 'mistral:large',
      displayName: 'Mistral Large',
      description: 'Larger Mistral variant',
      sizeGB: 26.0,
      vramRequiredMB: 16384,
      tags: ['large', 'powerful', 'mistral'],
      rating: ModelRecommendationRating.acceptable,
      reason: 'Best on systems with 16GB+ RAM',
      isQuantized: true,
      quantization: 'q4',
    ),
    // Very large (15GB+)
    OllamaModelInfo(
      name: 'llama3.1:405b',
      displayName: 'Llama 3.1 405B',
      description: 'Ultra-powerful model',
      sizeGB: 236.0,
      vramRequiredMB: 65536,
      tags: ['xlarge', 'research', 'powerful'],
      rating: ModelRecommendationRating.minimal,
      reason: 'Enterprise-grade, requires 64GB+ RAM',
      isQuantized: true,
      quantization: 'q2',
    ),
    // Specialized models
    OllamaModelInfo(
      name: 'codegemma:latest',
      displayName: 'CodeGemma',
      description: 'Specialized for code generation',
      sizeGB: 4.8,
      vramRequiredMB: 3072,
      tags: ['code', 'specialized', 'programming'],
      rating: ModelRecommendationRating.good,
      reason: 'Optimized for code tasks',
      isQuantized: true,
      quantization: 'q4',
    ),
    OllamaModelInfo(
      name: 'deepseek-coder:latest',
      displayName: 'DeepSeek Coder',
      description: 'Advanced code model',
      sizeGB: 3.9,
      vramRequiredMB: 2560,
      tags: ['code', 'specialized', 'advanced'],
      rating: ModelRecommendationRating.good,
      reason: 'Excellent for code generation and analysis',
      isQuantized: true,
      quantization: 'q4',
    ),
    // Recently installed high-performance models
    OllamaModelInfo(
      name: 'qwen2.5-coder:14b',
      displayName: 'Qwen 2.5 Coder 14B',
      description: 'High-performance coding model from Alibaba',
      sizeGB: 9.0,
      vramRequiredMB: 10240,
      tags: ['code', 'specialized', 'large', 'installed'],
      rating: ModelRecommendationRating.optimal,
      reason: 'Best coding model available locally – highly recommended',
      isQuantized: false,
      quantization: 'fp16',
    ),
    OllamaModelInfo(
      name: 'codellama:13b',
      displayName: 'Code Llama 13B',
      description: 'Meta Code Llama 13B for code generation',
      sizeGB: 7.4,
      vramRequiredMB: 8192,
      tags: ['code', 'specialized', 'large', 'installed'],
      rating: ModelRecommendationRating.good,
      reason: 'Solid code generation, larger context than 7B',
      isQuantized: false,
      quantization: 'fp16',
    ),
  ];

  /// Get all available models
  List<OllamaModelInfo> getAllModels() {
    return List.from(_modelDatabase);
  }

  /// Get recommended models for current hardware
  Future<List<OllamaModelInfo>> getRecommendedModels({
    int limit = 5,
  }) async {
    final hardware = await _hardwareService.getHardwareInfo();
    final available = _rateModels(hardware);
    available.sort((a, b) {
      // Sort by rating priority
      final ratingOrder = {
        ModelRecommendationRating.optimal: 0,
        ModelRecommendationRating.good: 1,
        ModelRecommendationRating.acceptable: 2,
        ModelRecommendationRating.minimal: 3,
        ModelRecommendationRating.unsuitable: 4,
      };
      return (ratingOrder[a.rating] ?? 99)
          .compareTo(ratingOrder[b.rating] ?? 99);
    });
    return available.take(limit).toList();
  }

  /// Get all models rated for current hardware
  Future<List<OllamaModelInfo>> getAllModelsRated() async {
    final hardware = await _hardwareService.getHardwareInfo();
    final rated = _rateModels(hardware);
    rated.sort((a, b) {
      final ratingOrder = {
        ModelRecommendationRating.optimal: 0,
        ModelRecommendationRating.good: 1,
        ModelRecommendationRating.acceptable: 2,
        ModelRecommendationRating.minimal: 3,
        ModelRecommendationRating.unsuitable: 4,
      };
      return (ratingOrder[a.rating] ?? 99)
          .compareTo(ratingOrder[b.rating] ?? 99);
    });
    return rated;
  }

  /// Rate models based on hardware
  List<OllamaModelInfo> _rateModels(HardwareInfo hardware) {
    return _modelDatabase.map((model) {
      final availableMem = hardware.availableForModel;
      final requiredMem = model.vramRequiredMB;

      ModelRecommendationRating rating;
      String reason;

      if (requiredMem > availableMem * 2) {
        rating = ModelRecommendationRating.unsuitable;
        reason =
            'Requires ${requiredMem ~/ 1024}GB but you have ${availableMem ~/ 1024}GB available';
      } else if (requiredMem > availableMem * 1.5) {
        rating = ModelRecommendationRating.minimal;
        reason = 'Barely fits with ${availableMem ~/ 1024}GB available memory';
      } else if (requiredMem > availableMem) {
        rating = ModelRecommendationRating.acceptable;
        reason = 'Fits but may require swap/slowdown';
      } else if (requiredMem < availableMem * 0.5) {
        rating = ModelRecommendationRating.optimal;
        reason = 'Perfect fit for your ${availableMem ~/ 1024}GB available';
      } else {
        rating = ModelRecommendationRating.good;
        reason = 'Good fit for your system';
      }

      return OllamaModelInfo(
        name: model.name,
        displayName: model.displayName,
        description: model.description,
        sizeGB: model.sizeGB,
        vramRequiredMB: model.vramRequiredMB,
        tags: model.tags,
        rating: rating,
        reason: reason,
        isQuantized: model.isQuantized,
        quantization: model.quantization,
      );
    }).toList();
  }

  /// Get hardware summary for display
  Future<String> getHardwareSummary() async {
    final hw = await _hardwareService.getHardwareInfo();
    return '${hw.totalMemoryMB ~/ 1024}GB RAM • ${hw.cpuCores} CPU cores • ${hw.osName} ${hw.osVersion}';
  }
}
