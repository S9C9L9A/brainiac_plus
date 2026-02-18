# 🎯 Flutter Authentication Setup - Guida Completa

## 📦 File Creati

### 1. **api_client.dart** (Già esistente)
- Client HTTP per comunicare con il backend
- Servizio `FacebookAuthService`
- Metodi: `authenticateWithFacebook()`, `getUserPages()`, `postToPage()`

### 2. **auth_service.dart** (Nuovo)
- Wrapper del `FacebookAuthService`
- Metodi di alto livello per autenticazione
- Gestione token e dati utente

### 3. **auth_provider.dart** (Nuovo)
- State management con `ChangeNotifier`
- Gestione dello stato di autenticazione
- Metodi: `loginWithFacebook()`, `logout()`, `publishPost()`

### 4. **facebook_login_screen.dart** (Nuovo)
- UI completa per il login Facebook
- Gestione degli errori
- Info sul backend

### 5. **publish_post_screen.dart** (Nuovo)
- UI per pubblicare post
- Validazione messaggi
- Feedback all'utente

---

## 🚀 Come Integrare nel Tuo App

### Step 1: Aggiungi le Dipendenze

Nel tuo `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0        # State management
  http: ^1.1.0            # (già dovrebbe esserci)
  flutter_facebook_sdk: ^6.0.0  # Per vero Facebook SDK (OPZIONALE)
```

Esegui:
```bash
flutter pub get
```

### Step 2: Configura l'URL del Backend

Modifica `lib/core/network/api_client.dart`:
```dart
class ApiClient {
  // Scegli in base al tuo ambiente:
  
  // Per Emulatore Android
  static const String baseUrl = 'http://10.0.2.2:8080';
  
  // Per iOS Simulator
  // static const String baseUrl = 'http://localhost:8080';
  
  // Per Device Fisico
  // static const String baseUrl = 'http://192.168.1.XXX:8080'; // Sostituisci XXX con IP
}
```

### Step 3: Integra nel main.dart

```dart
import 'package:provider/provider.dart';
import 'lib/features/settings/controllers/auth_provider.dart';
import 'lib/features/settings/screens/facebook_login_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BraniacPlus',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // Se non autenticato, mostra login
          if (!authProvider.isAuthenticated) {
            return const FacebookLoginScreen();
          }
          // Altrimenti mostra home
          return const HomeScreen(); // Adatta al tuo widget
        },
      ),
      routes: {
        '/login': (_) => const FacebookLoginScreen(),
        '/home': (_) => const HomeScreen(), // Adatta al tuo widget
      },
    );
  }
}
```

### Step 4: Usa nel Tuo Widget

#### Accedi
```dart
import 'package:provider/provider.dart';
import 'lib/features/settings/controllers/auth_provider.dart';

// Nel tuo widget
ElevatedButton(
  onPressed: () async {
    final authProvider = context.read<AuthProvider>();
    
    // Con Facebook SDK vero (flutter_facebook_sdk)
    // const LoginResult result = await FacebookAuth.instance.login();
    // if (result.status == LoginStatus.success) {
    //   await authProvider.loginWithFacebook(
    //     accessToken: result.accessToken!.token,
    //     userID: result.accessToken!.userId!,
    //   );
    // }
    
    // Per test (token fittizio)
    await authProvider.loginWithFacebook(
      accessToken: 'TEST_TOKEN',
      userID: '123456',
    );
  },
  child: const Text('Login'),
)
```

#### Pubblica Post
```dart
import 'package:provider/provider.dart';

ElevatedButton(
  onPressed: () async {
    final authProvider = context.read<AuthProvider>();
    
    final success = await authProvider.publishPost(
      pageID: 'PAGE_ID',
      pageToken: 'PAGE_TOKEN',
      message: 'Ciao da BraniacPlus!',
    );
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post pubblicato!')),
      );
    }
  },
  child: const Text('Pubblica'),
)
```

#### Leggi l'Utente Corrente
```dart
Consumer<AuthProvider>(
  builder: (context, authProvider, _) {
    if (!authProvider.isAuthenticated) {
      return const Text('Non autenticato');
    }
    
    return Column(
      children: [
        Text('Utente: ${authProvider.currentUser?['name']}'),
        Text('Email: ${authProvider.currentUser?['email']}'),
      ],
    );
  },
)
```

