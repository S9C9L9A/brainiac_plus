# 🧠 Backend Go - Guida Completa di Configurazione

## 📋 Indice
1. [Architettura](#architettura)
2. [Come Funziona](#come-funziona)
3. [Facebook Integration](#facebook-integration)
4. [Setup Locale](#setup-locale)
5. [Deploy](#deploy)
6. [Troubleshooting](#troubleshooting)

---

## 🏗️ Architettura

### Struttura dei Folder

```
go_backend/
├── main.go                ← Entry point del server
├── go.mod                 ← Dipendenze
├── .env.example          ← Template configurazione
│
├── models/               ← Strutture dati (type-safe)
│   ├── facebook.go       ← Modelli per Facebook
│   └── ollama.go         ← Modelli per AI
│
├── services/             ← Logica di business
│   ├── facebook.go       ← Integrazione Facebook API
│   ├── ollama.go         ← Integrazione Ollama
│   └── auth.go           ← Autenticazione/JWT
│
└── routes/               ← Endpoint HTTP
    ├── facebook.go       ← Route Facebook
    └── ollama.go         ← Route AI
```

### I Tre Livelli

```
┌─────────────────────────────────────┐
│ HTTP Request (da Flutter App)      │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│ ROUTES Layer (routes/facebook.go)   │  ← Riceve la richiesta
│ - Valida i parametri               │
│ - Estrae i dati dalla richiesta    │
│ - Chiama il service                │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│ SERVICES Layer (services/facebook.go) │ ← Logica core
│ - Comunica con Facebook API          │
│ - Usa variabili di ambiente          │
│ - Gestisce gli errori                │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│ MODELS Layer (models/facebook.go)    │ ← Strutture dati
│ - Definisce i tipi Go                │
│ - Mapping JSON                       │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│ Response JSON (al client)            │
└─────────────────────────────────────┘
```

---

## 🔄 Come Funziona

### Esempio: Autenticazione Facebook

#### 1️⃣ Request dal Flutter (APP)
```dart
// lib/features/settings/authentication_service.dart
final response = await http.post(
  Uri.parse('http://localhost:8080/api/facebook/auth'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'access_token': 'EAAd3zUKn7To...', // Dal Facebook SDK
    'user_id': '123456'
  }),
);
```

#### 2️⃣ Route riceve (routes/facebook.go)
```
POST /api/facebook/auth
├─ Legge il JSON
├─ Chiama FacebookService
└─ Ritorna risposta
```

#### 3️⃣ Service processa (services/facebook.go)
```go
user, err := svc.ValidateUserToken(req.AccessToken)
// Comunica con Facebook API
// Ritorna dati utente
```

#### 4️⃣ Response al Flutter
```json
{
  "valid": true,
  "user": {
    "id": "123456",
    "name": "Giuseppe Genna",
    "email": "giuseppe@example.com"
  },
  "message": "Autenticazione riuscita"
}
```

---

## 🔐 Facebook Integration

### Endpoint Disponibili

#### 1. Autenticazione
```http
POST /api/facebook/auth
Content-Type: application/json

{
  "access_token": "EAAd3zUKn7To...",
  "user_id": "123456"
}

Response:
{
  "valid": true,
  "user": {
    "id": "123456",
    "name": "Giuseppe",
    "email": "giuseppe@example.com"
  },
  "token": "eyJhbGc..." (JWT interno)
}
```

#### 2. Recuperare Pagine
```http
GET /api/facebook/pages
Headers:
  X-Facebook-Token: EAAd3zUKn7To...

Response:
{
  "pages": [
    {
      "access_token": "PAGE_TOKEN",
      "category": "App Page",
      "id": "PAGE_ID",
      "name": "BraniacPlus"
    }
  ]
}
```

#### 3. Pubblicare Post
```http
POST /api/facebook/post
Content-Type: application/json

{
  "page_id": "PAGE_ID",
  "page_token": "PAGE_TOKEN",
  "message": "Hello from BraniacPlus!"
}

Response:
{
  "post_id": "123456_789",
  "message": "Post pubblicato con successo"
}
```

---

## 🚀 Setup Locale

### Step 1: Clona il Repo
```bash
cd /home/giuseppe-genna/brainiac_plus/go_backend
```

### Step 2: Configura le Variabili di Ambiente
```bash
# Copia il template
cp .env.example .env

# Modifica con i tuoi dati
nano .env
# Oppure in VSCode
code .env
```

Riempi con i tuoi valori:
```env
FACEBOOK_TOKEN=EAAd3zUKn7To...     # Dal Facebook Developers
FACEBOOK_APP_ID=12345              # ID dell'app
FACEBOOK_APP_SECRET=xxxxx          # Secret dell'app
```

### Step 3: Installa le Dipendenze
```bash
go mod tidy
```

### Step 4: Avvia il Server
```bash
go run main.go
# Oppure con auto-reload (installa air prima)
air
```

Dovresti vedere:
```
🧠 BrainiacPlus Backend starting on :8080
```

### Step 5: Testa gli Endpoint
```bash
# Health check
curl http://localhost:8080/health

# Autenticazione (con token di esempio)
curl -X POST http://localhost:8080/api/facebook/auth \
  -H "Content-Type: application/json" \
  -d '{
    "access_token": "YOUR_TOKEN",
    "user_id": "123456"
  }'
```

---

## 🌐 Come Ottenere il Token Facebook

### 1. Vai su Facebook Developers
https://developers.facebook.com/

### 2. Seleziona l'App BraniacPlus
- Vai al dashboard
- Seleziona "BraniacPlus" dal menu

### 3. Strumenti > Esplora API
- Clicca su "Strumenti" (in alto)
- Seleziona "Esplora API"

### 4. Genera il Token
- Accanto al profilo, clicca "Generate Access Token"
- Copia il token completo
- **NON CONDIVIDERE MAI PUBBLICAMENTE!**

### 5. Inserisci nel .env
```env
FACEBOOK_TOKEN=EAAd3zUKn7To...
```

---

## 📦 Deploy

### Deploy su Railway (Consigliato)
```bash
# 1. Installa CLI di Railway
curl -fsSL https://railway.app/install.sh | sh

# 2. Login
railway login

# 3. Collega al progetto
railway link

# 4. Aggiungi variabili
railway variables set FACEBOOK_TOKEN="EAAd3zUKn7To..."
railway variables set FACEBOOK_APP_ID="12345"
railway variables set FACEBOOK_APP_SECRET="xxxxx"

# 5. Deploy
railway up
```

### Deploy su Heroku
```bash
# 1. Login
heroku login

# 2. Crea app
heroku create brainiac-backend

# 3. Aggiungi variabili
heroku config:set FACEBOOK_TOKEN="EAAd3zUKn7To..."
heroku config:set PORT=8080

# 4. Deploy
git push heroku main
```

### Deploy su Docker
```dockerfile
# Dockerfile
FROM golang:1.21-alpine

WORKDIR /app
COPY . .

RUN go mod tidy
RUN go build -o main .

EXPOSE 8080

CMD ["./main"]
```

```bash
docker build -t brainiac-backend .
docker run -p 8080:8080 \
  -e FACEBOOK_TOKEN="EAAd3zUKn7To..." \
  brainiac-backend
```

---

## 🛠️ Aggiungere Nuovi Servizi

### Esempio: Integrare un Nuovo Servizio (e.g., Instagram)

#### Step 1: Crea il Modello
```go
// models/instagram.go
type InstagramUser struct {
    ID       string
    Username string
    Bio      string
}
```

#### Step 2: Crea il Service
```go
// services/instagram.go
type InstagramService struct {
    AccessToken string
}

func (is *InstagramService) GetUserInfo(userID string) (*InstagramUser, error) {
    // Chiama Instagram API
}
```

#### Step 3: Crea i Route
```go
// routes/instagram.go
func SetupInstagramRoutes(r *gin.Engine) {
    instagramSvc := services.NewInstagramService()
    
    ig := r.Group("/api/instagram")
    {
        ig.GET("/user", func(c *gin.Context) {
            handleGetUser(c, instagramSvc)
        })
    }
}
```

#### Step 4: Aggiungi a main.go
```go
// in main()
routes.SetupInstagramRoutes(r)
```

---

## ❌ Troubleshooting

### Errore: "Token non valido"
```
Soluzione:
1. Verifica che il token sia corretto in .env
2. Verifica che sia ancora valido (non scaduto)
3. Rigenerato da Facebook Developers
```

### Errore: "CORS origin not allowed"
```
Soluzione:
- Il CORS è già configurato in main.go
- Se problemi, aggiungi il dominio nel backend:
  c.Writer.Header().Set("Access-Control-Allow-Origin", "YOUR_DOMAIN")
```

### Errore: "Connection refused"
```
Soluzione:
1. Verifica che il backend sia in esecuzione (go run main.go)
2. Controlla la porta (default 8080)
3. Verifica firewall/rete
```

### Errore: "Unauthorized" nel deployment
```
Soluzione:
1. Verifica variabili di ambiente nel cloud
2. Usa: railway variables list (per Railway)
3. Usa: heroku config (per Heroku)
4. Assicurati che il token sia stato copiato completamente
```

---

## 📚 Risorse Utili

- [Gin Framework Docs](https://gin-gonic.com/)
- [Facebook Graph API](https://developers.facebook.com/docs/graph-api)
- [Go Environment Variables](https://pkg.go.dev/os)
- [RESTful API Best Practices](https://restfulapi.net/)

---

## ✅ Checklist di Sicurezza

- [ ] Token di Facebook NON nel codice sorgente
- [ ] .env aggiunto a .gitignore
- [ ] CORS configurato solo per domini autorizzati
- [ ] JWT secret generato e sicuro
- [ ] Rate limiting implementato
- [ ] Input validation su tutte le richieste
- [ ] Logging di errori senza esporre dati sensibili
- [ ] HTTPS in produzione
- [ ] Token con scadenza limitata

---

Fatto! Ora hai tutto configurato! 🚀
