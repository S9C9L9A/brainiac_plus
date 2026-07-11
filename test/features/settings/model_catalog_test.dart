import 'package:brainiac_plus/core/services/model_suggestions_service.dart';
import 'package:brainiac_plus/core/services/ollama_service.dart';
import 'package:brainiac_plus/features/settings/services/model_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

OllamaModelInfo catalogEntry(String name) => OllamaModelInfo(
  name: name,
  displayName: name,
  description: 'catalog',
  sizeGB: 4,
  vramRequiredMB: 4000,
  tags: const ['chat'],
  rating: ModelRecommendationRating.good,
  reason: 'fits',
);

OllamaModel serverModel(String name, {int bytes = 14325115392}) => OllamaModel(
  name: name,
  sizeBytes: bytes,
  modifiedAt: DateTime(2026, 7, 10),
);

void main() {
  group('ModelCatalog.mergeWithInstalled', () {
    test('models reported by the server but absent from the catalog are '
        'prepended as installed entries', () {
      final merged = ModelCatalog.mergeWithInstalled(
        [catalogEntry('mistral:7b')],
        [serverModel('bartowski/Mistral-Small-24B-Instruct-2501-GGUF:Q4_K_M')],
      );

      expect(
        merged.first.name,
        'bartowski/Mistral-Small-24B-Instruct-2501-GGUF:Q4_K_M',
      );
      expect(merged.first.tags, contains('installed'));
      expect(merged.first.sizeGB, closeTo(13.34, 0.01));
      expect(merged.map((m) => m.name), contains('mistral:7b'));
    });

    test('server models already in the catalog are not duplicated', () {
      final merged = ModelCatalog.mergeWithInstalled(
        [catalogEntry('mistral:7b')],
        [serverModel('mistral:7b')],
      );

      expect(merged.where((m) => m.name == 'mistral:7b'), hasLength(1));
    });

    test('empty server list leaves the catalog untouched', () {
      final catalog = [catalogEntry('a'), catalogEntry('b')];
      final merged = ModelCatalog.mergeWithInstalled(catalog, const []);

      expect(merged.map((m) => m.name), ['a', 'b']);
    });

    test('installedNames exposes the set of server-reported names', () {
      final names = ModelCatalog.installedNames([
        serverModel('x'),
        serverModel('y'),
      ]);
      expect(names, {'x', 'y'});
    });
  });
}
