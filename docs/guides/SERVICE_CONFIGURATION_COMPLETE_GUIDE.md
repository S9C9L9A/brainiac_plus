# 📚 Guida Completa alla Configurazione dei Servizi

## 🎯 Panoramica

BrainiacPlus offre un **wizard interattivo** per configurare qualsiasi servizio social in modo semplice e guidato.

---

## ✨ Nuovo Sistema di Configurazione

### Caratteristiche Principali

✅ **Wizard Step-by-Step** - 4 passi guidati  
✅ **Validazione in tempo reale** - Feedback immediato  
✅ **Test di connessione integrato** - Verifica credenziali  
✅ **Link alla documentazione** - Aiuto contestuale  
✅ **Paste from clipboard** - Incolla credenziali facilmente  
✅ **Progress indicator** - Visualizza il progresso  
✅ **Help button** - Aiuto disponibile sempre  

---

## 🚀 Come Configurare un Servizio

### Step 1: Aprire la Configurazione

```
Dashboard → Settings → Tab "Services" → Clicca su un servizio
```

Oppure:

```
Automation → "New Task" → Seleziona servizio → "Setup Now"
```

### Step 2: Seguire il Wizard

Il wizard ti guiderà attraverso **4 passi**:

```
┌─────────────────────────────────────┐
│  Step 1: WELCOME                    │
│  ↓  Cosa serve e cosa ottieni       │
├─────────────────────────────────────┤
│  Step 2: CREDENTIALS                │
│  ↓  Inserisci API Key/Secret        │
├─────────────────────────────────────┤
│  Step 3: TEST CONNECTION            │
│  ↓  Verifica che funzioni           │
├─────────────────────────────────────┤
│  Step 4: COMPLETION                 │
│  ↓  Riepilogo e prossimi passi      │
└─────────────────────────────────────┘
```

---

## 📋 Step-by-Step Dettagliato

### 🎬 Step 1: Welcome

**Cosa vedrai:**
- Icona del servizio con animazione
- Lista dei requisiti necessari
- Benefici della configurazione
- Tempo stimato (5 minuti)

**Cosa fare:**
- Leggi i requisiti
- Clicca "Next" per continuare

---

### 🔑 Step 2: Enter Credentials

**Cosa vedrai:**
- Form per API Key e API Secret
- Card "How to get credentials" con istruzioni
- Link diretto alla documentazione
- Pulsante "Paste" per incollare da clipboard

**Cosa fare:**

1. **Clicca su "Open Documentation"**
   - Si apre la guida ufficiale del servizio
   - Segui le istruzioni per ottenere le credenziali

2. **Copia le credenziali**
   - API Key (obbligatorio)
   - API Secret (se richiesto)

3. **Incolla nel form**
   - Usa il pulsante "Paste" oppure
   - Digita manualmente

4. **Validazione automatica**
   - ✅ Verde se valido
   - ❌ Rosso se manca o troppo corto

5. **Clicca "Next"** quando tutto è verde

---

### 🧪 Step 3: Test Connection

**Cosa vedrai:**
- Card "Ready to test"
- Pulsante "Test Connection"
- Loading indicator durante il test
- Risultato del test (success/error)

**Cosa fare:**

1. **Clicca "Test Connection"**
   - Attendi 2-3 secondi
   - L'app testa le credenziali

2. **Se successo (✅):**
   - Vedi "Connection Successful!"
   - Clicca "Next" per continuare

3. **Se errore (❌):**
   - Vedi messaggio d'errore
   - Clicca "Back" per correggere
   - Riprova

---

### 🏆 Step 4: Completion

**Cosa vedrai:**
- Riepilogo della configurazione
- Service name, status, API key
- Card "Next Steps"
- Pulsante "Complete Setup"

**Cosa fare:**

1. **Verifica il riepilogo**
   - Controlla che tutto sia corretto

2. **Leggi i next steps**
   - Suggerimenti su cosa fare dopo

3. **Clicca "Complete Setup"**
   - Salva la configurazione
   - Ritorna alla schermata precedente

---

## 🎨 Funzionalità Speciali

### 📋 Paste from Clipboard

Ogni campo ha un pulsante "Paste":
- Clicca per incollare da clipboard
- Risparmia tempo
- Evita errori di digitazione

### 🔍 Validazione in Tempo Reale

