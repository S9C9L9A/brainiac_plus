import '../../../core/services/model_suggestions_service.dart';
import '../../../core/services/ollama_service.dart';

/// Reconciles the static model catalog with what the local AI server
/// actually reports as installed.
///
/// The settings dropdown used to list only the hardcoded catalog, so a
/// model pulled outside of it (e.g. a GGUF served by llama.cpp) showed up
/// as "(not installed)" even while the server was running it — making the
/// selector claim the opposite of the green "installed" panel above it.
class ModelCatalog {
  ModelCatalog._();

  static const _bytesPerGB = 1024 * 1024 * 1024;

  /// Catalog plus one first-class entry for every server-reported model the
  /// catalog does not know, prepended so installed models rank first.
  static List<OllamaModelInfo> mergeWithInstalled(
    List<OllamaModelInfo> catalog,
    List<OllamaModel> installed,
  ) {
    final known = catalog.map((m) => m.name).toSet();
    final extras = [
      for (final model in installed)
        if (!known.contains(model.name))
          OllamaModelInfo(
            name: model.name,
            displayName: model.name,
            description: 'Detected on the local AI server',
            sizeGB: model.sizeBytes / _bytesPerGB,
            vramRequiredMB: 0,
            tags: const ['installed'],
            rating: ModelRecommendationRating.optimal,
            reason: 'Installed and ready to use',
          ),
    ];
    return [...extras, ...catalog];
  }

  /// Names the server reports as installed, for badging.
  static Set<String> installedNames(List<OllamaModel> installed) {
    return installed.map((m) => m.name).toSet();
  }
}
