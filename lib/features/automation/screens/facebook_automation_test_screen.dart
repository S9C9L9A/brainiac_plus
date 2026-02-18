import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Schermata di test per le automazioni Facebook
/// Permette di testare l'integrazione Facebook senza dover configurare tutto
class FacebookAutomationTestScreen extends StatefulWidget {
  const FacebookAutomationTestScreen({super.key});

  @override
  State<FacebookAutomationTestScreen> createState() => _FacebookAutomationTestScreenState();
}

class _FacebookAutomationTestScreenState extends State<FacebookAutomationTestScreen> {
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  String _backendUrl = 'http://localhost:8080';
  bool _isLoading = false;
  String _status = 'Pronto per iniziare';
  Map<String, dynamic>? _userData;
  List<dynamic>? _pages;
  String? _selectedPageId;
  String? _selectedPageToken;

  @override
  void initState() {
    super.initState();
    // Pre-compila con il token fornito se disponibile
    _tokenController.text = 'EAAd3zUKn7ToBQla4F65ayrZBcm2ZBzW2SUOlXlCWSz3MXfAIwVd1oaKUu0MmxwMKvj1BWLMbIgyEzKJJVPqVZB1NkGMMXa4Hny4Fcd6YEeQfCUQ6RGjpdfCLHJ1IKRBoZC7LEpmeZCSOdVA5T0PaBaeduGqIlkKYMJKzZAcK2gLkB7gheZBle3QIj3TAPY2XZBLKVtMqIEXD8MH9yY7hPJOCN80GKZBNIZA8j5ifFoNJaywZCJFVL5AFUwVhOzWRz9dGZAIih3ZBPrJ9eyZBso2W70vSluUkAvEVQF';
    _messageController.text = '🧠 Test BrainiacPlus - ${DateTime.now()}';
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _testBackendConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testando connessione backend...';
    });

    try {
      final response = await http.get(Uri.parse('$_backendUrl/health'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _status = '✅ Backend connesso - Versione: ${data['version']}';
        });
      } else {
        setState(() {
          _status = '❌ Backend non risponde (Status: ${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Errore connessione: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _validateToken() async {
    if (_tokenController.text.isEmpty) {
      _showSnackBar('Inserisci un token Facebook valido');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Validando token Facebook...';
    });

    try {
      // Test diretto con Facebook API
      final fbResponse = await http.get(
        Uri.parse('https://graph.facebook.com/v18.0/me?fields=id,name,email&access_token=${_tokenController.text}')
      );
      
      if (fbResponse.statusCode == 200) {
        final userData = json.decode(fbResponse.body);
        
        if (userData.containsKey('error')) {
          setState(() {
            _status = '❌ Token non valido: ${userData['error']['message']}';
            _userData = null;
          });
          _showSnackBar('Token non valido! Genera un nuovo token.');
        } else {
          setState(() {
            _userData = userData;
            _status = '✅ Token valido! Utente: ${userData['name']}';
          });
          
          // Autentica anche con il backend
          await _authenticateWithBackend();
        }
      } else {
        setState(() {
          _status = '❌ Errore validazione token';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Errore: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _authenticateWithBackend() async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/facebook/auth'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'access_token': _tokenController.text}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['valid'] == true) {
          _showSnackBar('✅ Autenticazione backend riuscita!');
        } else {
          _showSnackBar('⚠️ Backend: ${data['message']}');
        }
      }
    } catch (e) {
      _showSnackBar('⚠️ Backend non raggiungibile');
    }
  }

  Future<void> _fetchPages() async {
    if (_tokenController.text.isEmpty) {
      _showSnackBar('Prima valida il token');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Recuperando pagine Facebook...';
    });

    try {
      final response = await http.get(
        Uri.parse('https://graph.facebook.com/v18.0/me/accounts?access_token=${_tokenController.text}')
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['data'] != null && (data['data'] as List).isNotEmpty) {
          setState(() {
            _pages = data['data'];
            _status = '✅ Trovate ${_pages!.length} pagina/e';
          });
        } else {
          setState(() {
            _pages = null;
            _status = '⚠️ Nessuna pagina trovata. Devi essere admin/editor di almeno una pagina.';
          });
          _showSnackBar('Nessuna pagina trovata');
        }
      }
    } catch (e) {
      setState(() {
        _status = '❌ Errore recupero pagine: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _publishPost() async {
    if (_selectedPageId == null || _selectedPageToken == null) {
      _showSnackBar('Seleziona prima una pagina');
      return;
    }

    if (_messageController.text.isEmpty) {
      _showSnackBar('Scrivi un messaggio');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Pubblicando post...';
    });

    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/facebook/post'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'page_id': _selectedPageId,
          'page_token': _selectedPageToken,
          'message': _messageController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _status = '✅ Post pubblicato! ID: ${data['post_id']}';
        });
        _showSnackBar('✅ Post pubblicato con successo!');
      } else {
        final data = json.decode(response.body);
        setState(() {
          _status = '❌ Errore pubblicazione: ${data['error']}';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Errore: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 Test Automazioni Facebook'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: Colors.deepPurple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    if (_isLoading) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // Backend Configuration
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚙️ Configurazione Backend',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Backend URL',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(text: _backendUrl),
                      onChanged: (value) => _backendUrl = value,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _testBackendConnection,
                      icon: const Icon(Icons.wifi),
                      label: const Text('Test Connessione'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Token Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '🔑 Token Facebook',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.help_outline),
                          onPressed: () {
                            _showTokenHelp();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _tokenController,
                      decoration: const InputDecoration(
                        labelText: 'Access Token',
                        border: OutlineInputBorder(),
                        hintText: 'Incolla il token da Facebook Developer',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _validateToken,
                      icon: const Icon(Icons.verified_user),
                      label: const Text('Valida Token'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_userData != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '👤 Utente Connesso',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text('Nome: ${_userData!['name']}'),
                      Text('ID: ${_userData!['id']}'),
                      if (_userData!['email'] != null)
                        Text('Email: ${_userData!['email']}'),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Pages Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📄 Pagine Facebook',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _fetchPages,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Carica Pagine'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    if (_pages != null) ...[
                      const SizedBox(height: 12),
                      ..._pages!.map((page) => RadioListTile(
                        title: Text(page['name']),
                        subtitle: Text('ID: ${page['id']}'),
                        value: page['id'],
                        groupValue: _selectedPageId,
                        onChanged: (value) {
                          setState(() {
                            _selectedPageId = value as String;
                            _selectedPageToken = page['access_token'];
                          });
                        },
                      )),
                    ],
                  ],
                ),
              ),
            ),

            if (_selectedPageId != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📝 Pubblica Post',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          labelText: 'Messaggio',
                          border: OutlineInputBorder(),
                          hintText: 'Scrivi il tuo post...',
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _publishPost,
                        icon: const Icon(Icons.send),
                        label: const Text('Pubblica Post'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          backgroundColor: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Help Section
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💡 Guida Rapida',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text('1. Testa la connessione al backend'),
                    const Text('2. Genera un token su developers.facebook.com/tools/explorer'),
                    const Text('3. Incolla il token e validalo'),
                    const Text('4. Carica le tue pagine Facebook'),
                    const Text('5. Seleziona una pagina e pubblica un post di test'),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        _showTokenHelp();
                      },
                      icon: const Icon(Icons.info),
                      label: const Text('Come ottenere il token'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTokenHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔑 Come ottenere il token'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('1. Vai su:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SelectableText(
                'https://developers.facebook.com/tools/explorer/',
                style: TextStyle(color: Colors.blue),
              ),
              const SizedBox(height: 12),
              const Text('2. Seleziona la tua app:', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('App ID: 2102048307277114'),
              const SizedBox(height: 12),
              const Text('3. Clicca "Generate Access Token"'),
              const SizedBox(height: 12),
              const Text('4. Richiedi i permessi:', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('• pages_show_list'),
              const Text('• pages_manage_posts'),
              const Text('• pages_read_engagement'),
              const SizedBox(height: 12),
              const Text('5. Copia il token e incollalo qui'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.orange.shade50,
                child: const Text(
                  '⚠️ Il token ha durata limitata. Per un token long-lived (60 giorni), consulta la guida FACEBOOK_TOKEN_GUIDE.md',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(const ClipboardData(
                text: 'https://developers.facebook.com/tools/explorer/',
              ));
              Navigator.pop(context);
              _showSnackBar('URL copiato negli appunti!');
            },
            child: const Text('Copia URL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }
}
