# 🔐 Guida: Come Ottenere un Token Facebook Valido

## ⚠️ Problema Attuale
Il token che hai fornito è **scaduto** o **invalidato**. Facebook riporta:
```
Error validating access token: The session is invalid because the user logged out.
```

## 📋 Informazioni App Facebook
- **App ID**: `2102048307277114`
- **App Secret**: `5cc547de365531456ec19ddc1a335cb7`
- **Nome App**: BraniacPlus (presumibilmente)

---

## 🔄 Come Generare un Nuovo Token

### Opzione 1: Facebook Graph API Explorer (Raccomandato per Testing)

1. **Vai su Facebook Graph API Explorer**
   ```
   https://developers.facebook.com/tools/explorer/
   ```

2. **Seleziona la tua App**
   - In alto a destra, nel menu dropdown "Meta App"
   - Seleziona l'app `2102048307277114` (BraniacPlus)

3. **Genera User Access Token**
   - Clicca su "Generate Access Token"
   - Accetta i permessi richiesti

4. **Richiedi i Permessi Necessari**
   - Clicca su "Permissions" (sotto il token)
   - Aggiungi questi permessi:
     - ✅ `pages_show_list` - Per vedere le tue pagine
     - ✅ `pages_read_engagement` - Per leggere engagement delle pagine
     - ✅ `pages_manage_posts` - Per pubblicare post
     - ✅ `publish_to_groups` - Se vuoi pubblicare in gruppi
   
5. **Copia il Token**
   - Il token apparirà nel campo "Access Token"
   - **IMPORTANTE**: Questo è un token temporaneo (1-2 ore)

6. **Estendi il Token (Opzionale ma Raccomandato)**
   ```bash
   curl -X GET "https://graph.facebook.com/v18.0/oauth/access_token?\
   grant_type=fb_exchange_token&\
   client_id=2102048307277114&\
   client_secret=5cc547de365531456ec19ddc1a335cb7&\
   fb_exchange_token=IL_TUO_TOKEN_BREVE"
   ```
   Questo restituirà un token che dura **60 giorni**.

---

### Opzione 2: OAuth Flow (Per Produzione)

Per un'app in produzione, dovresti implementare il flusso OAuth completo:

```dart
// Nel tuo Flutter app
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

Future<void> loginWithFacebook() async {
  final LoginResult result = await FacebookAuth.instance.login(
    permissions: [
      'pages_show_list',
      'pages_read_engagement', 
      'pages_manage_posts',
    ],
  );

  if (result.status == LoginStatus.success) {
    final AccessToken accessToken = result.accessToken!;
    print('Token: ${accessToken.tokenString}');
    
    // Invia questo token al backend
    sendTokenToBackend(accessToken.tokenString);
  }
}
```

---

### Opzione 3: Test Token dalla Dashboard

1. Vai su: https://developers.facebook.com/apps/2102048307277114/dashboard/
2. Settings → Basic
3. Cerca "App Token" o genera un "User Token" per testing

---

## 🧪 Dopo Aver Ottenuto il Nuovo Token

### Aggiorna il file .env

```bash
cd /home/giuseppe-genna/brainiac_plus/go_backend
nano .env
```

Sostituisci `FACEBOOK_TOKEN` con il nuovo token:
```env
FACEBOOK_TOKEN=IL_TUO_NUOVO_TOKEN_QUI
```

### Testa con lo Script

```bash
cd /home/giuseppe-genna/brainiac_plus

# Opzione 1: Modifica lo script con il nuovo token
nano test_facebook_automation.sh
# Modifica la variabile FACEBOOK_TOKEN

# Opzione 2: Passa il token come variabile d'ambiente
FACEBOOK_TOKEN="il_tuo_token" ./test_facebook_automation.sh
```

---

## 🔍 Verifica Manuale del Token

Puoi verificare rapidamente un token con questo comando:

```bash
TOKEN="il_tuo_token"

# Test 1: Info utente
curl "https://graph.facebook.com/v18.0/me?fields=id,name,email&access_token=$TOKEN"

# Test 2: Permessi
curl "https://graph.facebook.com/v18.0/me/permissions?access_token=$TOKEN"

# Test 3: Pagine
curl "https://graph.facebook.com/v18.0/me/accounts?access_token=$TOKEN"

# Test 4: Debug token
curl "https://graph.facebook.com/v18.0/debug_token?\
input_token=$TOKEN&\
access_token=2102048307277114|5cc547de365531456ec19ddc1a335cb7"
```

---

## 📝 Note Importanti

### Token Types
1. **User Access Token** (quello che ti serve)
   - Associato a un utente specifico
   - Scade dopo 1-2 ore (short-lived) o 60 giorni (long-lived)
   - Può essere esteso

2. **Page Access Token**
   - Associato a una pagina specifica
   - Ottieni questo DOPO aver fatto login con User Token
   - Necessario per pubblicare su pagine

3. **App Access Token**
   - `{app_id}|{app_secret}`
   - Usato per operazioni a livello di app
   - Non serve per automazioni utente

### Permessi Necessari per Automazioni

Per le automazioni Facebook avrai bisogno di:

| Permesso | Descrizione | Necessario per |
|----------|-------------|----------------|
| `pages_show_list` | Vedere le pagine gestite | Elencare pagine |
| `pages_read_engagement` | Leggere statistiche | Analytics |
| `pages_manage_posts` | Creare/modificare post | Pubblicare |
| `pages_read_user_content` | Leggere contenuti | Moderazione |
| `pages_manage_engagement` | Rispondere commenti | Automazione risposte |

### Limitazioni in Modalità Sviluppo

Se la tua app è in **Development Mode**:
- ⚠️ Solo tu (admin/developer) puoi usarla
- ⚠️ Le funzionalità sono limitate
- ⚠️ Devi passare in "Live Mode" per utenti esterni

Per passare in Live Mode:
1. Vai su App Settings → Basic
2. Scorri in basso
3. Attiva "App Mode: Live"
4. **Prima dovrai completare App Review per i permessi avanzati**

---

## 🚀 Prossimi Passi

1. ✅ Ottieni un nuovo token usando uno dei metodi sopra
2. ✅ Aggiorna il file `.env` o lo script di test
3. ✅ Esegui di nuovo `./test_facebook_automation.sh`
4. ✅ Se funziona, implementa l'OAuth flow nell'app Flutter
5. ✅ Testa le automazioni end-to-end

---

## 📞 Supporto

Se hai problemi:
1. Controlla i log del backend: `/tmp/copilot-detached-go_backend-*.log`
2. Usa Graph API Explorer per debugging: https://developers.facebook.com/tools/explorer/
3. Verifica i permessi dell'app su: https://developers.facebook.com/apps/2102048307277114/