I campi vengono validati mentre digiti:
- ✅ **Verde** = Valido
- ⚠️ **Giallo** = Avviso
- ❌ **Rosso** = Errore

### 📊 Progress Indicator

Barra in alto mostra il progresso:
```
[████████░░░░] Step 2 of 4
```

### ❓ Help Button

Sempre disponibile in alto a destra:
- Clicca per aprire menu aiuto
- View Documentation
- Watch Tutorial
- Contact Support

---

## 🛠️ Servizi Supportati

### Social Media

| Servizio | Requisiti | Tempo |
|----------|-----------|-------|
| **Facebook** | App ID + Secret + Page Token | ~5 min |
| **Instagram** | Business Account + Access Token | ~5 min |
| **Twitter/X** | API Key + Secret | ~5 min |
| **LinkedIn** | Client ID + Secret | ~5 min |
| **YouTube** | API Key | ~3 min |
| **TikTok** | Client Key + Secret | ~5 min |

### Development

| Servizio | Requisiti | Tempo |
|----------|-----------|-------|
| **GitHub** | Personal Access Token | ~2 min |
| **GitLab** | Private Token | ~2 min |

### Communication

| Servizio | Requisiti | Tempo |
|----------|-----------|-------|
| **Slack** | Bot Token + Webhook URL | ~3 min |
| **Discord** | Bot Token | ~3 min |
| **Telegram** | Bot Token | ~2 min |

### Productivity

| Servizio | Requisiti | Tempo |
|----------|-----------|-------|
| **Notion** | API Key | ~3 min |
| **Trello** | API Key + Token | ~3 min |

---

## 📖 Guide Specifiche per Servizio

### 📘 Facebook

**Prerequisiti:**
- Account Facebook Developer
- Pagina Facebook creata

**Passi:**
1. Vai a: https://developers.facebook.com
2. Crea app o seleziona esistente
3. Vai a Settings → Basic
4. Copia **App ID** e **App Secret**
5. Vai a Graph API Explorer
6. Genera **Page Access Token**
7. Incolla tutto nel wizard

**Permessi necessari:**
- `pages_show_list`
- `pages_read_engagement`
- `pages_manage_posts` (per posting)

---

### 📷 Instagram

**Prerequisiti:**
- Account Instagram Business
- Pagina Facebook collegata

**Passi:**
1. Converti account Instagram a Business
2. Collega a Pagina Facebook
3. Vai a: https://developers.facebook.com/tools/explorer/
4. Seleziona la tua app
5. Genera token con permessi:
   - `instagram_basic`
   - `instagram_manage_insights`
6. Copia il token (inizia con `EAAZ...`)
7. Incolla nel wizard

**Guida completa:** Vedi `docs/setup/INSTAGRAM_SETUP_GUIDE.md`

---

### 🐦 Twitter/X

**Prerequisiti:**
- Account Twitter Developer
- App Twitter creata

**Passi:**
1. Vai a: https://developer.twitter.com/
2. Crea app o seleziona esistente
3. Vai a Keys and Tokens
4. Copia **API Key** e **API Secret**
5. Genera **Access Token** e **Access Token Secret**
6. Incolla nel wizard

---

### 💼 LinkedIn

**Prerequisiti:**
- Account LinkedIn Developer
- App LinkedIn creata

**Passi:**
1. Vai a: https://www.linkedin.com/developers/
2. Crea app
3. Vai a Auth
4. Copia **Client ID** e **Client Secret**
5. Incolla nel wizard

**Permessi necessari:**
- `r_liteprofile`
- `r_emailaddress`
- `w_member_social` (per posting)

---

### 📺 YouTube

**Prerequisiti:**
- Account Google Cloud
- Progetto Google Cloud creato

**Passi:**
1. Vai a: https://console.cloud.google.com/
2. Crea progetto
3. Abilita YouTube Data API v3
4. Vai a Credenziali
5. Crea **API Key**
6. Incolla nel wizard

---

### 🎵 TikTok

**Prerequisiti:**
- Account TikTok Developer
- App TikTok creata

**Passi:**
1. Vai a: https://developers.tiktok.com/
2. Crea app
3. Vai a Manage Apps
4. Copia **Client Key** e **Client Secret**
5. Incolla nel wizard

---

### 🔧 GitHub

**Prerequisiti:**
- Account GitHub

**Passi:**
1. Vai a: https://github.com/settings/tokens
2. Clicca "Generate new token (classic)"
3. Seleziona scopes:
   - `repo` (per repository)
   - `workflow` (per GitHub Actions)
