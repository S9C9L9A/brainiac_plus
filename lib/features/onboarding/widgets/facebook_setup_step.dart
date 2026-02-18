import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/setup_wizard_controller.dart';

class FacebookSetupStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const FacebookSetupStep({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  ConsumerState<FacebookSetupStep> createState() => _FacebookSetupStepState();
}

class _FacebookSetupStepState extends ConsumerState<FacebookSetupStep> {
  final _tokenController = TextEditingController();
  bool _isValidating = false;
  String? _errorMessage;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _validateToken() async {
    if (_tokenController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Inserisci un token valido';
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      // TODO: Chiamata API per validare il token
      await Future.delayed(const Duration(seconds: 1));

      // Simula validazione (sostituire con chiamata reale al backend)
      final isValid = _tokenController.text.trim().length > 50;

      if (isValid) {
        ref.read(setupWizardControllerProvider.notifier).updateServiceStatus(
              'facebook',
              true,
              credentials: {'token': _tokenController.text.trim()},
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('✅ Facebook collegato con successo!'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Token non valido. Controlla e riprova.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore durante la validazione: $e';
      });
    } finally {
      setState(() {
        _isValidating = false;
      });
    }
  }

  Future<void> _openFacebookDevelopers() async {
    final url = Uri.parse('https://developers.facebook.com/tools/explorer/');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(setupWizardControllerProvider);
    final isConnected = state.services['facebook']?.isConnected ?? false;

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
                  color: const Color(0xFF1877F2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.facebook,
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
                      'Collega Facebook',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Gestisci la tua pagina e le automazioni',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Instructions
          if (!isConnected) ...[
            _buildInstructionCard(
              context,
              '1',
              'Vai su Facebook Developers',
              'Apri il Graph API Explorer per generare il tuo token',
              onTap: _openFacebookDevelopers,
              buttonText: 'Apri Facebook Developers',
            ),
            const SizedBox(height: 16),
            _buildInstructionCard(
              context,
              '2',
              'Genera il Token',
              'Seleziona i permessi: pages_show_list, pages_read_engagement',
            ),
            const SizedBox(height: 16),
            _buildInstructionCard(
              context,
              '3',
              'Incolla il Token',
              'Copia il token generato e incollalo qui sotto',
            ),
            const SizedBox(height: 24),

            // Token input
            TextField(
              controller: _tokenController,
              decoration: InputDecoration(
                labelText: 'Facebook Access Token',
                hintText: 'EAAd3zUKn7ToBQ...',
                prefixIcon: const Icon(Icons.vpn_key),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste),
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null) {
                      _tokenController.text = data!.text!;
                    }
                  },
                  tooltip: 'Incolla',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                errorText: _errorMessage,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Validate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isValidating ? null : _validateToken,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF1877F2),
                  foregroundColor: Colors.white,
                ),
                child: _isValidating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Verifica Token',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ] else ...[
            // Connected status
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
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
                          '✅ Facebook Collegato!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Il tuo account Facebook è configurato correttamente',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      ref.read(setupWizardControllerProvider.notifier).updateServiceStatus(
                            'facebook',
                            false,
                          );
                    },
                    tooltip: 'Modifica',
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Help section
          _buildHelpSection(context),

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

  Widget _buildInstructionCard(
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
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    step,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          if (onTap != null && buttonText != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: TextButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.open_in_new),
                label: Text(buttonText),
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
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
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
            'Consulta la guida completa in: docs/setup/FACEBOOK_TOKEN_GUIDE.md',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange[900],
            ),
          ),
        ],
      ),
    );
  }
}
