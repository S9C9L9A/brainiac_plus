# 🔧 MAINTENANCE & EXTENSION GUIDE

**Service Configuration Navigation System**

---

## 📋 QUICK REFERENCE

### Where Things Are
- **Routes**: `lib/routes/app_routes.dart` - Costante `serviceConfig`
- **Route Handler**: `lib/routes/route_generator.dart` - Case per `/service-config`
- **UI Screen**: `lib/features/settings/screens/service_config_screen.dart`
- **Integration**: `lib/features/settings/screens/modern_settings_screen.dart` - _buildServiceCard()
- **Examples**: `lib/features/settings/examples/service_config_navigation_examples.dart`

### Key Constants
```dart
// app_routes.dart
static const String serviceConfig = '/service-config';
```

---

## 🆕 AGGIUNGERE UN NUOVO SERVIZIO

### Step 1: Aggiungere a ServiceProvider enum
File: `lib/features/automation/models/automation_enums.dart`
```dart
enum ServiceProvider {
  // ... existing ...
  myNewService,  // ← Add here
}
```

### Step 2: Aggiungere label
```dart
extension ServiceProviderExtension on ServiceProvider {
  String get label {
    switch (this) {
      // ... existing ...
      case ServiceProvider.myNewService:
        return 'My New Service';
    }
  }
```

### Step 3: Aggiungere icon/emoji
```dart
  String get icon {
    switch (this) {
      // ... existing ...
      case ServiceProvider.myNewService:
        return '🆕';
    }
  }
```

### Step 4: Aggiungere gradiente
File: `service_config_screen.dart`
```dart
List<Color> _getServiceColors() {
  switch (widget.serviceType) {
    // ... existing ...
    case ServiceProvider.myNewService:
      return [const Color(0xFFXXXXXX), const Color(0xFFXXXXXX)];
  }
}
```

### Step 5: Aggiungere help text (opzionale)
```dart
String _getHelpText() {
  switch (widget.serviceType) {
    // ... existing ...
    case ServiceProvider.myNewService:
      return 'Visit myservice.com to generate...';
  }
}
```

---

## 🔄 MODIFICARE LA FORM

### Aggiungere campo aggiuntivo

File: `service_config_screen.dart`, metodo `_buildConfigurationForm()`

```dart
_buildTextField(
  controller: _newFieldController,  // ← Add controller in initState
  label: 'New Field',
  hint: 'Enter value',
  icon: Icons.some_icon,
),
```

### Aggiungere validazione

Nel metodo `_handleSave()`:
```dart
if (_apiKeyController.text.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('API Key is required')),
  );
  return;
}
```

---

## 🔌 IMPLEMENTARE OAUTH

### Aggiungere dipendenza
```yaml
# pubspec.yaml
dependencies:
  google_sign_in: ^latest
  # or similar for your service
```

### Aggiungere metodo OAuth
```dart
Future<void> _handleOAuth() async {
  try {
    // Implement OAuth flow
    final credential = await _performOAuthFlow();
    setState(() => _oauthToken = credential);
  } catch (e) {
    // Handle error
  }
}
```

### Aggiungere bottone
```dart
ElevatedButton(
  onPressed: _handleOAuth,
  child: const Text('Authorize with OAuth'),
),
```

---

## 💾 IMPLEMENTARE SECURE STORAGE

### Aggiungere dipendenza
```yaml
dependencies:
  flutter_secure_storage: ^latest
```

### Salvare credenziali
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();

Future<void> _saveCredentials() async {
  await storage.write(
    key: 'api_key_${widget.serviceType}',
    value: _apiKeyController.text,
  );
  await storage.write(
    key: 'api_secret_${widget.serviceType}',
    value: _apiSecretController.text,
  );
}
```

### Caricacredenziali
```dart
@override
void initState() {
  super.initState();
  _loadCredentials();
}

Future<void> _loadCredentials() async {
  final apiKey = await storage.read(
    key: 'api_key_${widget.serviceType}',
  );
  if (apiKey != null) {
    _apiKeyController.text = apiKey;
  }
}
```

---

## 🧪 TESTING

### Test Navigazione
```dart
test('Navigate to service config', () {
  AppRoutes.navigateTo(
    context,
    AppRoutes.serviceConfig,
    arguments: ServiceProvider.github,
  );
  
  expect(find.byType(ServiceConfigScreen), findsOneWidget);
});
```

### Test Type-Safety
```dart
test('Invalid arguments show error', () {
  final route = RouteGenerator.generateRoute(
    RouteSettings(
      name: AppRoutes.serviceConfig,
      arguments: 'invalid',  // String instead of ServiceProvider
    ),
  );
  
  expect(route, isA<MaterialPageRoute>());
});
```

---

## 🐛 TROUBLESHOOTING

### Problema: "Route not found"
**Soluzione**: Verificare che `serviceConfig` sia definito in `app_routes.dart`
```dart
grep "serviceConfig" lib/routes/app_routes.dart
```

### Problema: Type mismatch
**Soluzione**: Assicurarsi che arguments sia un `ServiceProvider`:
```dart
// ✅ Corretto
arguments: ServiceProvider.github,

// ❌ Sbagliato
arguments: 'github',
```

### Problema: ServiceConfigScreen non appare
**Soluzione**: Verificare import in `route_generator.dart`:
```dart
import '../features/settings/screens/service_config_screen.dart';
```

---

## 📊 MONITORARE PERFORMANCE

### Aggiungere Analytics
```dart
void _handleSave() {
  // Log analytics
  FirebaseAnalytics.instance.logEvent(
    name: 'service_configured',
    parameters: {
      'service': widget.serviceType.label,
      'timestamp': DateTime.now().toIso8601String(),
    },
  );
}
```

### Aggiungere Logging
```dart
debugPrint('[ServiceConfig] Saving ${widget.serviceType.label}');
```

---

## 🔮 FUTURE ENHANCEMENTS

### Priority 1
- [ ] Credential encryption
- [ ] Connection test button
- [ ] Service disconnect option

### Priority 2
- [ ] OAuth integration
- [ ] Rate limit display
- [ ] Usage statistics

### Priority 3
- [ ] Webhook management
- [ ] Permission scopes UI
- [ ] Service notifications

---

## 📞 SUPPORT

### Documentation
- `SERVICE_CONFIG_GUIDE.md` - Usage guide
- `SERVICE_CONFIG_IMPLEMENTATION.md` - Technical details
- `service_config_navigation_examples.dart` - Code examples

### Files to Review
1. `app_routes.dart` - Routes definition
2. `route_generator.dart` - Route handling
3. `service_config_screen.dart` - UI implementation
4. `modern_settings_screen.dart` - Integration points

### Common Tasks
- **Add service**: Follow "Add nuovo servizio" section
- **Modify form**: Edit `_buildConfigurationForm()`
- **Debug navigation**: Check `route_generator.dart`
- **Update UI**: Modify `service_config_screen.dart`

---

## ✅ CHECKLIST

Prima di deployare:
- [ ] Test navigazione su tutti i servizi
- [ ] Verificare help text per errori
- [ ] Test form validation
- [ ] Check gradinti colori
- [ ] Verificare loading states
- [ ] Test error handling
- [ ] Review documentation
- [ ] Check for unused imports

---

**Maintained By**: BrainiacPlus Development Team
**Last Updated**: 13 Febbraio 2026
**Version**: 2.0.0