4. Genera e copia il token
5. Incolla nel wizard

---

### 💬 Slack

**Prerequisiti:**
- Workspace Slack
- Permessi di amministratore

**Passi:**
1. Vai a: https://api.slack.com/apps
2. Crea app
3. Vai a OAuth & Permissions
4. Copia **Bot User OAuth Token**
5. Vai a Incoming Webhooks
6. Attiva e copia **Webhook URL**
7. Incolla nel wizard

---

## ❓ Troubleshooting

### Problema: "API Key non valida"

**Soluzioni:**
1. Verifica di aver copiato il token completo
2. Controlla che non ci siano spazi extra
3. Verifica che il token non sia scaduto
4. Rigenera un token nuovo

---

### Problema: "Connection failed"

**Soluzioni:**
1. Verifica la connessione internet
2. Controlla che i permessi siano corretti
3. Verifica che l'app sia attivata sul servizio
4. Prova a rigenerare le credenziali

---

### Problema: "Insufficient permissions"

**Soluzioni:**
1. Verifica di aver selezionato tutti i permessi necessari
2. Rigenera il token con i permessi corretti
3. Controlla la documentazione del servizio

---

### Problema: "Token expired"

**Soluzioni:**
1. I token scadono dopo un periodo
2. Rigenera un token nuovo
3. Per token permanenti, segui le istruzioni del servizio

---

## 💡 Tips & Best Practices

### ✅ Do's

- ✅ Usa token dedicati per BrainiacPlus
- ✅ Salva le credenziali in un password manager
- ✅ Testa la connessione prima di completare
- ✅ Leggi la documentazione ufficiale
- ✅ Usa permessi minimi necessari

### ❌ Don'ts

- ❌ Non condividere i token
- ❌ Non usare token dell'account principale
- ❌ Non saltare il test di connessione
- ❌ Non dare permessi non necessari
- ❌ Non salvare credenziali in plain text

---

## 🔒 Sicurezza

### Come vengono salvate le credenziali?

- ✅ Criptate con `flutter_secure_storage`
- ✅ Mai salvate in plain text
- ✅ Accessibili solo all'app
- ✅ Eliminate quando disinstalli

### Token Security

- 🔐 I token sono come password
- 🔐 Non condividerli mai
- 🔐 Revoca token vecchi
- 🔐 Usa permessi minimi

---

## 📞 Supporto

### Se hai problemi:

1. **Consulta questa guida** - Controlla la sezione Troubleshooting
2. **Clicca Help button** - Nel wizard, in alto a destra
3. **Leggi i log** - `flutter logs` per vedere errori
4. **Contatta supporto** - Con screenshot e descrizione

### Link Utili

| Risorsa | Link |
|---------|------|
| Guide servizi | `docs/setup/` |
| Instagram setup | `docs/setup/INSTAGRAM_SETUP_GUIDE.md` |
| Facebook setup | `docs/setup/FACEBOOK_TOKEN_GUIDE.md` |
| FAQ | `docs/FAQ.md` |

---

## ✅ Checklist Configurazione

Prima di iniziare, assicurati di avere:

- [ ] Account sul servizio da configurare
- [ ] Accesso a developer portal del servizio
- [ ] Permessi per creare app/token
- [ ] 5-10 minuti di tempo
- [ ] Connessione internet stabile

Durante la configurazione:

- [ ] Leggi le istruzioni di ogni step
- [ ] Verifica che le credenziali siano corrette
- [ ] Fai il test di connessione
- [ ] Leggi il riepilogo finale

Dopo la configurazione:

- [ ] Salva le credenziali in un password manager
- [ ] Prova a creare un'automazione
- [ ] Verifica che funzioni correttamente
- [ ] Consulta analytics per vedere i risultati

---

## 🎉 Conclusione

Con il **nuovo wizard interattivo**, configurare qualsiasi servizio è:

✅ **Facile** - Step guidati  
✅ **Veloce** - Solo 5 minuti  
✅ **Sicuro** - Credenziali criptate  
✅ **Affidabile** - Test integrato  

**Pronto a iniziare?** Vai su Settings → Services e scegli un servizio! 🚀

---

**Versione:** 2.0  
**Ultimo aggiornamento:** Febbraio 2026  
**Status:** ✅ Completo e Testato
