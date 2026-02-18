# 🧠 BrainiacPlus - Sistema Automazioni Facebook

## 📋 Panoramica

Il sistema di automazioni Facebook di BrainiacPlus permette di:
- ✅ Autenticare utenti tramite Facebook OAuth
- ✅ Recuperare le pagine Facebook gestite dall'utente
- ✅ Pubblicare post automaticamente su pagine Facebook
- ✅ Schedulare pubblicazioni con cron
- ✅ Gestire automazioni multi-piattaforma (Linux + Android)

---

## 🏗️ Architettura

```
┌─────────────────────────────────────────────────────────┐
│                  FLUTTER APP (UI)                        │
│  ┌───────────────┐  ┌──────────────────────────────┐   │
│  │ Test Screen   │  │ Automation Controller         │   │
│  │ (Manual Test) │  │ (Scheduled Automations)       │   │
│  └───────┬───────┘  └──────────┬───────────────────┘   │
│          │                      │                        │
│          └──────────┬───────────┘                        │
│                     │                                     │
└─────────────────────┼─────────────────────────────────────┘
                      │ HTTP Requests
                      ▼
┌─────────────────────────────────────────────────────────┐
│               GO BACKEND (API Server)                    │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Routes (facebook.go)                            │  │
│  │  - POST /api/facebook/auth                       │  │
│  │  - GET  /api/facebook/pages                      │  │
│  │  - POST /api/facebook/post                       │  │
│  └────────────────┬─────────────────────────────────┘  │
│                   │                                      │
│  ┌────────────────▼─────────────────────────────────┐  │
│  │  Services (facebook.go)                          │  │
│  │  - ValidateUserToken()                           │  │
│  │  - GetUserInfo()                                 │  │
│  │  - GetUserPages()                                │  │
│  │  - PostToPage()                                  │  │
│  └────────────────┬─────────────────────────────────┘  │
│                   │                                      │
└───────────────────┼──────────────────────────────────────┘
                    │ Facebook Graph API
                    ▼
┌─────────────────────────────────────────────────────────┐
│          FACEBOOK GRAPH API v18.0                        │
│  - User Authentication & Token Validation               │
│  - Page Management                                      │
│  - Post Publishing                                      │
└─────────────────────────────────────────────────────────┘
```

---

## 🔧 Setup

### 1. Configurazione Facebook App

**App Details:**
- App ID: `2102048307277114`
- App Secret: `5cc547de365531456ec19ddc1a335cb7`
- Dashboard: https://developers.facebook.com/apps/2102048307277114/

**Permessi Necessari:**
```
pages_show_list          - Visualizzare le pagine gestite
pages_read_engagement    - Leggere statistiche pagine
pages_manage_posts       - Pubblicare e gestire post
```

### 2. Backend Go Configuration

File: `go_backend/.env`
```env
PORT=8080

# Facebook Integration
FACEBOOK_TOKEN=<your_user_access_token>
FACEBOOK_APP_ID=2102048307277114
FACEBOOK_APP_SECRET=5cc547de365531456ec19ddc1a335cb7
```

**Avvio Backend:**
```bash
cd go_backend
go run main.go
```

Il backend sarà disponibile su `http://localhost:8080`

### 3. Flutter App Setup

**Dipendenze richieste** (già configurate):
```yaml
dependencies:
  http: ^1.1.0
  flutter_riverpod: ^2.4.0
```

**Nessuna configurazione aggiuntiva necessaria** - l'app si connette automaticamente a localhost:8080

---

## 🧪 Testing

### Opzione 1: Script Interattivo (Raccomandato)

```bash
cd /home/giuseppe-genna/brainiac_plus
./test_facebook_interactive.sh
```

Lo script ti guiderà attraverso:
1. ✅ Test connessione backend
2. ✅ Validazione token Facebook
3. ✅ Recupero informazioni utente
4. ✅ Lista pagine disponibili
5. ✅ Pubblicazione post di test

### Opzione 2: Script Automatico

```bash
cd /home/giuseppe-genna/brainiac_plus

# Modifica prima il token nello script
nano test_facebook_automation.sh
# Cambia FACEBOOK_TOKEN con il tuo token valido

./test_facebook_automation.sh
```

### Opzione 3: Flutter Test Screen

1. **Avvia l'app Flutter:**
   ```bash
   cd /home/giuseppe-genna/brainiac_plus
   flutter run -d linux
   ```

2. **Naviga alla schermata di test:**
   - Vai su "Automations"
   - Clicca sull'icona Facebook (in alto a destra)

