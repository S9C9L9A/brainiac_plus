# 🧠 BraniacPlus Backend Go - Setup Completo

## 🎯 Cosa abbiamo fatto

Ho creato una **architettura completa e sicura** per integrare Facebook nel tuo app BraniacPlus usando un backend Go professionale.

### ✅ Creato

#### Backend Go (`go_backend/`)
- **models/facebook.go** - Strutture dati type-safe
- **services/facebook.go** - Logica di integrazione Facebook
- **services/jwt.go** - Gestione dei token JWT
- **routes/facebook.go** - Endpoint API
- **routes/middleware.go** - Autenticazione e middleware
- **config.go** - Caricamento variabili di ambiente
- **main.go** - Server aggiornato
- **.env.example** - Template di configurazione
- **go.mod** - Dipendenze aggiornate

#### Frontend Flutter (`lib/`)
- **lib/core/network/api_client.dart** - Client HTTP + Servizi

#### Documentazione (ROOT)
- **QUICK_START.md** - 5 minuti per far funzionare tutto ⚡
- **INSTALLATION_GUIDE.md** - Come installare Go e dipendenze
- **GO_BACKEND_GUIDE.md** - Guida completa del backend 📚
- **FLUTTER_BACKEND_INTEGRATION.md** - Come usare da Flutter 📱
- **SYSTEM_ARCHITECTURE.md** - Vista d'insieme dell'architettura 🏗️
- **BACKEND_SETUP_SUMMARY.md** - Riepilogo e troubleshooting

---

## 🚀 Come Iniziare

### 1️⃣ Leggi il Quick Start (5 minuti)
```bash
cat QUICK_START.md
```
→ Ti farà avviare il backend in 5 minuti

### 2️⃣ Setup Completo
Se non l'hai fatto:
```bash
# Installa Go
sudo apt install golang-go

# Vai nella cartella backend
cd go_backend

# Configura il token
cp .env.example .env
nano .env  # Incolla il tuo token

# Scarica dipendenze
go mod tidy

# Avvia
go run main.go
```

### 3️⃣ Testa
```bash
# In un altro terminale
curl http://localhost:8080/health

# Aspetta: {"status":"ok","version":"2.0.0-alpha"}
```

---

## 📚 Documentazione Completa

### Per il Backend
👉 **GO_BACKEND_GUIDE.md**
- Architettura dettagliata
- Tutti gli endpoint
- Come aggiungere nuovi servizi
- Deploy (Railway, Heroku, Docker)

### Per Flutter
👉 **FLUTTER_BACKEND_INTEGRATION.md**
- Integrazione Facebook SDK
- Login flow completo
- Pubblicazione post
- Gestione token sicura

### Per il Setup
👉 **INSTALLATION_GUIDE.md**
- Linux, macOS, Windows
- Troubleshooting
- Comandi utili

### Vista d'Insieme
👉 **SYSTEM_ARCHITECTURE.md**
- Diagrammi dell'architettura
- Flussi di dati
- Security patterns
- Deploy architecture

---

## 🔐 Sicurezza: IMPORTANTE!

### ⚠️ Il token che hai condiviso è ESPOSTO!

1. **Revoca immediatamente**: https://developers.facebook.com
2. **Genera un nuovo token**
3. **Usa il nuovo token nel `.env` locale**
4. **MAI condividere token pubblicamente**

### Come Proteggere i Token

```bash
# 1. Il file .env NON deve essere committato
echo ".env" >> .gitignore

# 2. Verifica che sia nel .gitignore
cat .gitignore | grep .env
# Output: .env ✅

# 3. Verifica di non averlo già committato
git log --all --full-history -- go_backend/.env
# Se vuoto, ok. Se ha commit, fai:
git rm --cached go_backend/.env
git commit -m "Remove .env from git history"
```

---

## 🎯 Endpoint Disponibili

```
✅ GET /health
   → Health check del server

✅ POST /api/facebook/auth
   → Autentica l'utente con Facebook
   → Ritorna JWT per sessioni interne

✅ GET /api/facebook/pages
   → Recupera le pagine Facebook dell'utente

✅ POST /api/facebook/post
   → Pubblica un post su una pagina
```

---

## 📊 Architettura (Visione Rapida)

```
Flutter App
    ↓
lib/core/network/api_client.dart
    ↓ (HTTPS)
Go Backend (routes/)
    ↓
Services (logica)
    ↓
Models (dati)
    ↓
Facebook API
```

**Tutto è type-safe, sicuro e scalabile** ✅

---

## 🛠️ Comandi Utili

### Backend Go
```bash
cd go_backend

# Avvia
go run main.go

# Build per production
go build -o brainiac-backend .

# Test
go test ./...

# Formato codice
go fmt ./...

# Controlla errori
go vet ./...
```

