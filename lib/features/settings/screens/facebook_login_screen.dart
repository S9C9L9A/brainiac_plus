import 'package:flutter/material.dart';
import '../controllers/auth_service.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_provider.dart';

/// Screen di accesso con Facebook
class FacebookLoginScreen extends StatefulWidget {
  const FacebookLoginScreen({Key? key}) : super(key: key);

  @override
  State<FacebookLoginScreen> createState() => _FacebookLoginScreenState();
}

class _FacebookLoginScreenState extends State<FacebookLoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _handleFacebookLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // TODO: Integra con il vero Facebook SDK (flutter_facebook_sdk)
      // Per ora usiamo token di test
      
      // Esempio con token di test
      const String testAccessToken = 'TEST_TOKEN_DEMO';
      const String testUserID = '123456789';

      final result = await AuthService.loginWithFacebook(
        accessToken: testAccessToken,
        userID: testUserID,
      );

      if (result['success'] == true) {
        setState(() {
          _successMessage = 'Accesso riuscito: ${result['user']['name']}';
        });

        // Naviga alla home dopo 2 secondi
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Errore sconosciuto';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login - BraniacPlus'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Icon(
                Icons.psychology,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 32),

              // Titolo
              Text(
                'BraniacPlus',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Sottotitolo
              Text(
                'Accedi con Facebook per gestire le tue pagine',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),

              // Messaggio di errore
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),

              // Messaggio di successo
              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: TextStyle(color: Colors.green[700]),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_errorMessage != null || _successMessage != null)
                const SizedBox(height: 24),

              // Pulsante Facebook Login
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleFacebookLogin,
                icon: const Icon(Icons.facebook),
                label: Text(
                  _isLoading ? 'Accesso in corso...' : 'Accedi con Facebook',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1877F2), // Colore Facebook
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              // Logout Button (se autenticato)
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  if (authProvider.isAuthenticated) {
                    return Column(
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          'Connesso come: ${authProvider.currentUser?['name']}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            authProvider.logout();
                            setState(() {
                              _isLoading = false;
                              _errorMessage = null;
                              _successMessage = null;
                            });
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              if (_isLoading) ...[
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Verifica in corso con il backend...'),
              ],

              const SizedBox(height: 48),

              // Info backend
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔧 Info Backend',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Backend: http://localhost:8080',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'Endpoint: /api/facebook/auth',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '⚠️ Nota: Questo utilizza token di test. Integra il vero Facebook SDK per token reali.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
