import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/setup_wizard_controller.dart';

class CompletionStep extends ConsumerWidget {
  final VoidCallback onComplete;
  final VoidCallback onBack;

  const CompletionStep({
    super.key,
    required this.onComplete,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(setupWizardControllerProvider);
    final connectedCount = state.connectedServicesCount;
    final hasAnyService = state.hasAnyServiceConnected;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.green, Colors.lightGreen],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 48),

          // Title
          Text(
            hasAnyService ? '🎉 Setup Completato!' : '✅ Tutto Pronto!',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Subtitle
          Text(
            hasAnyService
                ? 'Hai collegato $connectedCount ${connectedCount == 1 ? 'servizio' : 'servizi'}'
                : 'Puoi collegare i servizi in qualsiasi momento',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // Services summary
          _buildServicesSummary(context, state),

          const SizedBox(height: 48),

          // Next steps
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Prossimi Passi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildNextStep('Esplora la Dashboard', 'Visualizza metriche e analytics'),
                const SizedBox(height: 8),
                _buildNextStep('Crea Automazioni', 'Programma post sui tuoi social'),
                const SizedBox(height: 8),
                _buildNextStep('Collega Altri Servizi', 'YouTube, Twitter e altro'),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Info message
          if (!hasAnyService)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Puoi collegare i servizi dalle Impostazioni in qualsiasi momento',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 32),

          // Complete button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onComplete,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Inizia ad Usare BrainiacPlus',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.rocket_launch, size: 28),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Back button
          TextButton(
            onPressed: onBack,
            child: const Text('← Modifica Configurazione'),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSummary(BuildContext context, SetupWizardState state) {
    final services = [
      {'name': 'Facebook', 'icon': Icons.facebook, 'color': const Color(0xFF1877F2), 'key': 'facebook'},
      {'name': 'Instagram', 'icon': Icons.camera_alt, 'color': const Color(0xFFDD2A7B), 'key': 'instagram'},
      {'name': 'YouTube', 'icon': Icons.play_circle, 'color': const Color(0xFFFF0000), 'key': 'youtube'},
      {'name': 'Twitter', 'icon': Icons.tag, 'color': const Color(0xFF1DA1F2), 'key': 'twitter'},
    ];

    return Column(
      children: services.map((service) {
        final isConnected = state.services[service['key']]?.isConnected ?? false;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (service['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  service['icon'] as IconData,
                  color: service['color'] as Color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  service['name'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                isConnected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isConnected ? Colors.green : Colors.grey,
                size: 28,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNextStep(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.arrow_forward, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