### Flutter
```bash
cd ~/brainiac_plus

# Aggiungi dipendenze
flutter pub add http flutter_facebook_sdk

# Avvia app
flutter run

# Test
flutter test
```

---

## ❓ FAQ

### D: Come faccio a usare il backend da Flutter?
**R:** Importa `lib/core/network/api_client.dart` e usa `FacebookAuthService`

### D: Posso aggiungere altri servizi (Instagram, TikTok)?
**R:** Sì! Segui il pattern: models/ → services/ → routes/

### D: Come faccio il deploy?
**R:** Leggi "GO_BACKEND_GUIDE.md" sezione "Deploy"

### D: Il token scade?
**R:** Il JWT scade in 24 ore. L'utente dovrà fare re-login.

### D: Posso usare un database?
**R:** Sì! Aggiungi PostgreSQL e una libreria come `sqlc` o `gorm`

### D: Devo usare Docker?
**R:** No, ma consigliato per production

---

## 🚨 Troubleshooting Rapido

| Errore | Soluzione |
|--------|-----------|
| `go: command not found` | Installa Go: `sudo apt install golang-go` |
| `address already in use` | Usa altra porta: `PORT=9000 go run main.go` |
| `cannot find package` | Esegui: `go mod tidy` |
| `no such file .env` | Copia: `cp .env.example .env` |
| CORS error | Già configurato in main.go ✅ |
| Token non valido | Rigenerato da Facebook Developers |
| Flutter non raggiunge backend | Controlla l'IP in `api_client.dart` |

---

## 📖 Letture Consigliate (Nell'ordine)

1. **QUICK_START.md** (5 min) ⚡
2. **SYSTEM_ARCHITECTURE.md** (10 min) 🏗️
3. **GO_BACKEND_GUIDE.md** (20 min) 📚
4. **FLUTTER_BACKEND_INTEGRATION.md** (20 min) 📱
5. **INSTALLATION_GUIDE.md** (Riferimento) 🛠️

---

## ✨ Prossimi Passi

- [ ] Leggi QUICK_START.md
- [ ] Installa Go
- [ ] Configura il `.env`
- [ ] Avvia il backend
- [ ] Testa con `curl /health`
- [ ] Integra in Flutter
- [ ] Testa il login Facebook
- [ ] Pubblica il primo post 🎉

---

## 🎓 Cosa Hai Imparato

✅ Come funziona un backend Go moderno  
✅ Architettura a 3 layer (Routes, Services, Models)  
✅ Come gestire i token di Facebook in modo sicuro  
✅ Come generare JWT per sessioni sicure  
✅ Come comunicare tra Flutter e Go  
✅ Best practices di sicurezza  
✅ Come scalare e deployare  

---

## 💡 Concetti Chiave

### Non confondere:
- **Access Token (Facebook)** → Token che Facebook ti da per accedere alle loro API
- **JWT (Backend)** → Token che il TUO backend genera per il frontend

### Il Flow:
```
1. Flutter → Facebook (ottieni accessToken)
2. Flutter → Backend (invia accessToken)
3. Backend → Facebook (valida accessToken con il suo token)
4. Backend → Flutter (ritorna JWT)
5. Flutter salva JWT in SecureStorage
6. Flutter usa JWT per richeste autenticate
```

---

## 🔗 Link Utili

- [Go Docs](https://golang.org/doc/)
- [Gin Framework](https://gin-gonic.com/)
- [Facebook Graph API](https://developers.facebook.com/docs/graph-api)
- [Flutter HTTP](https://pub.dev/packages/http)
- [JWT Explained](https://jwt.io/)

---

## ✅ Checklist Setup Completo

- [ ] Go 1.21+ installato
- [ ] Backend clonato
- [ ] `.env` configurato con token
- [ ] `go mod tidy` eseguito
- [ ] Backend avvia con `go run main.go`
- [ ] `/health` endpoint risponde
- [ ] Flutter SDK installato
- [ ] `api_client.dart` copiato
- [ ] URL backend configurato correttamente
- [ ] Test di connessione passa

---

## 🎉 Congratulazioni!

Hai ora un **backend professionistico** pronto per l'integrazione di servizi come Facebook!

La struttura che ho creato è:
- ✅ **Scalabile** - Aggiungi nuovi servizi facilmente
- ✅ **Sicura** - Token gestiti correttamente
- ✅ **Manutenibile** - Codice pulito e organizzato
- ✅ **Type-safe** - Go fa validazione in fase di compilazione
- ✅ **Production-ready** - Deployable subito

---

**Pronto a iniziare? Apri `QUICK_START.md`!** ⚡

Buona codifica! 🚀