3. **Esegui i test:**
   - Incolla il tuo Facebook Access Token
   - Clicca "Valida Token"
   - Clicca "Carica Pagine"
   - Seleziona una pagina
   - Scrivi un messaggio
   - Clicca "Pubblica Post"

### Opzione 4: Test Manuali con cURL

```bash
# Test 1: Health check
curl http://localhost:8080/health

# Test 2: Autenticazione
curl -X POST http://localhost:8080/api/facebook/auth \
  -H "Content-Type: application/json" \
  -d '{"access_token": "YOUR_TOKEN"}'

# Test 3: Lista pagine
curl -X GET http://localhost:8080/api/facebook/pages \
  -H "X-Facebook-Token: YOUR_TOKEN"

# Test 4: Pubblica post
curl -X POST http://localhost:8080/api/facebook/post \
  -H "Content-Type: application/json" \
  -d '{
    "page_id": "PAGE_ID",
    "page_token": "PAGE_TOKEN",
    "message": "Test post da BrainiacPlus!"
  }'
```

---

## 🔑 Come Ottenere un Token Valido

### Il tuo token attuale è SCADUTO

Il token che hai fornito risulta invalido:
```
Error: The session is invalid because the user logged out.
```

### Soluzione: Genera un Nuovo Token

#### Metodo 1: Facebook Graph API Explorer (Più Veloce)

1. Vai su: https://developers.facebook.com/tools/explorer/

2. In alto a destra:
   - Seleziona "Meta App" → `2102048307277114` (la tua app)

3. Clicca "Generate Access Token"

4. Seleziona i permessi:
   - ✅ `pages_show_list`
   - ✅ `pages_manage_posts`
   - ✅ `pages_read_engagement`

5. Copia il token generato

6. **IMPORTANTE**: Questo token dura 1-2 ore

#### Metodo 2: Estendi il Token (60 giorni)

Dopo aver ottenuto il token short-lived:

```bash
curl -X GET "https://graph.facebook.com/v18.0/oauth/access_token?\
grant_type=fb_exchange_token&\
client_id=2102048307277114&\
client_secret=5cc547de365531456ec19ddc1a335cb7&\
fb_exchange_token=IL_TUO_TOKEN_BREVE"
```

Riceverai un token long-lived valido per 60 giorni.

#### Metodo 3: OAuth Flow Completo (Produzione)

Per l'app in produzione, implementa l'OAuth flow nel Flutter:

```dart
// Usa flutter_facebook_auth package
final LoginResult result = await FacebookAuth.instance.login(
  permissions: ['pages_show_list', 'pages_manage_posts'],
);

if (result.status == LoginStatus.success) {
  final token = result.accessToken!.tokenString;
  // Usa questo token
}
```

---

## 📚 Documentazione Completa

- **FACEBOOK_TOKEN_GUIDE.md** - Guida dettagliata su token e permessi
- **GO_BACKEND_GUIDE.md** - Documentazione backend Go
- **PROJECT_SUMMARY.md** - Panoramica completa del progetto

---

## 🔌 API Endpoints

### POST /api/facebook/auth
Autentica un utente con Facebook token.

**Request:**
```json
{
  "access_token": "EAAd3zUKn..."
}
```

**Response (Success):**
```json
{
  "valid": true,
  "user": {
    "id": "123456789",
    "name": "Mario Rossi",
    "email": "mario@example.com"
  },
  "message": "Autenticazione riuscita"
}
```

**Response (Error):**
```json
{
  "valid": false,
  "message": "token non valido"
}
```

---

### GET /api/facebook/pages
Recupera le pagine Facebook dell'utente autenticato.

**Headers:**
```
X-Facebook-Token: EAAd3zUKn...
```

**Response:**
```json
{
  "pages": [
    {
      "id": "109876543210",
      "name": "La Mia Pagina",
      "access_token": "EAAd3zUKn...",
      "category": "Community"
    }
  ]
}
```

---

### POST /api/facebook/post
Pubblica un post su una pagina Facebook.

**Request:**
```json
{
  "page_id": "109876543210",
  "page_token": "EAAd3zUKn...",
  "message": "Il mio post automatizzato! 🚀"
}
```

**Response:**
```json
{
  "post_id": "109876543210_123456789",
  "message": "Post pubblicato con successo"
}
```

---

## 🔄 Automazioni Programmate

### Configurazione Automation Controller