#### Logout
```dart
ElevatedButton(
  onPressed: () {
    context.read<AuthProvider>().logout();
    Navigator.of(context).pushReplacementNamed('/login');
  },
  child: const Text('Logout'),
)
```

---

## 🧪 Test Senza Facebook SDK

Se non hai ancora il vero Facebook SDK, puoi testare con token di test:

```dart
// Nel login screen
const testToken = 'TEST_TOKEN_DEMO';
const testUserID = '123456789';

final result = await authProvider.loginWithFacebook(
  accessToken: testToken,
  userID: testUserID,
);
```

Il backend farà il parsing e ritornerà un errore (token non valido), che va bene per testare il flusso.

---

## 🔐 Integrare il Vero Facebook SDK

Quando sei pronto per il vero SDK:

### Installa flutter_facebook_sdk
```bash
flutter pub add flutter_facebook_sdk
```

### Configura Android
Segui: https://developers.facebook.com/docs/android/getting-started

### Configura iOS
Segui: https://developers.facebook.com/docs/ios/getting-started

### Nel Widget
```dart
import 'package:flutter_facebook_sdk/flutter_facebook_sdk.dart';

// Nel main
FacebookSdk.sdkInitialize();

// Nel login handler
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
  
  await authProvider.loginWithFacebook(
    accessToken: accessToken,
    userID: userID,
  );
}
```

---

## 🎯 Flusso Completo

```
┌─────────────────────────────────┐
│ FacebookLoginScreen             │
│ ├─ Login Button                │
│ ├─ Success/Error Messages       │
│ └─ Backend Info                │
└────────────┬────────────────────┘
             │ Login con token
             ▼
┌─────────────────────────────────┐
│ AuthProvider.loginWithFacebook()│
│ ├─ AuthService.loginWithFacebook
│ ├─ ApiClient.post()
│ ├─ Backend Go (validazione)
│ └─ Salva JWT + User Data
└────────────┬────────────────────┘
             │ Utente autenticato
             ▼
┌─────────────────────────────────┐
│ HomeScreen / App Principale     │
│ ├─ User Info: ${currentUser}    │
│ ├─ Publish Button               │
│ └─ Logout Button                │
└────────────┬────────────────────┘
             │ Pubblica post
             ▼
┌─────────────────────────────────┐
│ PublishPostScreen               │
│ ├─ TextField per messaggio      │
│ ├─ Pubblica Button              │
│ └─ Success/Error Messages       │
└────────────┬────────────────────┘
             │ Backend Go pubblica
             ▼
     ✅ Post su Facebook
```

---

## 📊 Stato nel AuthProvider

```dart
// Leggere lo stato
authProvider.isAuthenticated   // true/false
authProvider.currentUser       // {id, name, email}
authProvider.jwtToken          // Token JWT
authProvider.isLoading         // true mentre carica
authProvider.errorMessage      // Messaggio errore

// Modificare lo stato
authProvider.loginWithFacebook(...)
authProvider.publishPost(...)
authProvider.logout()
```

---

## 🐛 Troubleshooting

### "Connection refused"
- Verifica che il backend Go sia in esecuzione: `go run main.go`
- Verifica l'URL in `api_client.dart`

### "Errore 404 su /api/facebook/auth"
- Il backend Go potrebbe non avere i route Facebook
- Esegui `go run main.go` e verifica che stampi gli endpoint Facebook

### "Bad Request 400"
- Stai inviando dati nel formato sbagliato
- Verifica il JSON nel `ApiClient.post()`

### "Token non valido"
- Normale se usi token di test
- Usa il vero Facebook SDK per token reali

---

## ✅ Checklist

- [ ] Dipendenze installate (`provider`, `http`)
- [ ] URL backend configurato in `api_client.dart`
- [ ] AuthProvider integrato nel `main.dart`
- [ ] File Flutter creati importati correttamente
- [ ] Test del login (con token di test)
- [ ] Test della pubblicazione di post
- [ ] (Opzionale) Integrato vero Facebook SDK

---

## 🚀 Prossimi Passi

1. **Test subito:**
   ```bash
   flutter run
   ```

2. **Premi il pulsante di login (usa token di test)**

3. **Verifica i log per vedere le richieste al backend**

4. **Quando pronto, integra il vero Facebook SDK**

Buona codifica! 💻✨
