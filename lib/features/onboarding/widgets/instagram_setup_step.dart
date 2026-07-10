import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/setup_wizard_controller.dart';

class InstagramSetupStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const InstagramSetupStep({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  ConsumerState<InstagramSetupStep> createState() => _InstagramSetupStepState();
}

class _InstagramSetupStepState extends ConsumerState<InstagramSetupStep> {
  bool _isChecking = false;
  final _tokenController = TextEditingController();
  bool _showTokenField = false;

  Future<void> _checkInstagramConnection() async {
    if (_tokenController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Inserisci il token di accesso'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isChecking = true;
    });

    try {
      // TODO: Chiamata API per verificare Instagram con il token fornito
      // Per ora, simula il check
      await Future.delayed(const Duration(seconds: 2));

      // Simula verifica (da sostituire con chiamata reale)
      final isConnected =
          _tokenController.text.startsWith('EAA') &&
          _tokenController.text.length > 50;

      if (isConnected) {
        ref
            .read(setupWizardControllerProvider.notifier)
            .updateServiceStatus('instagram', true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('✅ Instagram collegato!'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Token non valido. Controlla il formato.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Errore: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  Future<void> _openGraphAPIExplorer() async {
    final url = Uri.parse('https://developers.facebook.com/tools/explorer/');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openFacebookBusinessManager() async {
    final url = Uri.parse(
      'https://business.facebook.com/latest/settings/pages',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(setupWizardControllerProvider);
    final isConnected = state.services['instagram']?.isConnected ?? false;
    final facebookConnected = state.services['facebook']?.isConnected ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF58529),
                      Color(0xFFDD2A7B),
                      Color(0xFF8134AF),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Collega Instagram',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Gestisci il tuo account Business',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Prerequisite check
          if (!facebookConnected) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    size: 48,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '⚠️ Facebook non collegato',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Per collegare Instagram è necessario prima configurare Facebook',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Torna a Facebook'),
                  ),
                ],
              ),
            ),
          ] else if (!isConnected) ...[
            // Step-by-step guide
            _buildStepCard(
              context,
              '1',
              'Converti Account Instagram',
              'Se hai un account personale, convertilo a Business\n\n• Apri Instagram app\n• Profilo → Menu (☰) → Impostazioni\n• Seleziona "Account professionale"\n• Scegli "Business" o "Creator"',
            ),
            const SizedBox(height: 16),

            _buildStepCard(
              context,
              '2',
              'Collega a una Pagina Facebook',
              'L\'API di Instagram richiede un collegamento con Facebook\n\n• Instagram app → Impostazioni → Account\n• Seleziona "Account collegati"\n• Scegli Facebook e una Pagina\n• Autorizza',
              onTap: _openFacebookBusinessManager,
              buttonText: 'Verifica in Business Manager',
            ),
            const SizedBox(height: 16),

            _buildStepCard(
              context,
              '3',
              'Ottieni il Token di Accesso',
              'Usa Facebook Graph API Explorer\n\n• Visita Graph API Explorer\n• Seleziona la tua App\n• Genera token con permessi Instagram\n• Copia il token (inizia con EAAZ...)',
              onTap: _openGraphAPIExplorer,
              buttonText: 'Apri Graph API Explorer',
            ),
            const SizedBox(height: 24),

            // Token input field
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.vpn_key, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Incolla il Token',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tokenController,
                    obscureText: !_showTokenField,
                    maxLines: 1,
                    decoration: InputDecoration(
                      hintText: 'EAAZ...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showTokenField
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _showTokenField = !_showTokenField;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '💡 Il token inizia con "EAAZ" e può essere molto lungo (200+ caratteri)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '🔒 Clicca l\'occhio per visualizzare il token completo',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Check button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isChecking ? null : _checkInstagramConnection,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFFDD2A7B),
                  foregroundColor: Colors.white,
                ),
                icon: _isChecking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  _isChecking ? 'Verifica in corso...' : 'Verifica Token',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Help section
            _buildHelpSection(context),
          ] else ...[
            // Connected status
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 48),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '✅ Instagram Collegato!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Il tuo account Instagram Business è configurato',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      ref
                          .read(setupWizardControllerProvider.notifier)
                          .updateServiceStatus('instagram', false);
                    },
                    tooltip: 'Modifica',
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Navigation buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back),
                      SizedBox(width: 8),
                      Text('Indietro'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: widget.onNext,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isConnected ? 'Avanti' : 'Salta'),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(
    BuildContext context,
    String step,
    String title,
    String description, {
    VoidCallback? onTap,
    String? buttonText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF58529), Color(0xFFDD2A7B)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    step,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
          if (onTap != null && buttonText != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 52),
              child: TextButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.open_in_new),
                label: Text(buttonText),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHelpSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Text(
                'Serve aiuto?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '📖 Consulta la guida completa: docs/setup/INSTAGRAM_SETUP_GUIDE.md\n\n💡 Errori comuni:\n• Token non valido → Rigenerato da Graph API Explorer\n• Account personale → Converti a Business\n• Non collegato a Facebook → Collega da Impostazioni',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange[900],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