```dart
// Crea una nuova automazione
final automation = Automation(
  id: 'fb_daily_post',
  name: 'Post Giornaliero Facebook',
  description: 'Pubblica un post ogni giorno alle 10:00',
  category: AutomationCategory.social,
  service: ServiceProvider.facebook,
  triggerType: TriggerType.scheduled,
  cronSchedule: '0 10 * * *', // Ogni giorno alle 10:00
  config: {
    'page_id': 'YOUR_PAGE_ID',
    'page_token': 'YOUR_PAGE_TOKEN',
    'message_template': 'Buongiorno! Oggi è il {date}',
  },
);

// Salva l'automazione
await AutomationRepository.insertAutomation(automation);
```

### Formato Cron Schedule

```
┌───────────── minuto (0 - 59)
│ ┌───────────── ora (0 - 23)
│ │ ┌───────────── giorno del mese (1 - 31)
│ │ │ ┌───────────── mese (1 - 12)
│ │ │ │ ┌───────────── giorno della settimana (0 - 6, 0=Domenica)
│ │ │ │ │
* * * * *
```

**Esempi:**
```
0 10 * * *     - Ogni giorno alle 10:00
0 */4 * * *    - Ogni 4 ore
0 9 * * 1      - Ogni lunedì alle 9:00
0 12 1 * *     - Primo giorno di ogni mese alle 12:00
*/30 * * * *   - Ogni 30 minuti
```

---

## 🐛 Troubleshooting

### Problema: "Token non valido"
**Soluzione:** Il token è scaduto. Genera un nuovo token usando Graph API Explorer.

### Problema: "Backend non raggiungibile"
**Soluzione:** 
```bash
# Verifica che il backend sia in esecuzione
ps aux | grep "go run main.go"

# Se non è attivo, avvialo
cd go_backend && go run main.go &
```

### Problema: "Nessuna pagina trovata"
**Soluzione:** 
- Verifica di essere admin/editor di almeno una pagina Facebook
- Controlla che il token abbia il permesso `pages_show_list`
- Genera un nuovo token con i permessi corretti

### Problema: "Errore pubblicazione post"
**Possibili cause:**
1. Token della pagina non valido
2. Permesso `pages_manage_posts` mancante
3. Pagina in modalità restricted
4. Rate limit di Facebook raggiunto

**Soluzione:**
```bash
# Testa direttamente con Facebook API
curl "https://graph.facebook.com/v18.0/me/permissions?access_token=YOUR_TOKEN"
```

### Problema: "App in Development Mode"
**Soluzione:**
- L'app Facebook è in modalità sviluppo
- Solo admin/developer/tester possono usarla
- Per utenti esterni, devi passare in "Live Mode" (richiede App Review)

---

## 📊 Limiti e Rate Limits

Facebook applica rate limits alle API:

| Endpoint | Limite |
|----------|--------|
| Graph API Calls | 200 chiamate/ora (per utente) |
| Page Posts | Variabile, dipende dalla pagina |
| Token Validation | Illimitato |

**Best Practices:**
- Non pubblicare più di 1 post/ora per pagina
- Cache le informazioni delle pagine
- Implementa retry con backoff esponenziale
- Monitora gli errori di rate limit (error code 4)

---

## 🚀 Prossimi Passi

### Fase 1: Test Completo ✅
- [x] Setup backend Go
- [x] Configurazione Facebook App
- [x] Creazione script di test
- [x] UI di test in Flutter
- [ ] **Generare nuovo token valido**
- [ ] **Eseguire test completi**

### Fase 2: Implementazione Automazioni
- [ ] Implementare scheduler nel backend
- [ ] Aggiungere supporto per template di messaggi
- [ ] Gestire variabili dinamiche nei post ({date}, {time}, etc)
- [ ] Implementare retry logic

### Fase 3: UI Migliorata
- [ ] Wizard di creazione automazione Facebook
- [ ] Anteprima post prima della pubblicazione
- [ ] Analytics delle automazioni
- [ ] Notifiche push per post pubblicati

### Fase 4: Features Avanzate
- [ ] Supporto per immagini/video nei post
- [ ] Pubblicazione multi-pagina
- [ ] Integrazione con AI per generazione contenuti
- [ ] Moderazione automatica commenti
- [ ] Risposta automatica ai messaggi

---

## 📞 Supporto

**Documentazione:**
- Leggi `FACEBOOK_TOKEN_GUIDE.md` per problemi con i token
- Leggi `GO_BACKEND_GUIDE.md` per configurazione backend
- Consulta [Facebook Developers Docs](https://developers.facebook.com/docs/graph-api/)

**Debug:**
```bash
# Logs backend
tail -f /tmp/copilot-detached-go_backend-*.log

# Test manuale API
cd /home/giuseppe-genna/brainiac_plus
./test_facebook_interactive.sh
```

**Contatti:**
- GitHub Issues: [brainiac_plus/issues]
- Facebook Developers: https://developers.facebook.com/support/
