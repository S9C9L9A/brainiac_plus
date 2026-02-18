# 📱 Flutter Integration - Backend Go

## 📋 Indice
1. [Setup Iniziale](#setup-iniziale)
2. [Autenticazione Facebook](#autenticazione-facebook)
3. [Pubblicare Post](#pubblicare-post)
4. [Gestire i Token](#gestire-i-token)
5. [Esempi Completi](#esempi-completi)

---

## 🚀 Setup Iniziale

### Step 1: Aggiungi le Dipendenze
```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  
  # HTTP Client
  http: ^1.1.0
  
  # Facebook SDK
  flutter_facebook_sdk: ^6.0.0
  
  # Secure Storage
  flutter_secure_storage: ^9.0.0
  
  # Logging
  logger: ^2.0.0
```

### Step 2: Copia il Client API
Copia il file `lib/core/network/api_client.dart` creato

### Step 3: Configura il Backend URL
```dart
// lib/core/network/api_client.dart
static const String baseUrl = 'http://localhost:8080'; // Locale
// static const String baseUrl = 'https://api.brainiac.com'; // Produzione
```

---

## 🔐 Autenticazione Facebook

### Step 1: Configura Facebook SDK
```dart
// main.dart
import 'package:flutter_facebook_sdk/flutter_facebook_sdk.dart';

void main() {
  FacebookSdk.sdkInitialize();
  runApp(MyApp());
}
```

### Step 2: Implementa il Login
```dart
// lib/features/settings/facebook_login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_facebook_sdk/flutter_facebook_sdk.dart';
import 'package:core/network/api_client.dart';

class FacebookLoginScreen extends StatefulWidget {
  @override
  State<FacebookLoginScreen> createState() => _FacebookLoginScreenState();
}

class _FacebookLoginScreenState extends State<FacebookLoginScreen> {
  bool isLoading = false;

  Future<void> _loginWithFacebook() async {
    setState(() => isLoading = true);

    try {
      // 1️⃣ Login con Facebook SDK
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: [
          'email',
          'public_profile',
          'pages_manage_posts', // Per pubblicare post
        ],
      );

      if (result.status == LoginStatus.success) {
        final accessToken = result.accessToken!.token;
        final userID = result.accessToken!.userId!;

        // 2️⃣ Invia il token al backend Go
        final response = await FacebookAuthService.authenticateWithFacebook(
          accessToken,
          userID,
        );

        // 3️⃣ Mostra il risultato
        if (response['valid']) {
          final user = response['user'];
          _showSuccessDialog(user['name']);
          
          // 4️⃣ Salva i dati
          await _saveUserData(response);
        } else {
          _showErrorDialog(response['message']);
        }
      }
    } catch (e) {
      _showErrorDialog('Errore: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveUserData(Map<String, dynamic> authData) async {
    // TODO: Salva in SecureStorage o database
    // final storage = FlutterSecureStorage();
    // await storage.write(
    //   key: 'facebook_user_id',
    //   value: authData['user']['id'],
    // );
  }

  void _showSuccessDialog(String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Accesso Riuscito'),
        content: Text('Benvenuto, $name!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Errore'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Facebook Login')),
      body: Center(
        child: ElevatedButton(
          onPressed: isLoading ? null : _loginWithFacebook,
          child: isLoading
              ? CircularProgressIndicator()
              : Text('Login con Facebook'),
        ),
      ),
    );
  }
}
```

---

## 📝 Pubblicare Post

### Step 1: Recupera le Pagine
```dart
// lib/features/automation/facebook_pages_screen.dart

class FacebookPagesScreen extends StatefulWidget {
  final String facebookToken;
  
  const FacebookPagesScreen({required this.facebookToken});

  @override
  State<FacebookPagesScreen> createState() => _FacebookPagesScreenState();
}

class _FacebookPagesScreenState extends State<FacebookPagesScreen> {
  late Future<List<dynamic>> _pagesFuture;

  @override
  void initState() {
    super.initState();
    _pagesFuture = FacebookAuthService.getUserPages(widget.facebookToken);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Le Mie Pagine')),
      body: FutureBuilder<List<dynamic>>(
        future: _pagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Errore: ${snapshot.error}'));
          }

          final pages = snapshot.data ?? [];

          return ListView.builder(
            itemCount: pages.length,
            itemBuilder: (context, index) {
              final page = pages[index];
              return ListTile(
                title: Text(page['name']),
                subtitle: Text(page['category']),
                trailing: Icon(Icons.arrow_forward),
                onTap: () {
                  // Vai alla schermata di pubblicazione
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PublishPostScreen(
                        pageID: page['id'],
                        pageToken: page['access_token'],
                        pageName: page['name'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
```

### Step 2: Pubblica un Post
```dart
// lib/features/automation/publish_post_screen.dart

class PublishPostScreen extends StatefulWidget {
  final String pageID;
  final String pageToken;
  final String pageName;

  const PublishPostScreen({
    required this.pageID,
    required this.pageToken,
    required this.pageName,
  });

  @override
  State<PublishPostScreen> createState() => _PublishPostScreenState();
}

class _PublishPostScreenState extends State<PublishPostScreen> {
  final messageController = TextEditingController();
  bool isLoading = false;

  Future<void> _publishPost() async {
    if (messageController.text.isEmpty) {
      _showErrorDialog('Scrivi un messaggio!');
      return;
    }

    setState(() => isLoading = true);

    try {
      final postId = await FacebookAuthService.postToPage(
        widget.pageID,
        widget.pageToken,
        messageController.text,
      );

      _showSuccessDialog('Post pubblicato! ID: $postId');
      messageController.clear();
    } catch (e) {
      _showErrorDialog('Errore: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pubblica su ${widget.pageName}')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: messageController,
              maxLines: 10,
              decoration: InputDecoration(
                hintText: 'Scrivi il tuo messaggio...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: isLoading ? null : _publishPost,
              icon: isLoading ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ) : Icon(Icons.send),
              label: Text(isLoading ? 'Pubblicazione...' : 'Pubblica'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}
```

---

## 🔑 Gestire i Token

### Salva i Token in Secure Storage
```dart
// lib/core/services/secure_storage_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveFacebookToken(String token) async {
    await _storage.write(key: 'facebook_token', value: token);
  }

  static Future<String?> getFacebookToken() async {
    return await _storage.read(key: 'facebook_token');
  }

  static Future<void> saveJWTToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  static Future<String?> getJWTToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  static Future<void> deleteAllTokens() async {
    await _storage.delete(key: 'facebook_token');
    await _storage.delete(key: 'jwt_token');
  }
}
```

### Logout
```dart
// lib/features/settings/settings_screen.dart

Future<void> _logout() async {
  // 1. Logout da Facebook
  await FacebookAuth.instance.logOut();

  // 2. Elimina i token salvati
  await SecureStorageService.deleteAllTokens();

  // 3. Naviga al login
  Navigator.pushReplacementNamed(context, '/login');
}
```

---

## 💡 Esempi Completi

### Flusso di Autenticazione Completo
```dart
// lib/features/auth/auth_provider.dart

import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  String? _jwtToken;
  String? _facebookToken;
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;
  String? get jwtToken => _jwtToken;

  Future<bool> loginWithFacebook() async {
    try {
      // 1. Login con Facebook
      final result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final accessToken = result.accessToken!.token;
        final userID = result.accessToken!.userId!;

        // 2. Autentica con il backend
        final response = await FacebookAuthService.authenticateWithFacebook(
          accessToken,
          userID,
        );

        if (response['valid']) {
          // 3. Salva i token
          _facebookToken = accessToken;
          _jwtToken = response['token'];
          _isAuthenticated = true;

          // 4. Persisti i token
          await SecureStorageService.saveFacebookToken(accessToken);
          await SecureStorageService.saveJWTToken(response['token']);

          notifyListeners();
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await FacebookAuth.instance.logOut();
    await SecureStorageService.deleteAllTokens();

    _isAuthenticated = false;
    _jwtToken = null;
    _facebookToken = null;

    notifyListeners();
  }

  Future<void> restoreSession() async {
    final token = await SecureStorageService.getJWTToken();
    if (token != null) {
      _jwtToken = token;
      _isAuthenticated = true;
      notifyListeners();
    }
  }
}
```

### Uso nel Widget
```dart
// main.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FacebookSdk.sdkInitialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..restoreSession(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isAuthenticated) {
            return HomeScreen();
          } else {
            return FacebookLoginScreen();
          }
        },
      ),
    );
  }
}
```

---

## 🔗 Collegare Backend al Widget

### Passo 1: Assicurati che il Backend sia in Esecuzione
```bash
cd go_backend
go run main.go
# Output: 🧠 BrainiacPlus Backend starting on :8080
```

### Passo 2: Configura l'URL Corretto
```dart
// lib/core/network/api_client.dart

// Per Android Emulator
static const String baseUrl = 'http://10.0.2.2:8080';

// Per iOS Simulator
static const String baseUrl = 'http://localhost:8080';

// Per Device Fisico
static const String baseUrl = 'http://192.168.1.XXX:8080'; // IP della tua macchina
```

### Passo 3: Testa la Connessione
```dart
// In un widget di test
ElevatedButton(
  onPressed: () async {
    try {
      final health = await ApiClient.get('/health');
      print('Backend è alive: $health');
    } catch (e) {
      print('Errore: $e');
    }
  },
  child: Text('Test Backend'),
)
```

---

## ⚡ Flusso Completo

```
┌─────────────────────────────────────────────────┐
│ 1. User preme "Login con Facebook"              │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│ 2. Facebook SDK apre dialog di login            │
│    User inserisce credenziali                   │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│ 3. Facebook ritorna accessToken                 │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│ 4. Flutter invia token al Backend Go            │
│    POST /api/facebook/auth                      │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│ 5. Backend valida token con Facebook API       │
│    Recupera info utente                         │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│ 6. Backend genera JWT e ritorna al Flutter      │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│ 7. Flutter salva JWT in SecureStorage           │
│    Utente è autenticato                         │
└─────────────────────────────────────────────────┘
```

---

Perfetto! Ora hai tutto pronto per integrare Facebook nel tuo app Flutter! 🚀
