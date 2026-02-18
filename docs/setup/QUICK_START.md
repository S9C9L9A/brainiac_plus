# ⚡ Quick Start - 5 Minuti

Vuoi far funzionare tutto in 5 minuti? Segui questi step!

---

## 🚀 Step 1: Installa Go (1 minuto)

### Ubuntu/Debian
```bash
sudo apt update && sudo apt install golang-go
go version
```

### macOS
```bash
brew install go
go version
```

### Windows
Scarica da https://golang.org/dl/ e installa

---

## 🔐 Step 2: Configura il Token (1 minuto)

```bash
cd ~/brainiac_plus/go_backend

# Copia il template
cp .env.example .env

# Modifica il file
nano .env  # o VSCode
```

**Dentro al file `.env`:**
```env
PORT=8080
FACEBOOK_TOKEN=EAAd3zUKn7To...  ← Incolla il tuo token qui
FACEBOOK_APP_ID=12345
FACEBOOK_APP_SECRET=xxxxx
JWT_SECRET=cambiami
```

---

## 📦 Step 3: Scarica le Dipendenze (1 minuto)

```bash
# Assicurati di essere in go_backend/
pwd
# Output: /home/giuseppe-genna/brainiac_plus/go_backend

# Scarica dipendenze
go mod tidy

# Aspetta il completamento...
```

---

## ▶️ Step 4: Avvia il Backend (1 minuto)

```bash
go run main.go
```

**Aspettati questo output:**
```
🧠 BrainiacPlus Backend starting on :8080
```

---

## ✅ Step 5: Testa! (1 minuto)

Apri un **nuovo terminale** e prova:

```bash
# Test di salute
curl http://localhost:8080/health

# Aspettati
{"status":"ok","version":"2.0.0-alpha"}
```

🎉 **Perfetto! Il backend funziona!**

---

## 📱 Prossimo: Usa da Flutter

```dart
import 'package:core/network/api_client.dart';

// Autentica con Facebook
final response = await FacebookAuthService.authenticateWithFacebook(
  userToken,
  userID,
);

// Boom! ✅
print(response['user']['name']);
```

---

## ❓ Problemi Comuni?

| Problema | Soluzione |
|----------|-----------|
| `go: command not found` | Installa Go da golang.org |
| `address already in use` | Cambia porta: `PORT=9000 go run main.go` |
| `permission denied .env` | Copia con: `cp .env.example .env` |
| Token error | Rigenera il token da Facebook Developers |

---

## 📚 Leggi Dopo

1. `GO_BACKEND_GUIDE.md` - Guida completa backend
2. `FLUTTER_BACKEND_INTEGRATION.md` - Come usare da Flutter
3. `SYSTEM_ARCHITECTURE.md` - Visione d'insieme

---

**Done!** 🎉 Ora il tuo backend è live!

Domande? Rivedi i file `.md` nella root del progetto.
