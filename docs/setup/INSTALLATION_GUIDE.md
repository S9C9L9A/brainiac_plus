# 🛠️ Guida di Installazione Completa

## 📋 Prerequisiti

### Per il Backend Go
- Go 1.21+
- Git
- Variabili d'ambiente configurate

### Per Flutter
- Flutter SDK
- Dart SDK
- Android SDK (per Android) o Xcode (per iOS)

---

## 🐧 Linux (Ubuntu/Debian)

### Installa Go

```bash
# Opzione 1: Usando Snap (consigliato)
sudo snap install go --classic

# Opzione 2: Usando apt
sudo apt update
sudo apt install golang-go

# Verifica
go version
# Output: go version go1.21 linux/amd64
```

### Installa dipendenze del backend

```bash
cd /home/giuseppe-genna/brainiac_plus/go_backend

# Scarica le dipendenze
go mod tidy

# Verifica
go mod graph
```

### Avvia il Backend

```bash
go run main.go
# Output: 🧠 BrainiacPlus Backend starting on :8080
```

---

## 🐭 macOS

### Installa Go

```bash
# Usando Homebrew
brew install go

# Verifica
go version
```

### Installa dipendenze del backend

```bash
cd /home/giuseppe-genna/brainiac_plus/go_backend
go mod tidy
```

### Avvia il Backend

```bash
go run main.go
```

---

## 🪟 Windows

### Installa Go

1. Scarica da https://golang.org/dl/
2. Esegui l'installer
3. Apri PowerShell e verifica:
```powershell
go version
```

### Avvia il Backend

```powershell
cd C:\path\to\brainiac_plus\go_backend
go mod tidy
go run main.go
```

---

## 📦 Configurazione Variabili di Ambiente

### Linux/macOS

```bash
# Copia il template
cp /home/giuseppe-genna/brainiac_plus/go_backend/.env.example \
   /home/giuseppe-genna/brainiac_plus/go_backend/.env

# Modifica con i tuoi dati
nano /home/giuseppe-genna/brainiac_plus/go_backend/.env
```

Riempi il file `.env`:
```env
PORT=8080
FACEBOOK_TOKEN=EAAd3zUKn7To...
FACEBOOK_APP_ID=12345
FACEBOOK_APP_SECRET=xxxxx
JWT_SECRET=cambiami-in-produzione
```

### Windows

```powershell
# Copia il template
Copy-Item `.env.example` `.env`

# Modifica
notepad .env
```

---

## 🚀 Avvio del Backend

### Primo Avvio

```bash
cd go_backend

# Scarica dipendenze
go mod tidy

# Avvia
go run main.go
```

Output atteso:
```
⚠️  WARNING: Variabile d'ambiente FACEBOOK_TOKEN non impostata
⚠️  WARNING: Variabile d'ambiente FACEBOOK_APP_ID non impostata
⚠️  WARNING: Variabile d'ambiente FACEBOOK_APP_SECRET non impostata
🧠 BrainiacPlus Backend starting on :8080
```

### Con Variabili Caricate

```bash
# Verifica che il .env sia configurato
cat .env

# Avvia con variabili
go run main.go
```

Output atteso:
```
🧠 BrainiacPlus Backend starting on :8080
```

### Test Rapido

```bash
# In un altro terminale
curl http://localhost:8080/health

# Risposta attesa
{"status":"ok","version":"2.0.0-alpha"}
```

---

## 🐛 Troubleshooting

### Errore: "go: no Go files in ..."

Assicurati che sei nella cartella corretta:
```bash
pwd
# Output: /home/giuseppe-genna/brainiac_plus/go_backend

ls -la
# Dovresti vedere: main.go, go.mod, config.go, etc.
```

### Errore: "address already in use"

La porta 8080 è già occupata:
```bash
# Trova che processo usa la porta
lsof -i :8080

# Killit (UNIX)
kill -9 <PID>

# Oppure usa un'altra porta
PORT=9000 go run main.go
```

### Errore: "cannot find package"

Scarica le dipendenze:
```bash
go mod tidy
go mod download
```

### Errore nel .env

Verifica che il file esista:
```bash
ls -la .env

# Se non esiste
cp .env.example .env
```

---

## 📱 Setup Flutter

### Installa Flutter

```bash
# Scarica Flutter SDK
# https://flutter.dev/docs/get-started/install

# Aggiungi Flutter al PATH
export PATH="$PATH:/path/to/flutter/bin"

# Verifica
flutter --version
```

### Installa dipendenze del progetto

```bash
cd /home/giuseppe-genna/brainiac_plus

flutter pub get
```

### Aggiungi pacchetti necessari

```bash
flutter pub add http
flutter pub add flutter_facebook_sdk
flutter pub add flutter_secure_storage
```

### Avvia l'App

```bash
# Emulatore Android
flutter run

# iOS Simulator
flutter run -d macos

# Web
flutter run -d chrome
```

---

## 🔌 Connessione Backend ↔️ Frontend

### Configurare l'URL Corretto

Modifica `lib/core/network/api_client.dart`:

```dart
// Per Emulatore Android
static const String baseUrl = 'http://10.0.2.2:8080';

// Per iOS Simulator
static const String baseUrl = 'http://localhost:8080';

// Per Device Fisico
// Scopri l'IP della tua macchina:
// Linux: ifconfig | grep inet
// macOS: ifconfig | grep inet
// Windows: ipconfig | grep IPv4
static const String baseUrl = 'http://192.168.1.XXX:8080';
```

### Testa la Connessione

```dart
// Nel widget di test
ElevatedButton(
  onPressed: () async {
    try {
      final response = await ApiClient.get('/health');
      print('✅ Backend alive: $response');
    } catch (e) {
      print('❌ Error: $e');
    }
  },
  child: Text('Test Backend Connection'),
)
```

---

## 📚 Comandi Utili

### Backend Go

```bash
# Avvia in modalità debug
go run main.go -v

# Build per production
go build -o brainiac-backend .

# Test
go test ./...

# Formatta il codice
go fmt ./...

# Verifica il codice
go vet ./...
```

### Flutter

```bash
# Scarica dipendenze
flutter pub get

# Aggiorna dipendenze
flutter pub upgrade

# Clean
flutter clean

# Test
flutter test

# Build Android APK
flutter build apk

# Build iOS
flutter build ios

# Build Web
flutter build web
```

---

## 🐳 Docker (Opzionale)

### Build & Run con Docker

```bash
cd go_backend

# Crea il Dockerfile
cat > Dockerfile << 'EOF'
FROM golang:1.21-alpine
WORKDIR /app
COPY . .
RUN go mod tidy
RUN go build -o main .
EXPOSE 8080
CMD ["./main"]
EOF

# Build
docker build -t brainiac-backend .

# Run
docker run -p 8080:8080 \
  -e FACEBOOK_TOKEN="EAAd3zUKn7To..." \
  -e FACEBOOK_APP_ID="12345" \
  -e FACEBOOK_APP_SECRET="xxxxx" \
  brainiac-backend
```

---

## ✅ Checklist di Completamento

- [ ] Go installato (`go version` funziona)
- [ ] Backend repository clonato
- [ ] `.env` configurato con token Facebook
- [ ] `go mod tidy` eseguito con successo
- [ ] Backend avvia con `go run main.go`
- [ ] `/health` endpoint risponde
- [ ] Flutter SDK installato
- [ ] Dipendenze Flutter installate (`flutter pub get`)
- [ ] URL backend configurato in `api_client.dart`
- [ ] Test di connessione funziona

---

## 🎉 Prossimi Passi

1. Segui `GO_BACKEND_GUIDE.md` per configurare Facebook
2. Leggi `FLUTTER_BACKEND_INTEGRATION.md` per usare il backend in Flutter
3. Implementa il login nella tua app
4. Testa la pubblicazione di post

---

Tutto pronto! 🚀
